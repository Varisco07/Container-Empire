import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_model.dart';
import 'database_service.dart';
import 'player_service.dart';

enum SortMode { newest, oldest, valueDesc, valueAsc, rarityDesc }
enum FilterRarity { all, common, uncommon, rare, epic, legendary, mythic, divine, secret }

class InventoryService {
  final PlayerService _playerService;
  final DatabaseService _db = DatabaseService();
  Box<ItemModel>? _box;
  String? _uid;

  InventoryService(this._playerService);

  String _boxName(String? uid) => uid != null ? 'inventory_$uid' : 'inventory_local';

  Future<void> init({String? uid}) async {
    _uid = uid;
    final name = _boxName(uid);
    if (!Hive.isBoxOpen(name)) {
      _box = await Hive.openBox<ItemModel>(name);
    } else {
      _box = Hive.box<ItemModel>(name);
    }

    // Sincronizza inventario da Firestore al login
    if (uid != null) {
      try {
        final remoteItems = await _db.loadInventory(uid);
        if (remoteItems.isNotEmpty) {
          await _box!.clear();
          for (final item in remoteItems) {
            await _box!.put(item.id, item);
          }
        }
      } catch (_) {
        // Offline — usa cache Hive
      }
    }
  }

  List<ItemModel> get allItems => _box?.values.toList() ?? [];

  int get count => _box?.length ?? 0;

  bool get isFull {
    final player = _playerService.localPlayer;
    if (player == null) return false;
    return count >= player.inventorySlots;
  }

  Future<bool> addItem(ItemModel item) async {
    if (isFull) return false;
    await _box?.put(item.id, item);
    if (_uid != null) _db.saveItem(_uid!, item).catchError((_) {});
    return true;
  }

  Future<void> removeItem(String id) async {
    await _box?.delete(id);
    if (_uid != null) _db.deleteItem(_uid!, id).catchError((_) {});
  }

  Future<double> sellItem(String id) async {
    final item = _box?.get(id);
    if (item == null || item.isLocked) return 0;
    final value = item.finalValue * (_playerService.localPlayer?.valueBoost ?? 1.0);
    await _box?.delete(id);
    if (_uid != null) _db.deleteItem(_uid!, id).catchError((_) {});
    await _playerService.addCoins(value);
    await _playerService.incrementItemsSold();
    return value;
  }

  Future<double> sellAll({bool skipLocked = true}) async {
    final ids = (_box?.values ?? [])
        .where((i) => !skipLocked || !i.isLocked)
        .map((i) => i.id)
        .toList();
    double total = 0;
    for (final id in ids) {
      total += await sellItem(id);
    }
    return total;
  }

  Future<double> sellByIds(List<String> ids) async {
    double total = 0;
    for (final id in ids) {
      total += await sellItem(id);
    }
    return total;
  }

  Future<void> toggleLock(String id) async {
    final item = _box?.get(id);
    if (item == null) return;
    item.isLocked = !item.isLocked;
    await item.save();
  }

  List<ItemModel> filter({
    String query = '',
    FilterRarity rarity = FilterRarity.all,
    SortMode sort = SortMode.newest,
  }) {
    var items = allItems;

    if (query.isNotEmpty) {
      items = items.where((i) => i.name.toLowerCase().contains(query.toLowerCase())).toList();
    }

    if (rarity != FilterRarity.all) {
      items = items.where((i) => i.rarityKey == rarity.name).toList();
    }

    switch (sort) {
      case SortMode.newest:
        items.sort((a, b) => b.obtainedAt.compareTo(a.obtainedAt));
      case SortMode.oldest:
        items.sort((a, b) => a.obtainedAt.compareTo(b.obtainedAt));
      case SortMode.valueDesc:
        items.sort((a, b) => b.finalValue.compareTo(a.finalValue));
      case SortMode.valueAsc:
        items.sort((a, b) => a.finalValue.compareTo(b.finalValue));
      case SortMode.rarityDesc:
        items.sort((a, b) => b.rarity.sortOrder.compareTo(a.rarity.sortOrder));
    }

    return items;
  }

  // Stats
  double get totalInventoryValue =>
      allItems.fold(0.0, (s, i) => s + i.finalValue);

  Map<String, int> get rarityBreakdown {
    final result = <String, int>{};
    for (final item in allItems) {
      result[item.rarityKey] = (result[item.rarityKey] ?? 0) + 1;
    }
    return result;
  }

  // Collection: unique items discovered
  Map<String, bool> get discoveredItems {
    final result = <String, bool>{};
    for (final item in allItems) {
      result[item.name] = true;
    }
    return result;
  }
}
