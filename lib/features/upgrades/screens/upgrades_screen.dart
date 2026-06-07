import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';

// ─── Upgrade definitions ──────────────────────────────────────────────────────

class _UpgradeDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int Function(int level) gemCost;
  final String Function(int level) effectLabel;
  final String Function(int level) nextLabel;
  final int maxLevel;

  const _UpgradeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.gemCost,
    required this.effectLabel,
    required this.nextLabel,
    this.maxLevel = 10,
  });
}

final _upgrades = <_UpgradeDef>[
  _UpgradeDef(
    id: 'luck', name: 'FORTUNA', icon: Icons.auto_awesome_rounded,
    description: 'Aumenta le chance di oggetti Rari, Epici e oltre',
    color: AppColors.neonGold,
    gemCost: (lvl) => 5 + lvl * 10,
    effectLabel: (lvl) => lvl == 0 ? 'Base' : '×${(1.0 + lvl * 0.15).toStringAsFixed(2)} Fortuna',
    nextLabel: (lvl) => '→ ×${(1.0 + (lvl + 1) * 0.15).toStringAsFixed(2)} Fortuna',
  ),
  _UpgradeDef(
    id: 'value', name: 'VALUE BOOST', icon: Icons.trending_up_rounded,
    description: 'Moltiplica il valore di vendita di tutti gli oggetti',
    color: AppColors.coins,
    gemCost: (lvl) => 8 + lvl * 12,
    effectLabel: (lvl) => lvl == 0 ? 'Base' : '+${lvl * 20}% valore',
    nextLabel: (lvl) => '→ +${(lvl + 1) * 20}% valore',
  ),
  _UpgradeDef(
    id: 'slots', name: 'INVENTARIO', icon: Icons.inventory_2_rounded,
    description: 'Espande la capienza dell\'inventario di 25 slot per livello',
    color: AppColors.neonPurple,
    gemCost: (lvl) => 3 + lvl * 5,
    effectLabel: (lvl) => '${50 + lvl * 25} slot totali',
    nextLabel: (lvl) => '→ ${50 + (lvl + 1) * 25} slot totali',
    maxLevel: 20,
  ),
  _UpgradeDef(
    id: 'mutation', name: 'MUTAZIONE', icon: Icons.science_rounded,
    description: 'Aumenta la probabilità di mutazioni Golden, Diamond e Galaxy',
    color: AppColors.neonGreen,
    gemCost: (lvl) => 15 + lvl * 20,
    effectLabel: (lvl) => lvl == 0 ? 'Base' : '+${lvl * 10}% mutazione',
    nextLabel: (lvl) => '→ +${(lvl + 1) * 10}% mutazione',
  ),
  _UpgradeDef(
    id: 'auto_open', name: 'AUTO OPEN', icon: Icons.smart_toy_rounded,
    description: 'Apre automaticamente container ogni tot secondi',
    color: AppColors.neonCyan,
    gemCost: (lvl) => 50 + lvl * 30,
    effectLabel: (lvl) => lvl == 0 ? 'Non attivo' : '1 ogni ${60 ~/ lvl}s',
    nextLabel: (lvl) => '→ 1 ogni ${lvl == 0 ? 60 : 60 ~/ (lvl + 1)}s',
    maxLevel: 5,
  ),
  _UpgradeDef(
    id: 'auto_sell', name: 'AUTO SELL', icon: Icons.sell_rounded,
    description: 'Vende automaticamente oggetti fino alla rarità selezionata',
    color: AppColors.neonOrange,
    gemCost: (lvl) => 25 + lvl * 15,
    effectLabel: (lvl) => lvl == 0 ? 'Non attivo' : 'Fino a: ${_rarityLabel(lvl)}',
    nextLabel: (lvl) => '→ fino a: ${_rarityLabel(lvl + 1)}',
    maxLevel: 4,
  ),
];

