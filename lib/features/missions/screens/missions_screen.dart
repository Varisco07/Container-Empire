import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';


enum MissionType { daily, weekly, permanent }

class _MissionDef {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final MissionType type;
  final int target;
  final Color color;
  // Reward
  final double coinsReward;
  final int gemsReward;

  const _MissionDef({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.target,
    required this.color,
    this.coinsReward = 0,
    this.gemsReward = 0,
  });
}

final _missionDefs = <_MissionDef>[
  // Daily
  _MissionDef(id: 'daily_open_5', title: 'Apri 5 Container', description: 'Apri qualsiasi container 5 volte oggi',
      emoji: '📦', type: MissionType.daily, target: 5, color: AppColors.neonCyan,
      coinsReward: 1000, gemsReward: 2),
  _MissionDef(id: 'daily_sell_10', title: 'Vendi 10 Oggetti', description: 'Vendi 10 oggetti dall\'inventario',
      emoji: '💰', type: MissionType.daily, target: 10, color: AppColors.coins,
      coinsReward: 2000, gemsReward: 3),
  _MissionDef(id: 'daily_open_free', title: 'Container Gratuito', description: 'Apri il container gratuito del giorno',
      emoji: '🎁', type: MissionType.daily, target: 1, color: AppColors.neonGreen,
      coinsReward: 500, gemsReward: 1),

  // Weekly
  _MissionDef(id: 'weekly_open_50', title: 'Collezionista', description: 'Apri 50 container questa settimana',
      emoji: '🗃️', type: MissionType.weekly, target: 50, color: AppColors.neonPurple,
      coinsReward: 10000, gemsReward: 20),
  _MissionDef(id: 'weekly_sell_100', title: 'Grande Mercante', description: 'Vendi 100 oggetti',
      emoji: '💸', type: MissionType.weekly, target: 100, color: AppColors.neonOrange,
      coinsReward: 20000, gemsReward: 30),
  _MissionDef(id: 'weekly_rare_5', title: 'Cacciatore di Rari', description: 'Trova 5 oggetti Raro o superiore',
      emoji: '⭐', type: MissionType.weekly, target: 5, color: AppColors.rare,
      coinsReward: 15000, gemsReward: 50),

  // Permanent
  _MissionDef(id: 'perm_open_100', title: 'Centurione', description: 'Apri 100 container in totale',
      emoji: '🏆', type: MissionType.permanent, target: 100, color: AppColors.neonGold,
      coinsReward: 50000, gemsReward: 100),
  _MissionDef(id: 'perm_level_10', title: 'Esperto', description: 'Raggiungi il livello 10',
      emoji: '🎯', type: MissionType.permanent, target: 10, color: AppColors.epic,
      coinsReward: 30000, gemsReward: 75),
  _MissionDef(id: 'perm_earn_100k', title: 'Centomilionario', description: 'Guadagna 100.000€ in totale',
      emoji: '💎', type: MissionType.permanent, target: 100000, color: AppColors.legendary,
      coinsReward: 50000, gemsReward: 100),
  _MissionDef(id: 'perm_rare_10', title: 'Fortunato', description: 'Trova 10 oggetti rari o superiori',
      emoji: '🌟', type: MissionType.permanent, target: 10, color: AppColors.mythic,
      coinsReward: 100000, gemsReward: 200),
];

