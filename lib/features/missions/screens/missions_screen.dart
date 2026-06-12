import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';

// ─── Mission definitions ──────────────────────────────────────────────────────

enum MissionType { daily, weekly, permanent }

class _MissionDef {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final MissionType type;
  final int target;
  final Color color;
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
  // Daily — rewards calibrati su costo basic container (100€)
  _MissionDef(
    id: 'daily_open_5', title: 'Apri 5 Container',
    description: 'Apri qualsiasi container 5 volte oggi',
    emoji: '📦', type: MissionType.daily, target: 5, color: AppColors.neonCyan,
    coinsReward: 150, gemsReward: 1,
  ),
  _MissionDef(
    id: 'daily_sell_10', title: 'Vendi 10 Oggetti',
    description: 'Vendi 10 oggetti dall\'inventario oggi',
    emoji: '💰', type: MissionType.daily, target: 10, color: AppColors.coins,
    coinsReward: 300, gemsReward: 1,
  ),
  _MissionDef(
    id: 'daily_rares_1', title: 'Trova 1 Raro',
    description: 'Ottieni almeno 1 oggetto Raro o superiore oggi',
    emoji: '⭐', type: MissionType.daily, target: 1, color: AppColors.rare,
    coinsReward: 200, gemsReward: 1,
  ),

  // Weekly
  _MissionDef(
    id: 'weekly_open_50', title: 'Collezionista',
    description: 'Apri 50 container questa settimana',
    emoji: '🗃️', type: MissionType.weekly, target: 50, color: AppColors.neonPurple,
    coinsReward: 2000, gemsReward: 5,
  ),
  _MissionDef(
    id: 'weekly_sell_100', title: 'Grande Mercante',
    description: 'Vendi 100 oggetti questa settimana',
    emoji: '💸', type: MissionType.weekly, target: 100, color: AppColors.neonOrange,
    coinsReward: 3500, gemsReward: 8,
  ),
  _MissionDef(
    id: 'weekly_rare_5', title: 'Cacciatore di Rari',
    description: 'Trova 5 oggetti Raro o superiore questa settimana',
    emoji: '🏆', type: MissionType.weekly, target: 5, color: AppColors.rare,
    coinsReward: 2500, gemsReward: 10,
  ),

