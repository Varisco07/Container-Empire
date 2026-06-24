import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/item_model.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snack_helper.dart';
import '../../../features/profile/providers/player_provider.dart';

class DustScreen extends ConsumerStatefulWidget {
  const DustScreen({super.key});

  @override
  ConsumerState<DustScreen> createState() => _DustScreenState();
}

class _DustScreenState extends ConsumerState<DustScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: const BoxDecoration(
              color: Color(0xFF0A1020),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('🌫️', style: TextStyle(fontSize: 22, decoration: TextDecoration.none)),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF8B7FF0), Color(0xFFB8A5FF)],
                    ).createShader(b),
                    child: const Text('ALCHIMIA DUST', style: TextStyle(
                      color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2,
                      decoration: TextDecoration.none,
                    )),
                  ),
                  const Spacer(),
                  ref.watch(playerNotifierProvider).when(
                    data: (p) => _DustBadge(dust: p.dust),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ]),
                const SizedBox(height: 4),
                const Text(
                  'Smantella item → ottieni Dust → usalo per mutazioni e ticket',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11,
                      decoration: TextDecoration.none),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tab,
                  labelColor: const Color(0xFF8B7FF0),
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 11,
                      decoration: TextDecoration.none),
                  unselectedLabelStyle: const TextStyle(
                      decoration: TextDecoration.none),
                  indicatorColor: const Color(0xFF8B7FF0),
                  indicatorWeight: 2.5,
                  tabs: const [
                    Tab(text: '⬆️  POTENZIA'),
                    Tab(text: '🎲  REROLL'),
                    Tab(text: '🎟️  TICKET'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _UpgradeMutationTab(),
                _RerollTab(),
                const _TicketTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dust badge ───────────────────────────────────────────────────────────────

class _DustBadge extends StatelessWidget {
  final double dust;
  const _DustBadge({required this.dust});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF3D2F6E), Color(0xFF5B4A9A)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B7FF0).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8B7FF0).withOpacity(0.3), blurRadius: 12)
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🌫️',
            style: TextStyle(fontSize: 14, decoration: TextDecoration.none)),
        const SizedBox(width: 6),
        Text(
          _fmt(dust),
          style: const TextStyle(
            color: Color(0xFFB8A5FF),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
        ),
      ]),
    );
  }

  static String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Upgrade Mutation tab ─────────────────────────────────────────────────────
// Usa il Dust per SALIRE DI TIER la mutazione di un item (non → golden → diamond…)
// Nessun conflitto con gli Upgrade a monete che potenziano le statistiche.

class _UpgradeMutationTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UpgradeMutationTab> createState() =>
      _UpgradeMutationTabState();
}

class _UpgradeMutationTabState extends ConsumerState<_UpgradeMutationTab> {
  ItemModel? _selectedItem;

  // Costo per salire di un tier di mutazione (none→golden→diamond→radioactive→galaxy→void)
  static const _upgradeCosts = <String, double>{
    'none':         800,   // none → golden
    'golden':      3000,   // golden → diamond
    'diamond':    12000,   // diamond → radioactive
    'radioactive': 50000,  // radioactive → galaxy
    'galaxy':     200000,  // galaxy → void
  };

  static const _nextMutation = <String, String>{
    'none': 'golden',
    'golden': 'diamond',
    'diamond': 'radioactive',
    'radioactive': 'galaxy',
    'galaxy': 'voidMutation',
  };

  static const _mutEmoji = <String, String>{
    'none': '⬜',
    'golden': '✨',
    'diamond': '💎',
    'radioactive': '☢️',
    'galaxy': '🌌',
    'voidMutation': '🕳️',
  };

  static const _mutName = <String, String>{
    'none': 'Nessuna',
    'golden': 'Golden',
    'diamond': 'Diamond',
    'radioactive': 'Radioactive',
    'galaxy': 'Galaxy',
    'voidMutation': 'Void',
  };