// ─────────────────────────────────────────────────────────────────────────────

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});
  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final Set<String> _claimed = {}; // In-session claimed (in real app: persisted)

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  int _getProgress(_MissionDef def, int containers, int sold, int rares, double earned, int level) {
    switch (def.id) {
      case 'daily_open_5': return containers.clamp(0, def.target);
      case 'daily_sell_10': return sold.clamp(0, def.target);
      case 'daily_open_free': return (containers > 0 ? 1 : 0);
      case 'weekly_open_50': return containers.clamp(0, def.target);
      case 'weekly_sell_100': return sold.clamp(0, def.target);
      case 'weekly_rare_5': return rares.clamp(0, def.target);
      case 'perm_open_100': return containers.clamp(0, def.target);
      case 'perm_level_10': return level.clamp(0, def.target);
      case 'perm_earn_100k': return earned.toInt().clamp(0, def.target);
      case 'perm_rare_10': return rares.clamp(0, def.target);
      default: return 0;
    }
  }

  Future<void> _claimReward(_MissionDef def) async {
    final ps = sl<PlayerService>();
    if (def.coinsReward > 0) await ps.addCoins(def.coinsReward);
    if (def.gemsReward > 0) await ps.addGems(def.gemsReward);
    ref.read(playerNotifierProvider.notifier).refresh();
    setState(() => _claimed.add(def.id));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎉 Missione completata! +${def.coinsReward > 0 ? "${_fmtCoin(def.coinsReward)}€" : ""}'
            '${def.gemsReward > 0 ? "  +${def.gemsReward}💎" : ""}'),
        backgroundColor: def.color,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerNotifierProvider);

    return playerAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      ),
      error: (e, _) => Scaffold(backgroundColor: AppColors.background,
          body: Center(child: Text('$e', style: const TextStyle(color: AppColors.error)))),
      data: (player) {
        final containers = player.totalContainersOpened;
        final sold = player.totalItemsSold;
        final rares = player.totalRaresFound;
        final earned = player.totalEarned;
        final level = player.level;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('MISSIONI'),
            bottom: TabBar(
              controller: _tab,
              labelColor: AppColors.neonCyan,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.neonCyan,
              tabs: const [
                Tab(text: 'GIORNALIERE'),
                Tab(text: 'SETTIMANALI'),
                Tab(text: 'PERMANENTI'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: MissionType.values.map((type) {
              final defs = _missionDefs.where((d) => d.type == type).toList();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.neonCyan.withOpacity(0.08), AppColors.neonPurple.withOpacity(0.04),
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatMini('📦', '$containers', 'Container'),
                        _StatMini('💰', '$sold', 'Venduti'),
                        _StatMini('⭐', '$rares', 'Rari'),
                        _StatMini('📈', _fmtCoin(earned), 'Guadagnati'),
                      ],
                    ),
                  ),
                  ...defs.asMap().entries.map((e) {
                    final i = e.key;
                    final def = e.value;
                    final progress = _getProgress(def, containers, sold, rares, earned, level);
                    final isComplete = progress >= def.target;
                    final isClaimed = _claimed.contains(def.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MissionCard(
                        def: def, progress: progress, isComplete: isComplete, isClaimed: isClaimed,
                        onClaim: () => _claimReward(def),
                      ),
                    ).animate(delay: Duration(milliseconds: i * 80)).fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
                  }),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _fmtCoin(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatMini extends StatelessWidget {
  final String icon, value, label;
  const _StatMini(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('$icon $value', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final _MissionDef def;
  final int progress;
  final bool isComplete;
  final bool isClaimed;
  final VoidCallback onClaim;

  const _MissionCard({
    required this.def, required this.progress, required this.isComplete,
    required this.isClaimed, required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final color = isClaimed ? AppColors.textMuted : def.color;
    final pct = (progress / def.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimed ? AppColors.border : isComplete ? color : color.withOpacity(0.3),
          width: isComplete && !isClaimed ? 2 : 1,
        ),
        boxShadow: isComplete && !isClaimed
            ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 16)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(def.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(def.title,
                      style: TextStyle(color: isClaimed ? AppColors.textMuted : AppColors.textPrimary,
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  Text(def.description,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ]),
              ),
              const SizedBox(width: 8),
              // Action button
              if (isClaimed)
                const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 28)
              else if (isComplete)
                GestureDetector(
                  onTap: onClaim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
                    ),
                    child: const Text('RISCATTA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, backgroundColor: AppColors.border, minHeight: 7,
              valueColor: AlwaysStoppedAnimation<Color>(isClaimed ? AppColors.neonGreen : color),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_fmt(progress)} / ${_fmt(def.target)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              // Reward preview
              Row(
                children: [
                  if (def.coinsReward > 0)
                    Text('🪙 ${_fmtCoin(def.coinsReward)}€',
                        style: TextStyle(color: isClaimed ? AppColors.textMuted : AppColors.coins,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  if (def.coinsReward > 0 && def.gemsReward > 0) const Text('  '),
                  if (def.gemsReward > 0)
                    Text('💎 ${def.gemsReward}',
                        style: TextStyle(color: isClaimed ? AppColors.textMuted : AppColors.gems,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }

  String _fmtCoin(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
