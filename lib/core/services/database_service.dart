import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../models/player_model.dart';

/// Gestisce TUTTE le operazioni Firestore.
///
/// Struttura del database:
/// ┌─ users/{uid}/
/// │   ├─ profile      → username, email, createdAt, isVip …
/// │   ├─ player       → coins, gems, level, xp, stats …
/// │   └─ inventory/{itemId} → ogni oggetto dell'inventario
/// │
/// └─ usernames/{username} → { uid }   (per unicità username)

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Riferimenti ──────────────────────────────────────────────────────────

  DocumentReference _userDoc(String uid)      => _db.collection('users').doc(uid);
  DocumentReference _playerDoc(String uid)    => _userDoc(uid).collection('data').doc('player');
  DocumentReference _profileDoc(String uid)   => _userDoc(uid).collection('data').doc('profile');
  CollectionReference _inventoryCol(String uid) => _userDoc(uid).collection('inventory');
  DocumentReference _usernameDoc(String username) =>
      _db.collection('usernames').doc(username.toLowerCase());

  // ─── Username univoco ─────────────────────────────────────────────────────

  Future<bool> isUsernameTaken(String username) async {
    final doc = await _usernameDoc(username).get();
    return doc.exists;
  }

  Future<String?> lookupUidByUsername(String username) async {
    final doc = await _usernameDoc(username).get();
    if (!doc.exists) return null;
    return (doc.data() as Map<String, dynamic>?)?['uid'] as String?;
  }

  Future<void> reserveUsername(String username, String uid) async {
    await _usernameDoc(username).set({'uid': uid});
  }

  Future<void> releaseUsername(String username) async {
    await _usernameDoc(username).delete();
  }

  // ─── Profilo ──────────────────────────────────────────────────────────────

  Future<void> saveProfile({
    required String uid,
    required String username,
    required String email,
    required DateTime createdAt,
  }) async {
    await _profileDoc(uid).set({
      'uid':       uid,
      'username':  username,
      'email':     email,
      'createdAt': createdAt.toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> loadProfile(String uid) async {
    final snap = await _profileDoc(uid).get();
    return snap.exists ? snap.data() as Map<String, dynamic>? : null;
  }

  // ─── Player ───────────────────────────────────────────────────────────────

  Future<void> savePlayer(String uid, PlayerModel player) async {
    await _playerDoc(uid).set(_playerToMap(player), SetOptions(merge: true));
  }

  Future<PlayerModel?> loadPlayer(String uid) async {
    final snap = await _playerDoc(uid).get();
    if (!snap.exists) return null;
    return _playerFromMap(snap.data() as Map<String, dynamic>);
  }

  // ─── Inventario ───────────────────────────────────────────────────────────

  Future<void> saveItem(String uid, ItemModel item) async {
    await _inventoryCol(uid).doc(item.id).set(_itemToMap(item));
  }

  Future<void> deleteItem(String uid, String itemId) async {
    await _inventoryCol(uid).doc(itemId).delete();
  }

  Future<List<ItemModel>> loadInventory(String uid) async {
    final snap = await _inventoryCol(uid).get();
    return snap.docs
        .map((d) => _itemFromMap(d.data() as Map<String, dynamic>))
        .toList();
  }

  // ─── Leaderboard ─────────────────────────────────────────────────────────

  /// Salva/aggiorna l'entry del giocatore nella classifica globale.
  Future<void> updateLeaderboard(PlayerModel player) async {
    await _db.collection('leaderboard').doc(player.uid).set({
      'uid':                   player.uid,
      'username':              player.username,
      'totalEarned':           player.totalEarned,
      'level':                 player.level,
      'totalContainersOpened': player.totalContainersOpened,
      'totalRaresFound':       player.totalRaresFound,
      'isVip':                 player.isVip,
      'updatedAt':             DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Restituisce i top N giocatori ordinati per un campo.
  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    String orderBy = 'totalEarned',
    int limit = 100,
  }) async {
    final snap = await _db
        .collection('leaderboard')
        .orderBy(orderBy, descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ─── Serializzazione PlayerModel ──────────────────────────────────────────

  Map<String, dynamic> _playerToMap(PlayerModel p) => {
    'uid':                    p.uid,
    'username':               p.username,
    'coins':                  p.coins,
    'gems':                   p.gems,
    'level':                  p.level,
    'xp':                     p.xp,
    'isVip':                  p.isVip,
    'totalContainersOpened':  p.totalContainersOpened,
    'totalItemsSold':         p.totalItemsSold,
    'totalRaresFound':        p.totalRaresFound,
    'totalEarned':            p.totalEarned,
    'pityCounter':            p.pityCounter,
    'luckBoost':              p.luckBoost,
    'valueBoost':             p.valueBoost,
    'mutationBoost':          p.mutationBoost,
    'inventorySlots':         p.inventorySlots,
    'dailyLoginStreak':       p.dailyLoginStreak,
    'lastLoginAt':            p.lastLoginAt.toIso8601String(),
    'lastFreeContainerAt':    p.lastFreeContainerAt.toIso8601String(),
    'luckUpgradeLevel':       p.luckUpgradeLevel,
    'valueUpgradeLevel':      p.valueUpgradeLevel,
    'slotsUpgradeLevel':      p.slotsUpgradeLevel,
    'mutationUpgradeLevel':   p.mutationUpgradeLevel,
    'autoOpenUpgradeLevel':   p.autoOpenUpgradeLevel,
    'autoSellUpgradeLevel':   p.autoSellUpgradeLevel,
    'prestigeLevel':          p.prestigeLevel,
    'prestigeLuckBonus':      p.prestigeLuckBonus,
    'dust':                   p.dust,
    'updatedAt':              DateTime.now().toIso8601String(),
  };

  PlayerModel _playerFromMap(Map<String, dynamic> m) {
    DateTime _dt(String? s) =>
        s != null ? DateTime.tryParse(s) ?? DateTime(2000) : DateTime(2000);

    return PlayerModel(
      uid:                   m['uid'] as String? ?? '',
      username:              m['username'] as String? ?? '',
      coins:                 (m['coins'] as num?)?.toDouble() ?? 0,
      gems:                  (m['gems'] as num?)?.toInt() ?? 0,
      level:                 (m['level'] as num?)?.toInt() ?? 1,
      xp:                    (m['xp'] as num?)?.toDouble() ?? 0,
      isVip:                 m['isVip'] as bool? ?? false,
      totalContainersOpened: (m['totalContainersOpened'] as num?)?.toInt() ?? 0,
      totalItemsSold:        (m['totalItemsSold'] as num?)?.toInt() ?? 0,
      totalRaresFound:       (m['totalRaresFound'] as num?)?.toInt() ?? 0,
      totalEarned:           (m['totalEarned'] as num?)?.toDouble() ?? 0,
      pityCounter:           (m['pityCounter'] as num?)?.toInt() ?? 0,
      luckBoost:             (m['luckBoost'] as num?)?.toDouble() ?? 1.0,
      valueBoost:            (m['valueBoost'] as num?)?.toDouble() ?? 1.0,
      mutationBoost:         (m['mutationBoost'] as num?)?.toDouble() ?? 1.0,
      inventorySlots:        (m['inventorySlots'] as num?)?.toInt() ?? 50,
      dailyLoginStreak:      (m['dailyLoginStreak'] as num?)?.toInt() ?? 0,
      lastLoginAt:           _dt(m['lastLoginAt'] as String?),
      lastFreeContainerAt:   _dt(m['lastFreeContainerAt'] as String?),
      luckUpgradeLevel:      (m['luckUpgradeLevel'] as num?)?.toInt() ?? 0,
      valueUpgradeLevel:     (m['valueUpgradeLevel'] as num?)?.toInt() ?? 0,
      slotsUpgradeLevel:     (m['slotsUpgradeLevel'] as num?)?.toInt() ?? 0,
      mutationUpgradeLevel:  (m['mutationUpgradeLevel'] as num?)?.toInt() ?? 0,
      autoOpenUpgradeLevel:  (m['autoOpenUpgradeLevel'] as num?)?.toInt() ?? 0,
      autoSellUpgradeLevel:  (m['autoSellUpgradeLevel'] as num?)?.toInt() ?? 0,
      prestigeLevel:         (m['prestigeLevel'] as num?)?.toInt() ?? 0,
      prestigeLuckBonus:     (m['prestigeLuckBonus'] as num?)?.toDouble() ?? 0,
      dust:                  (m['dust'] as num?)?.toDouble() ?? 0,
    );
  }

  // ─── Serializzazione ItemModel ────────────────────────────────────────────

  Map<String, dynamic> _itemToMap(ItemModel i) => {
    'id':          i.id,
    'name':        i.name,
    'category':    i.category,
    'rarityKey':   i.rarityKey,
    'mutationKey': i.mutationKey,
    'baseValue':   i.baseValue,
    'iconAsset':   i.iconAsset,
    'obtainedAt':  i.obtainedAt.toIso8601String(),
    'containerId': i.containerId,
    'isLocked':    i.isLocked,
  };

  ItemModel _itemFromMap(Map<String, dynamic> m) => ItemModel(
    id:          m['id'] as String,
    name:        m['name'] as String,
    category:    m['category'] as String,
    rarityKey:   m['rarityKey'] as String,
    mutationKey: m['mutationKey'] as String,
    baseValue:   (m['baseValue'] as num).toDouble(),
    iconAsset:   m['iconAsset'] as String? ?? '',
    obtainedAt:  DateTime.parse(m['obtainedAt'] as String),
    containerId: m['containerId'] as String,
    isLocked:    m['isLocked'] as bool? ?? false,
  );
}