String _rarityLabel(int level) {
  if (level == 0) return 'Nulla';
  if (level == 1) return 'Comune';
  if (level == 2) return 'Non Comune';
  if (level == 3) return 'Raro';
  return 'Epico';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class UpgradesScreen extends ConsumerStatefulWidget {
  const UpgradesScreen({super.key});
  @override
  ConsumerState<UpgradesScreen> createState() => _UpgradesScreenState();
}

class _UpgradesScreenState extends ConsumerState<UpgradesScreen> {
  final Map<String, int> _levels = {
    'luck': 0, 'value': 0, 'slots': 0, 'mutation': 0, 'auto_open': 0, 'auto_sell': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  void _loadLevels() {
    final p = sl<PlayerService>().localPlayer;
    if (p == null) return;
    _levels['luck']      = p.luckUpgradeLevel;
    _levels['value']     = p.valueUpgradeLevel;
    _levels['slots']     = p.slotsUpgradeLevel;
    _levels['mutation']  = p.mutationUpgradeLevel;
    _levels['auto_open'] = p.autoOpenUpgradeLevel;
    _levels['auto_sell'] = p.autoSellUpgradeLevel;
  }

  Future<void> _upgrade(_UpgradeDef def) async {
    final lvl = _levels[def.id] ?? 0;
    if (lvl >= def.maxLevel) {
      _snack('⭐ Livello massimo raggiunto!', AppColors.neonGold);
      return;
    }
    final cost = def.gemCost(lvl);
    final ps = sl<PlayerService>();
    final ok = await ps.spendGems(cost);
    if (!ok) {
      _snack('Gemme insufficienti! Servono $cost 💎', AppColors.error);
      return;
    }

    final player = ps.localPlayer;
    if (player != null) {
      final newLevel = lvl + 1;
      switch (def.id) {
        case 'luck':
          player.luckUpgradeLevel = newLevel;
          player.luckBoost = 1.0 + newLevel * 0.15 + player.prestigeLuckBonus;
        case 'value':
          player.valueUpgradeLevel = newLevel;
          player.valueBoost = 1.0 + newLevel * 0.20;
        case 'slots':
          player.slotsUpgradeLevel = newLevel;
          player.inventorySlots = 50 + newLevel * 25;
        case 'mutation':
          player.mutationUpgradeLevel = newLevel;
          player.mutationBoost = 1.0 + newLevel * 0.10;
        case 'auto_open':
          player.autoOpenUpgradeLevel = newLevel;
          player.autoOpenEnabled = true;
        case 'auto_sell':
          player.autoSellUpgradeLevel = newLevel;
          player.autoSellEnabled = true;
      }
      await ps.savePlayer(player);
    }

    setState(() => _levels[def.id] = lvl + 1);
    ref.read(playerNotifierProvider.notifier).refresh();
    _snack('✅ ${def.name} → LV ${lvl + 1}!', AppColors.success);
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerNotifierProvider);
    final gems = playerAsync.maybeWhen(data: (p) => p.gems, orElse: () => 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('POTENZIAMENTI',
                style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900)),
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gems.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gems.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text('$gems',
                        style: const TextStyle(
                            color: AppColors.gems, fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final def = _upgrades[i];
                  final lvl = _levels[def.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UpgradeCard(
                      def: def,
                      level: lvl,
                      gemCost: def.gemCost(lvl),
                      isMaxed: lvl >= def.maxLevel,
                      canAfford: gems >= def.gemCost(lvl),
                      onUpgrade: () => _upgrade(def),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 60))
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
                },
                childCount: _upgrades.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upgrade card ─────────────────────────────────────────────────────────────

class _UpgradeCard extends StatelessWidget {
  final _UpgradeDef def;
  final int level;
  final int gemCost;
  final bool isMaxed;
  final bool canAfford;
  final VoidCallback onUpgrade;

  const _UpgradeCard({
    required this.def, required this.level, required this.gemCost,
    required this.isMaxed, required this.canAfford, required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMaxed ? AppColors.neonGold : def.color;
    final lvlFraction = level / def.maxLevel;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMaxed ? AppColors.neonGold.withOpacity(0.6) : color.withOpacity(0.25),
        ),
        boxShadow: isMaxed
            ? [BoxShadow(color: AppColors.neonGold.withOpacity(0.15), blurRadius: 20)]
            : null,
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.25), color.withOpacity(0.08)],
                    ),
                    border: Border.all(color: color.withOpacity(0.5)),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 12)],
                  ),
                  child: Icon(def.icon, color: color, size: 28,
                      shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 8)]),
                ),
                const SizedBox(width: 14),

                // Name + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(def.name,
                              style: TextStyle(
                                  color: color, fontSize: 14,
                                  fontWeight: FontWeight.w900, letterSpacing: 0.5,
                                  shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 6)])),
                          const SizedBox(width: 8),
                          _LevelBadge(level: level, maxLevel: def.maxLevel, color: color, isMaxed: isMaxed),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(def.description,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      const SizedBox(height: 6),
                      Text(
                        def.effectLabel(level),
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      if (!isMaxed && level > 0)
                        Text(def.nextLabel(level),
                            style: TextStyle(color: color.withOpacity(0.5), fontSize: 10)),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Upgrade button
                if (!isMaxed)
                  _UpgradeButton(
                    gemCost: gemCost, canAfford: canAfford, color: color, onTap: onUpgrade,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.neonGold, Color(0xFFFF9500)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('⭐', style: TextStyle(fontSize: 18)),
                        Text('MAX', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Progress bar footer
          Container(
            height: 4,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Container(color: AppColors.border),
                  FractionallySizedBox(
                    widthFactor: lvlFraction,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          isMaxed ? AppColors.neonGold : color,
                          isMaxed ? const Color(0xFFFF9500) : color.withOpacity(0.7),
                        ]),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
                      ),
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
}

class _LevelBadge extends StatelessWidget {
  final int level, maxLevel;
  final Color color;
  final bool isMaxed;
  const _LevelBadge({required this.level, required this.maxLevel, required this.color, required this.isMaxed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isMaxed ? AppColors.neonGold.withOpacity(0.15) : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isMaxed ? AppColors.neonGold.withOpacity(0.5) : color.withOpacity(0.3)),
      ),
      child: Text(
        isMaxed ? '⭐ MAX' : 'LV $level / $maxLevel',
        style: TextStyle(
          color: isMaxed ? AppColors.neonGold : color,
          fontSize: 9, fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  final int gemCost;
  final bool canAfford;
  final Color color;
  final VoidCallback onTap;
  const _UpgradeButton({required this.gemCost, required this.canAfford, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: canAfford
              ? LinearGradient(colors: [color, color.withOpacity(0.7)])
              : null,
          color: canAfford ? null : AppColors.border.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: canAfford
              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              canAfford ? Icons.arrow_upward_rounded : Icons.lock_rounded,
              color: canAfford ? Colors.white : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(height: 3),
            const Text('💎', style: TextStyle(fontSize: 11)),
            Text(
              '$gemCost',
              style: TextStyle(
                color: canAfford ? Colors.white : AppColors.textMuted,
                fontSize: 12, fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