  List<ItemModel> get _upgradableItems => sl<InventoryService>()
      .allItems
      .where((i) => !i.isLocked && i.mutationKey != 'voidMutation')
      .toList()
    ..sort((a, b) => b.finalValue.compareTo(a.finalValue));

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerNotifierProvider);
    final dust = playerAsync.value?.dust ?? 0;
    final items = _upgradableItems;

    return Column(
      children: [
        // Spiegazione
        Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1520),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF8B7FF0).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('POTENZIA MUTAZIONE', style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1,
                decoration: TextDecoration.none,
              )),
              const SizedBox(height: 6),
              const Text(
                'Scegli un item dal tuo inventario e usa il Dust per salire di un livello di mutazione. '
                'Ogni upgrade è permanente.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11,
                    height: 1.4, decoration: TextDecoration.none),
              ),
              const SizedBox(height: 10),
              _MutationTierRow(),
            ],
          ),
        ),

        // Lista item
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text('Nessun item potenziabile',
                      style: TextStyle(color: AppColors.textMuted,
                          decoration: TextDecoration.none)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    final isSelected = _selectedItem?.id == item.id;
                    final curMut = item.mutationKey;
                    final nextMut = _nextMutation[curMut];
                    final cost = _upgradeCosts[curMut] ?? double.infinity;
                    final canAfford = dust >= cost;
                    final rarityColor = AppColors.rarityColor(item.rarityKey);

                    return GestureDetector(
                      onTap: () => setState(() =>
                          _selectedItem = isSelected ? null : item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8B7FF0).withOpacity(0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B7FF0)
                                : rarityColor.withOpacity(0.25),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          // Item info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: TextStyle(
                                      color: rarityColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      decoration: TextDecoration.none,
                                    )),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Text(
                                    '${_mutEmoji[curMut] ?? '⬜'} ${_mutName[curMut] ?? curMut}',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                        decoration: TextDecoration.none),
                                  ),
                                  if (nextMut != null) ...[
                                    const Text('  →  ',
                                        style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                            decoration: TextDecoration.none)),
                                    Text(
                                      '${_mutEmoji[nextMut] ?? ''} ${_mutName[nextMut] ?? nextMut}',
                                      style: const TextStyle(
                                        color: Color(0xFFB8A5FF),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ]),
                              ],
                            ),
                          ),
                          // Cost + button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(children: [
                                const Text('🌫️',
                                    style: TextStyle(
                                        fontSize: 12,
                                        decoration: TextDecoration.none)),
                                const SizedBox(width: 3),
                                Text(
                                  _fmt(cost),
                                  style: TextStyle(
                                    color: canAfford
                                        ? const Color(0xFFB8A5FF)
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: canAfford && nextMut != null
                                    ? () => _upgrade(item, nextMut, cost)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: canAfford && nextMut != null
                                        ? const LinearGradient(colors: [
                                            Color(0xFF8B7FF0),
                                            Color(0xFF5B4A9A)
                                          ])
                                        : null,
                                    color: canAfford && nextMut != null
                                        ? null
                                        : AppColors.border,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: canAfford && nextMut != null
                                        ? [
                                            BoxShadow(
                                                color: const Color(0xFF8B7FF0)
                                                    .withOpacity(0.4),
                                                blurRadius: 8)
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    nextMut != null
                                        ? (canAfford ? 'POTENZIA' : 'N/A')
                                        : 'MAX',
                                    style: TextStyle(
                                      color: canAfford && nextMut != null
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _upgrade(ItemModel item, String nextMut, double cost) async {
    final ps = sl<PlayerService>();
    final ok = await ps.spendDust(cost);
    if (!ok) {
      if (mounted) showSnack(context, '❌ Dust insufficiente!', type: SnackType.error);
      return;
    }
    // Aggiorna la mutazione nell'inventario
    final inv = sl<InventoryService>();
    await inv.upgradeMutation(item.id, nextMut);
    ref.read(playerNotifierProvider.notifier).refresh();
    setState(() {});
    if (mounted) {
      final emoji = _mutEmoji[nextMut] ?? '';
      final name = _mutName[nextMut] ?? nextMut;
      showSnack(context, '$emoji ${item.name}: ora è $name!',
          type: SnackType.success);
    }
  }

  static String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Mutation tier row ────────────────────────────────────────────────────────

class _MutationTierRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const tiers = [
      ('⬜', 'Nessuna', Colors.grey),
      ('✨', 'Golden', Color(0xFFFFD700)),
      ('💎', 'Diamond', Color(0xFF00BFFF)),
      ('☢️', 'Radioactive', Color(0xFF7FFF00)),
      ('🌌', 'Galaxy', Color(0xFF9370DB)),
      ('🕳️', 'Void', Color(0xFF6A0DAD)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tiers.asMap().entries.map((e) {
          final i = e.key;
          final (emoji, name, color) = e.value;
          return Row(children: [
            Column(children: [
              Text(emoji,
                  style: const TextStyle(
                      fontSize: 16, decoration: TextDecoration.none)),
              const SizedBox(height: 2),
              Text(name,
                  style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none)),
            ]),
            if (i < tiers.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('→',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        decoration: TextDecoration.none)),
              ),
          ]);
        }).toList(),
      ),
    );
  }
}