  // Permanent — one-time, rewards proporzionali all'effort
  _MissionDef(
    id: 'perm_open_100', title: 'Centurione',
    description: 'Apri 100 container in totale',
    emoji: '🎖️', type: MissionType.permanent, target: 100, color: AppColors.neonGold,
    coinsReward: 8000, gemsReward: 15,
  ),
  _MissionDef(
    id: 'perm_level_10', title: 'Esperto',
    description: 'Raggiungi il livello 10',
    emoji: '🎯', type: MissionType.permanent, target: 10, color: AppColors.epic,
    coinsReward: 5000, gemsReward: 10,
  ),
  _MissionDef(
    id: 'perm_earn_100k', title: 'Centomilionario',
    description: 'Guadagna 🪙 100.000 in totale',
    emoji: '💎', type: MissionType.permanent, target: 100000, color: AppColors.legendary,
    coinsReward: 10000, gemsReward: 20,
  ),
  _MissionDef(
    id: 'perm_rare_10', title: 'Fortunato',
    description: 'Trova 10 oggetti Raro o superiori in totale',
    emoji: '🌟', type: MissionType.permanent, target: 10, color: AppColors.mythic,
    coinsReward: 12000, gemsReward: 25,
  ),
  _MissionDef(
    id: 'perm_level_25', title: 'Veterano',
    description: 'Raggiungi il livello 25',
    emoji: '🔱', type: MissionType.permanent, target: 25, color: AppColors.divine,
    coinsReward: 20000, gemsReward: 40,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});
  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Box<dynamic>? _claimsBox;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _openClaimsBox();
  }

  // Snapshot dei stat all'inizio del giorno/settimana corrente
  // Chiave: "snap_daily_Y_M_D_stat" o "snap_weekly_Y_wW_stat"
  int _snapVal(String periodKey, String stat, int currentVal) {
    final key = '${periodKey}_$stat';
    final stored = _claimsBox?.get(key) as int?;
    if (stored == null) {
      // Prima volta oggi/questa settimana: salva snapshot
      _claimsBox?.put(key, currentVal);
      return currentVal;
    }
    return stored;
  }

  String get _dailyKey {
    final n = DateTime.now();
    return 'snap_daily_${n.year}_${n.month}_${n.day}';
  }

  String get _weeklyKey {
    final n = DateTime.now();
    final w = n.difference(DateTime(n.year, 1, 1)).inDays ~/ 7;
    return 'snap_weekly_${n.year}_w$w';
  }

  // Progresso relativo al periodo (delta rispetto allo snapshot)
  int _deltaProgress(MissionType type, String stat, int currentVal) {
    if (_claimsBox == null) return 0;
    if (type == MissionType.permanent) return currentVal;
    final periodKey = type == MissionType.daily ? _dailyKey : _weeklyKey;
    final snap = _snapVal(periodKey, stat, currentVal);
    return (currentVal - snap).clamp(0, 999999);
  }

  Future<void> _openClaimsBox() async {
    final box = await Hive.openBox<dynamic>('mission_claims');
    if (mounted) setState(() => _claimsBox = box);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // Unique key per tipo — daily/weekly include data, permanent è fisso
  String _claimKey(String id, MissionType type) {
    final now = DateTime.now();
    switch (type) {
      case MissionType.daily:
        return '${id}_${now.year}_${now.month}_${now.day}';
      case MissionType.weekly:
        final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
        final week = dayOfYear ~/ 7;
        return '${id}_${now.year}_w$week';
      case MissionType.permanent:
        return id;
    }
  }

  bool _isClaimed(String id, MissionType type) =>
      _claimsBox?.get(_claimKey(id, type)) == true;

  int _getProgress(_MissionDef def, int containers, int sold, int rares, double earned, int level) {
    switch (def.id) {
      // Daily — delta rispetto allo snapshot di oggi
      case 'daily_open_5':   return _deltaProgress(def.type, 'containers', containers).clamp(0, def.target);
      case 'daily_sell_10':  return _deltaProgress(def.type, 'sold', sold).clamp(0, def.target);
      case 'daily_rares_1':  return _deltaProgress(def.type, 'rares', rares).clamp(0, def.target);
      // Weekly — delta rispetto allo snapshot di questa settimana
      case 'weekly_open_50': return _deltaProgress(def.type, 'containers', containers).clamp(0, def.target);
      case 'weekly_sell_100':return _deltaProgress(def.type, 'sold', sold).clamp(0, def.target);
      case 'weekly_rare_5':  return _deltaProgress(def.type, 'rares', rares).clamp(0, def.target);
      // Permanent — totale cumulativo
      case 'perm_open_100':  return containers.clamp(0, def.target);
      case 'perm_level_10':  return level.clamp(0, def.target);
      case 'perm_earn_100k': return earned.toInt().clamp(0, def.target);
      case 'perm_rare_10':   return rares.clamp(0, def.target);
      case 'perm_level_25':  return level.clamp(0, def.target);
      default: return 0;
    }
  }

  Future<void> _claimReward(_MissionDef def) async {
    final box = _claimsBox;
    if (box == null) return;
    final key = _claimKey(def.id, def.type);
    if (box.get(key) == true) return; // already claimed

    final ps = sl<PlayerService>();
    if (def.coinsReward > 0) await ps.addCoins(def.coinsReward);
    if (def.gemsReward > 0) await ps.addGems(def.gemsReward);
    await box.put(key, true);

    ref.read(playerNotifierProvider.notifier).refresh();
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            Text(def.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(
              '${def.title} completata!'
              '${def.coinsReward > 0 ? "  +🪙 ${_fmtV(def.coinsReward)}" : ""}'
              '${def.gemsReward > 0 ? "  +${def.gemsReward}💎" : ""}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: def.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('$e', style: const TextStyle(color: AppColors.error))),
      ),
      data: (player) {
        final containers = player.totalContainersOpened;
        final sold      = player.totalItemsSold;
        final rares     = player.totalRaresFound;
        final earned    = player.totalEarned;
        final level     = player.level;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              SliverAppBar(
                title: const Text('MISSIONI', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900)),
                floating: true,
                snap: true,
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: _MissionTabBar(controller: _tab),
                ),
              ),
            ],
            body: Column(
              children: [
                // Stats mini-bar
                _StatsBar(containers: containers, sold: sold, rares: rares, earned: earned),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: MissionType.values.map((type) {
                      final defs = _missionDefs.where((d) => d.type == type).toList();
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: defs.length,
                        itemBuilder: (_, i) {
                          final def = defs[i];
                          final progress = _getProgress(def, containers, sold, rares, earned, level);
                          final isComplete = progress >= def.target;
                          final isClaimed = _isClaimed(def.id, def.type);
                          return _MissionCard(
                            def: def,
                            progress: progress,
                            isComplete: isComplete,
                            isClaimed: isClaimed,
                            onClaim: () => _claimReward(def),
                            index: i,
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtV(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Tab bar ──────────────────────────────────────────────────────────────────

class _MissionTabBar extends StatelessWidget {
  final TabController controller;
  const _MissionTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: controller,
        labelColor: Colors.black,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple]),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(text: 'GIORNALIERE'),
          Tab(text: 'SETTIMANALI'),
          Tab(text: 'PERMANENTI'),
        ],
      ),
    );
  }
}

// ─── Stats bar ────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final int containers, sold, rares;
  final double earned;
  const _StatsBar({required this.containers, required this.sold, required this.rares, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell('📦', '$containers', 'Container'),
            _vDivider(),
            _StatCell('💰', '$sold', 'Venduti'),
            _vDivider(),
            _StatCell('⭐', '$rares', 'Rari'),
            _vDivider(),
            _StatCell('📈', _fmt(earned), 'Guadagnati'),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 0.5, height: double.infinity, color: AppColors.border,
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );

  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatCell extends StatelessWidget {
  final String icon, value, label;
  const _StatCell(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$icon $value',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 8)),
      ],
    ),
  );
}

// ─── Mission card ─────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final _MissionDef def;
  final int progress;
  final bool isComplete;
  final bool isClaimed;
  final VoidCallback onClaim;
  final int index;

  const _MissionCard({
    required this.def,
    required this.progress,
    required this.isComplete,
    required this.isClaimed,
    required this.onClaim,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = isClaimed ? AppColors.textMuted.withOpacity(0.5) : def.color;
    final pct = (progress / def.target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isClaimed
              ? AppColors.border.withOpacity(0.5)
              : isComplete
                  ? def.color.withOpacity(0.8)
                  : def.color.withOpacity(0.2),
          width: isComplete && !isClaimed ? 1.5 : 1,
        ),
        boxShadow: isComplete && !isClaimed
            ? [BoxShadow(color: def.color.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4))]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Emoji + progress ring
            _ProgressRing(
              emoji: def.emoji,
              progress: pct,
              color: color,
              size: 52,
              isClaimed: isClaimed,
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.title,
                    style: TextStyle(
                      color: isClaimed ? AppColors.textMuted : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    def.description,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  // Progress text
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          isClaimed ? '✓ Completata' : '${_fmt(progress)} / ${_fmt(def.target)}',
                          style: TextStyle(
                            color: isClaimed ? AppColors.neonGreen : color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Reward
                      if (!isClaimed)
                        Row(
                          children: [
                            if (def.coinsReward > 0) ...[
                              Text('🪙 ${_fmtV(def.coinsReward)}',
                                  style: const TextStyle(color: AppColors.coins, fontSize: 10, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                            ],
                            if (def.gemsReward > 0)
                              Text('💎 ${def.gemsReward}',
                                  style: const TextStyle(color: AppColors.gems, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Action
            if (isClaimed)
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.neonGreen, size: 20),
              )
            else if (isComplete)
              GestureDetector(
                onTap: onClaim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [def.color, def.color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: def.color.withOpacity(0.4), blurRadius: 10)],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎁', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 2),
                      Text('CLAIM', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.border.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: (index * 50).clamp(0, 300)))
      .fadeIn(duration: 300.ms)
      .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  String _fmtV(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Progress ring ────────────────────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  final String emoji;
  final double progress;
  final Color color;
  final double size;
  final bool isClaimed;

  const _ProgressRing({
    required this.emoji,
    required this.progress,
    required this.color,
    required this.size,
    required this.isClaimed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring background
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 3,
              color: AppColors.border.withOpacity(0.5),
            ),
          ),
          // Ring fill
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: isClaimed ? 1.0 : progress,
              strokeWidth: 3,
              color: isClaimed ? AppColors.neonGreen : color,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Emoji center
          Text(emoji, style: TextStyle(fontSize: size * 0.45)),
        ],
      ),
    );
  }
}
