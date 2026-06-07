import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';
import '../../../widgets/common/neon_text.dart';

class _UpgradeDef {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color color;
  final int Function(int level) gemCost;
  final String Function(int level) effectLabel;
  final String Function(int level) nextLabel;
  final int maxLevel;

  const _UpgradeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.gemCost,
    required this.effectLabel,
    required this.nextLabel,
    this.maxLevel = 10,
  });
}

final _upgrades = <_UpgradeDef>[
  _UpgradeDef(
    id: 'luck',
    name: 'FORTUNA',
    description: 'Riduce la probabilità di comune e aumenta quella di raro+',
    emoji: '🍀',
    color: AppColors.neonGold,
    gemCost: (lvl) => 5 + lvl * 10,
    effectLabel: (lvl) => lvl == 0 ? 'Nessun bonus' : '×${(1.0 + lvl * 0.15).toStringAsFixed(2)} Fortuna',
    nextLabel: (lvl) => '→ ×${(1.0 + (lvl + 1) * 0.15).toStringAsFixed(2)} Fortuna',
  ),
  _UpgradeDef(
    id: 'value',
    name: 'VALUE BOOST',
    description: 'Moltiplica il valore di vendita di tutti gli oggetti',
    emoji: '📈',
    color: AppColors.coins,
    gemCost: (lvl) => 8 + lvl * 12,
    effectLabel: (lvl) => lvl == 0 ? 'Nessun bonus' : '+${(lvl * 20)}% valore vendita',
    nextLabel: (lvl) => '→ +${((lvl + 1) * 20)}% valore vendita',
  ),
  _UpgradeDef(
    id: 'slots',
    name: 'INVENTARIO +',
    description: 'Espande la capienza dell\'inventario di 25 slot per livello',
    emoji: '🗄️',
    color: AppColors.neonPurple,
    gemCost: (lvl) => 3 + lvl * 5,
    effectLabel: (lvl) => '${50 + lvl * 25} slot totali',
    nextLabel: (lvl) => '→ ${50 + (lvl + 1) * 25} slot totali',
    maxLevel: 20,
  ),
  _UpgradeDef(
    id: 'mutation',
    name: 'MUTATION RATE',
    description: 'Aumenta la probabilità di ottenere mutazioni golden, diamond e galaxy',
    emoji: '🧬',
    color: AppColors.neonGreen,
    gemCost: (lvl) => 15 + lvl * 20,
    effectLabel: (lvl) => lvl == 0 ? 'Nessun bonus' : '+${lvl * 10}% chance mutazione',
    nextLabel: (lvl) => '→ +${(lvl + 1) * 10}% chance mutazione',
  ),
  _UpgradeDef(
    id: 'auto_open',
    name: 'AUTO OPEN',
    description: 'Apre automaticamente container FREE ogni N secondi mentre sei nella home',
    emoji: '🤖',
    color: AppColors.neonCyan,
    gemCost: (lvl) => 50 + lvl * 30,
    effectLabel: (lvl) => lvl == 0 ? 'Non attivo' : '1 free ogni ${60 ~/ lvl}s',
    nextLabel: (lvl) => '→ 1 free ogni ${lvl == 0 ? 60 : 60 ~/ (lvl + 1)}s',
    maxLevel: 5,
  ),
  _UpgradeDef(
    id: 'auto_sell',
    name: 'AUTO SELL',
    description: 'Vende automaticamente gli oggetti fino alla rarità selezionata',
    emoji: '💸',
    color: AppColors.neonOrange,
    gemCost: (lvl) => 25 + lvl * 15,
    effectLabel: (lvl) => lvl == 0 ? 'Non attivo' : 'Vende fino a: ${_rarityLabel(lvl)}',
    nextLabel: (lvl) => '→ vende fino a: ${_rarityLabel(lvl + 1)}',
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

int _getLevelFromPlayer(String id) {
  final ps = sl<PlayerService>();
  final p = ps.localPlayer;
  if (p == null) return 0;
  switch (id) {
    case 'luck': return p.luckUpgradeLevel;
    case 'value': return p.valueUpgradeLevel;
    case 'slots': return p.slotsUpgradeLevel;
    case 'mutation': return p.mutationUpgradeLevel;
    case 'auto_open': return p.autoOpenUpgradeLevel;
    case 'auto_sell': return p.autoSellUpgradeLevel;
    default: return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class UpgradesScreen extends ConsumerStatefulWidget {
  const UpgradesScreen({super.key});

  @override
  ConsumerState<UpgradesScreen> createState() => _UpgradesScreenState();
}

class _UpgradesScreenState extends ConsumerState<UpgradesScreen> {
  // Levels are loaded from PlayerModel on init and kept in sync
  final Map<String, int> _levels = {
    'luck': 0, 'value': 0, 'slots': 0, 'mutation': 0, 'auto_open': 0, 'auto_sell': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  void _loadLevels() {
    for (final id in _levels.keys) {
      _levels[id] = _getLevelFromPlayer(id);
    }
  }

  Future<void> _upgrade(_UpgradeDef def) async {
    final lvl = _levels[def.id] ?? 0;
    if (lvl >= def.maxLevel) {
      _showSnack('⭐ Livello massimo raggiunto!', AppColors.neonGold);
      return;
    }
    final cost = def.gemCost(lvl);
    final ps = sl<PlayerService>();
    final ok = await ps.spendGems(cost);
    if (!ok) {
      _showSnack('Gemme insufficienti! Servono $cost 💎', AppColors.error);
      return;
    }

    // Persist upgrade level in PlayerModel
    final player = ps.localPlayer;
    if (player != null) {
      final newLevel = lvl + 1;
      switch (def.id) {
        case 'luck':
          player.luckUpgradeLevel = newLevel;
          player.luckBoost = 1.0 + newLevel * 0.15;
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
    _showSnack('✅ ${def.name} → LV ${lvl + 1}!', AppColors.success);
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerNotifierProvider);
    final gems = playerAsync.when(
      data: (p) => p.gems,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('POTENZIAMENTI'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gems.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gems.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Text('💎', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('$gems',
                      style: const TextStyle(
                          color: AppColors.gems, fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.gems.withOpacity(0.12),
                AppColors.neonPurple.withOpacity(0.06),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gems.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Text('💎', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('I potenziamenti usano GEMME',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                      SizedBox(height: 2),
                      Text('Guadagna gemme salendo di livello e aprendo container. I livelli vengono salvati!',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _upgrades.length,
              itemBuilder: (_, i) {
                final def = _upgrades[i];
                final lvl = _levels[def.id] ?? 0;
                final cost = def.gemCost(lvl);
                final isMaxed = lvl >= def.maxLevel;
                final canAfford = gems >= cost;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UpgradeCard(
                    def: def,
                    level: lvl,
                    gemCost: cost,
                    isMaxed: isMaxed,
                    canAfford: canAfford,
                    onUpgrade: () => _upgrade(def),
                  ),
                ).animate(delay: Duration(milliseconds: i * 60))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.1, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final _UpgradeDef def;
  final int level;
  final int gemCost;
  final bool isMaxed;
  final bool canAfford;
  final VoidCallback onUpgrade;

  const _UpgradeCard({
    required this.def,
    required this.level,
    required this.gemCost,
    required this.isMaxed,
    required this.canAfford,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMaxed ? AppColors.neonGold : def.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(isMaxed ? 0.7 : 0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(isMaxed ? 0.15 : 0.05), blurRadius: 12)],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.4)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)],
            ),
            child: Center(child: Text(def.emoji, style: const TextStyle(fontSize: 26))),
          ),

          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NeonText(def.name, color: color, fontSize: 13, blurRadius: 5),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMaxed ? AppColors.neonGold.withOpacity(0.2) : color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isMaxed ? '⭐ MAX' : 'LV $level',
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(def.description,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                const SizedBox(height: 4),
                Text(
                  def.effectLabel(level),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                ),
                if (!isMaxed && level > 0)
                  Text(
                    def.nextLabel(level),
                    style: TextStyle(color: color.withOpacity(0.5), fontSize: 9),
                  ),

                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: level / def.maxLevel,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 2),
                Text('$level / ${def.maxLevel}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Button
          if (!isMaxed)
            GestureDetector(
              onTap: onUpgrade,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: canAfford ? color.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: canAfford ? color : AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(canAfford ? '⬆️' : '🔒', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    const Text('💎', style: TextStyle(fontSize: 12)),
                    Text(
                      '$gemCost',
                      style: TextStyle(
                        color: canAfford ? AppColors.gems : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonGold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonGold.withOpacity(0.5)),
              ),
              child: const Text('⭐\nMAX',
                  style: TextStyle(color: AppColors.neonGold, fontSize: 10, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}