// ─── Reroll tab ───────────────────────────────────────────────────────────────

class _RerollTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RerollTab> createState() => _RerollTabState();
}

class _RerollTabState extends ConsumerState<_RerollTab> {
  ItemModel? _selectedItem;
  String? _resultMutation;
  bool _rolling = false;

  List<ItemModel> get _rerollableItems => sl<InventoryService>()
      .allItems
      .where((i) => !i.isLocked)
      .toList()
    ..sort((a, b) => b.finalValue.compareTo(a.finalValue));

  double _rerollCost(String rarityKey) {
    switch (rarityKey) {
      case 'common':
      case 'uncommon':   return 100;
      case 'rare':
      case 'epic':       return 500;
      case 'legendary':
      case 'mythic':     return 3000;
      case 'divine':
      case 'secret':     return 20000;
      case 'cosmic':     return 150000;
      default:           return 100;
    }
  }

  String _rollRandomMutation() {
    final roll = (DateTime.now().millisecondsSinceEpoch % 100).toDouble();
    if (roll < 2)   return 'voidMutation';
    if (roll < 7)   return 'galaxy';
    if (roll < 15)  return 'radioactive';
    if (roll < 30)  return 'diamond';
    if (roll < 60)  return 'golden';
    return 'none';
  }

  static const _mutEmoji = <String, String>{
    'none': '⬜', 'golden': '✨', 'diamond': '💎',
    'radioactive': '☢️', 'galaxy': '🌌', 'voidMutation': '🕳️',
  };
  static const _mutName = <String, String>{
    'none': 'Nessuna mutazione', 'golden': 'Golden', 'diamond': 'Diamond',
    'radioactive': 'Radioactive', 'galaxy': 'Galaxy', 'voidMutation': 'Void',
  };

