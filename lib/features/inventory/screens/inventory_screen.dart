import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/item_model.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';
import '../widgets/inventory_item_tile.dart';

final _sortProvider = StateProvider<SortMode>((ref) => SortMode.newest);
final _searchProvider = StateProvider<String>((ref) => '');

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  bool _selectMode = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ItemModel> _getItems() {
    final sort = ref.read(_sortProvider);
    final search = ref.read(_searchProvider);
    return sl<InventoryService>().filter(query: search, sort: sort);
  }

  Future<void> _sellSelected() async {
    final inv = sl<InventoryService>();
    double total = 0;
    for (final id in _selected) {
      total += await inv.sellItem(id);
    }
    ref.read(playerNotifierProvider.notifier).refresh();
    setState(() { _selected.clear(); _selectMode = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Venduto per 🪙 ${_fmt(total)}!'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _sellAll() async {
    final ok = await _confirm('Vendi tutti gli oggetti non bloccati?');
    if (!ok) return;
    final total = await sl<InventoryService>().sellAll();
    ref.read(playerNotifierProvider.notifier).refresh();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Venduto tutto: 🪙 ${_fmt(total)}'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<bool> _confirm(String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Conferma', style: TextStyle(color: AppColors.textPrimary)),
            content: Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Conferma')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final inv = sl<InventoryService>();
    final sort = ref.watch(_sortProvider);
    final search = ref.watch(_searchProvider);
    final items = inv.filter(query: search, sort: sort);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('INVENTARIO  ${inv.count}/${inv.isFull ? "PIENO" : "∞"}'),
        actions: [
          // Bottone Fusione
          IconButton(
            icon: const Text('⚗️', style: TextStyle(fontSize: 18)),
            tooltip: 'Fusione',
            onPressed: () => context.push('/crafting'),
          ),
          IconButton(
            icon: Icon(_selectMode ? Icons.close : Icons.checklist_rounded),
            onPressed: () => setState(() { _selectMode = !_selectMode; _selected.clear(); }),
          ),
          PopupMenuButton<String>(
            color: AppColors.surface,
            onSelected: (v) { if (v == 'sell_all') _sellAll(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'sell_all',
                child: Text('Vendi tutto', style: TextStyle(color: AppColors.textPrimary))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + sort
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cerca oggetti...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 8),
                // Sort chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: SortMode.values.map((m) {
                      final selected = sort == m;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => ref.read(_sortProvider.notifier).state = m,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.neonCyan.withOpacity(0.15) : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? AppColors.neonCyan : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                if (selected) const Text('✓ ', style: TextStyle(color: AppColors.neonCyan, fontSize: 11)),
                                Text(
                                  _sortLabel(m),
                                  style: TextStyle(
                                    color: selected ? AppColors.neonCyan : AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Grid
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.7, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (_, v, child) => Transform.scale(scale: v, child: child),
                          child: const Text('📦', style: TextStyle(fontSize: 72)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Inventario vuoto',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text('Apri un container per iniziare!',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 130, // max width per tile
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      final isSelected = _selected.contains(item.id);
                      return InventoryItemTile(
                        item: item,
                        isSelected: isSelected && _selectMode,
                        onTap: _selectMode ? () => setState(() {
                          if (isSelected) _selected.remove(item.id);
                          else _selected.add(item.id);
                        }) : null,
                        onLock: () async {
                          await sl<InventoryService>().toggleLock(item.id);
                          setState(() {});
                        },
                        onSell: () async {
                          await sl<InventoryService>().sellItem(item.id);
                          ref.read(playerNotifierProvider.notifier).refresh();
                          setState(() {});
                        },
                      );
                    },
                  ),
          ),

          // Multi-sell bar
          if (_selectMode && _selected.isNotEmpty)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.navBackground,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Text('${_selected.length} selezionati', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _sellSelected,
                      icon: const Text('💰', style: TextStyle(fontSize: 16)),
                      label: const Text('VENDI', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coins,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _sortLabel(SortMode m) {
    switch (m) {
      case SortMode.newest: return 'Più recenti';
      case SortMode.oldest: return 'Più vecchi';
      case SortMode.valueDesc: return 'Valore ↓';
      case SortMode.valueAsc: return 'Valore ↑';
      case SortMode.rarityDesc: return 'Rarità ↓';
    }
  }

  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