  @override
  Widget build(BuildContext context) {
    final dust = ref.watch(playerNotifierProvider).value?.dust ?? 0;
    final items = _rerollableItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spiegazione
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1520),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF8B7FF0).withOpacity(0.2)),
            ),
            child: const Text(
              'Rirollia la mutazione di un item in modo casuale. '
              'La rarità rimane invariata, ma la mutazione cambia. '
              'Attenzione: potresti ottenere una mutazione peggiore!',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12,
                  height: 1.5, decoration: TextDecoration.none),
            ),
          ),
          const SizedBox(height: 14),

          // Costi
          const _CostTable(rows: [
            ('Comune / Non Com.', '100 🌫️'),
            ('Raro / Epico', '500 🌫️'),
            ('Leggendario / Mitico', '3.000 🌫️'),
            ('Divino / Segreto', '20.000 🌫️'),
            ('Cosmico', '150.000 🌫️'),
          ]),
          const SizedBox(height: 14),

          // Probabilità risultato
          const _CostTable(rows: [
            ('Void 🕳️', '2%'),
            ('Galaxy 🌌', '5%'),
            ('Radioactive ☢️', '8%'),
            ('Diamond 💎', '15%'),
            ('Golden ✨', '30%'),
            ('Nessuna ⬜', '40%'),
          ]),
          const SizedBox(height: 16),

          // Selezione item
          const Text('SCEGLI UN ITEM', style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w900,
            fontSize: 12, letterSpacing: 1,
            decoration: TextDecoration.none,
          )),
          const SizedBox(height: 8),

          if (items.isEmpty)
            const Text('Inventario vuoto',
                style: TextStyle(color: AppColors.textMuted,
                    decoration: TextDecoration.none))
          else
            ...items.map((item) {
              final isSelected = _selectedItem?.id == item.id;
              final cost = _rerollCost(item.rarityKey);
              final canAfford = dust >= cost;
              final color = AppColors.rarityColor(item.rarityKey);

              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedItem = isSelected ? null : item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B7FF0).withOpacity(0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8B7FF0)
                          : color.withOpacity(0.25),
                    ),
                  ),
                  child: Row(children: [
                    Text(item.name,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        )),
                    const SizedBox(width: 8),
                    Text(
                      _mutEmoji[item.mutationKey] ?? '⬜',
                      style: const TextStyle(
                          fontSize: 12, decoration: TextDecoration.none),
                    ),
                    const Spacer(),
                    Text('🌫️ ${_fmt(cost)}',
                        style: TextStyle(
                          color: canAfford
                              ? const Color(0xFFB8A5FF)
                              : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        )),
                  ]),
                ),
              );
            }),

          const SizedBox(height: 16),

          // Result
          if (_resultMutation != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF8B7FF0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF8B7FF0).withOpacity(0.4)),
              ),
              child: Row(children: [
                Text(_mutEmoji[_resultMutation] ?? '⬜',
                    style: const TextStyle(
                        fontSize: 28, decoration: TextDecoration.none)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('RISULTATO REROLL',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 1,
                        decoration: TextDecoration.none,
                      )),
                  Text(
                    _mutName[_resultMutation] ?? _resultMutation!,
                    style: const TextStyle(
                      color: Color(0xFFB8A5FF),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ]),
              ]),
            ),

          const SizedBox(height: 16),

          // Reroll button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedItem == null || _rolling
                  ? null
                  : () => _doReroll(dust),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7FF0),
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _rolling
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      _selectedItem == null
                          ? 'Seleziona un item'
                          : '🎲  REROLL  ·  🌫️ ${_fmt(_rerollCost(_selectedItem!.rarityKey))}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doReroll(double dust) async {
    final item = _selectedItem!;
    final cost = _rerollCost(item.rarityKey);
    if (dust < cost) {
      showSnack(context, '❌ Dust insufficiente!', type: SnackType.error);
      return;
    }
    setState(() => _rolling = true);
    final ps = sl<PlayerService>();
    await ps.spendDust(cost);
    await Future.delayed(const Duration(milliseconds: 700));
    final newMut = _rollRandomMutation();
    await sl<InventoryService>().upgradeMutation(item.id, newMut);
    ref.read(playerNotifierProvider.notifier).refresh();
    setState(() {
      _rolling = false;
      _resultMutation = newMut;
    });
  }

  static String _fmt(double v) {
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Ticket tab ───────────────────────────────────────────────────────────────

class _TicketTab extends ConsumerWidget {
  const _TicketTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dust = ref.watch(playerNotifierProvider).value?.dust ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TICKET EVENTO', style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1,
            decoration: TextDecoration.none,
          )),
          const SizedBox(height: 6),
          const Text(
            'Converti Dust in Ticket per container evento esclusivi. '
            'I ticket non scadono.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12,
                height: 1.5, decoration: TextDecoration.none),
          ),
          const SizedBox(height: 20),
          _TicketCard(
            emoji: '🎟️',
            title: 'Ticket Standard',
            description: 'Apri un container evento  ·  loot Raro+',
            cost: 2500,
            color: const Color(0xFF4CAF50),
            onBuy: (ctx, r) => _buy(ctx, r, 2500, 'Ticket Standard'),
          ),
          const SizedBox(height: 10),
          _TicketCard(
            emoji: '🎫',
            title: 'Ticket Premium',
            description: 'Apri un container premium  ·  loot Epico+',
            cost: 10000,
            color: AppColors.neonPurple,
            onBuy: (ctx, r) => _buy(ctx, r, 10000, 'Ticket Premium'),
          ),
          const SizedBox(height: 10),
          _TicketCard(
            emoji: '🌟',
            title: 'Ticket Leggendario',
            description: 'Container esclusivo  ·  Leggendario garantito',
            cost: 50000,
            color: AppColors.neonGold,
            onBuy: (ctx, r) => _buy(ctx, r, 50000, 'Ticket Leggendario'),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Text('🌫️ Il tuo Dust: ',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    decoration: TextDecoration.none)),
            Text(_fmt(dust),
                style: const TextStyle(
                  color: Color(0xFFB8A5FF),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                )),
          ]),
        ],
      ),
    );
  }

  static Future<void> _buy(
      BuildContext context, WidgetRef ref, int cost, String name) async {
    final ps = sl<PlayerService>();
    final ok = await ps.spendDust(cost.toDouble());
    if (!ok) {
      if (context.mounted) {
        showSnack(context, '❌ Dust insufficiente!', type: SnackType.error);
      }
      return;
    }
    ref.read(playerNotifierProvider.notifier).refresh();
    if (context.mounted) {
      showSnack(context, '🎟️ $name ottenuto! Usalo negli eventi.',
          type: SnackType.success);
    }
  }

  static String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _TicketCard extends ConsumerWidget {
  final String emoji, title, description;
  final int cost;
  final Color color;
  final void Function(BuildContext, WidgetRef) onBuy;

  const _TicketCard({
    required this.emoji, required this.title, required this.description,
    required this.cost, required this.color, required this.onBuy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dust = ref.watch(playerNotifierProvider).value?.dust ?? 0;
    final canAfford = dust >= cost;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: canAfford ? color.withOpacity(0.4) : AppColors.border),
        boxShadow: canAfford
            ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12)]
            : null,
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Center(
              child: Text(emoji,
                  style: const TextStyle(
                      fontSize: 26, decoration: TextDecoration.none))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w800,
            fontSize: 13, decoration: TextDecoration.none,
          )),
          const SizedBox(height: 3),
          Text(description, style: const TextStyle(
              color: AppColors.textMuted, fontSize: 10,
              height: 1.3, decoration: TextDecoration.none)),
          const SizedBox(height: 5),
          Row(children: [
            const Text('🌫️ ', style: TextStyle(fontSize: 11, decoration: TextDecoration.none)),
            Text(_fmt(cost.toDouble()), style: TextStyle(
              color: canAfford ? const Color(0xFFB8A5FF) : AppColors.textMuted,
              fontWeight: FontWeight.w800, fontSize: 12,
              decoration: TextDecoration.none,
            )),
          ]),
        ])),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: canAfford ? () => onBuy(context, ref) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: canAfford ? color : AppColors.border,
              borderRadius: BorderRadius.circular(12),
              boxShadow: canAfford
                  ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]
                  : null,
            ),
            child: Text(
              canAfford ? 'RISCATTA' : 'N/A',
              style: TextStyle(
                color: canAfford ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w900, fontSize: 11,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  static String _fmt(double v) {
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Cost table helper ────────────────────────────────────────────────────────

class _CostTable extends StatelessWidget {
  final List<(String, String)> rows;
  const _CostTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1520),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF8B7FF0).withOpacity(0.15)),
      ),
      child: Column(children: rows.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Expanded(child: Text(r.$1, style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11,
              decoration: TextDecoration.none))),
          Text(r.$2, style: const TextStyle(
            color: Color(0xFFB8A5FF), fontWeight: FontWeight.w700,
            fontSize: 11, decoration: TextDecoration.none,
          )),
        ]),
      )).toList()),
    );
  }
}
