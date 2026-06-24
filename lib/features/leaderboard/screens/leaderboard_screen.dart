import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/neon_text.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum LeaderboardType { coins, level, containers, rares }

extension _LbTypeX on LeaderboardType {
  String get label {
    switch (this) {
      case LeaderboardType.coins:      return '💰 Guadagni';
      case LeaderboardType.level:      return '⭐ Livello';
      case LeaderboardType.containers: return '📦 Container';
      case LeaderboardType.rares:      return '🔮 Rari';
    }
  }

  String get field {
    switch (this) {
      case LeaderboardType.coins:      return 'totalEarned';
      case LeaderboardType.level:      return 'level';
      case LeaderboardType.containers: return 'totalContainersOpened';
      case LeaderboardType.rares:      return 'totalRaresFound';
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final _lbProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, field) => sl<DatabaseService>().fetchLeaderboard(orderBy: field, limit: 100),
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardType _type = LeaderboardType.coins;

  @override
  Widget build(BuildContext context) {
    final field    = _type.field;
    final lbAsync  = ref.watch(_lbProvider(field));
    final myPlayer = sl<PlayerService>().localPlayer;
    final myUid    = myPlayer?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            title: const Text('CLASSIFICA GLOBALE',
                style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900)),
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: _TypeSelector(selected: _type, onChanged: (t) => setState(() => _type = t)),
            ),
          ),
        ],
        body: lbAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.neonGold)),
          error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(_lbProvider(field))),
          data: (entries) {
            if (entries.isEmpty) {
              return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('🏆', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('Nessun dato ancora', style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Apri container per apparire in classifica!',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ]));
            }

            int myRank = -1;
            for (int i = 0; i < entries.length; i++) {
              if (entries[i]['uid'] == myUid) { myRank = i + 1; break; }
            }

            final hasPodium = entries.length >= 3;
            return RefreshIndicator(
              color: AppColors.neonGold,
              onRefresh: () async => ref.invalidate(_lbProvider(field)),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: entries.length + (myRank > 10 ? 1 : 0) + (hasPodium ? 1 : 0),
                itemBuilder: (_, i) {
                  // Podio top 3
                  if (hasPodium && i == 0) {
                    return _Podium(entries: entries.take(3).toList(), type: _type, myUid: myUid ?? '')
                        .animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
                  }
                  final dataIdx = hasPodium ? i - 1 : i;

                  // La tua posizione in fondo
                  if (dataIdx == entries.length) {
                    final me = entries.firstWhere(
                        (e) => e['uid'] == myUid, orElse: () => {});
                    if (me.isEmpty) return const SizedBox.shrink();
                    return Column(children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('La tua posizione',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ]),
                      ),
                      _LeaderRow(rank: myRank, data: me, type: _type, isMe: true),
                    ]);
                  }

                  final entry = entries[dataIdx];
                  final isMe  = entry['uid'] == myUid;
                  return _LeaderRow(rank: dataIdx + 1, data: entry, type: _type, isMe: isMe)
                      .animate(delay: Duration(milliseconds: (dataIdx * 30).clamp(0, 300)))
                      .fadeIn(duration: 250.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Podium top 3 ────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final LeaderboardType type;
  final String myUid;
  const _Podium({required this.entries, required this.type, required this.myUid});

  @override
  Widget build(BuildContext context) {
    // Order: 2nd, 1st, 3rd (visual podium layout)
    final first  = entries[0];
    final second = entries.length > 1 ? entries[1] : <String, dynamic>{};
    final third  = entries.length > 2 ? entries[2] : <String, dynamic>{};

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1E35), Color(0xFF0A1628)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonGold.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second.isNotEmpty) _PodiumSlot(
            rank: 2, data: second, type: type,
            isMe: second['uid'] == myUid,
            height: 80, medalEmoji: '🥈',
            color: const Color(0xFFC0C0C0),
          ),
          _PodiumSlot(
            rank: 1, data: first, type: type,
            isMe: first['uid'] == myUid,
            height: 110, medalEmoji: '🥇',
            color: AppColors.neonGold,
          ),
          if (third.isNotEmpty) _PodiumSlot(
            rank: 3, data: third, type: type,
            isMe: third['uid'] == myUid,
            height: 60, medalEmoji: '🥉',
            color: const Color(0xFFCD7F32),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;
  final LeaderboardType type;
  final bool isMe;
  final double height;
  final String medalEmoji;
  final Color color;
  const _PodiumSlot({
    required this.rank, required this.data, required this.type,
    required this.isMe, required this.height, required this.medalEmoji, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final username = data['username'] as String? ?? '???';
    final rawValue = (data[type.field] as num?)?.toDouble() ?? 0;
    final initial  = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medal
        Text(medalEmoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        // Avatar
        Container(
          width: rank == 1 ? 56 : 46,
          height: rank == 1 ? 56 : 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]),
            border: Border.all(color: color, width: rank == 1 ? 2.5 : 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: rank == 1 ? 20 : 12)],
          ),
          child: Center(child: Text(
            initial,
            style: TextStyle(color: color, fontSize: rank == 1 ? 24 : 18, fontWeight: FontWeight.w900),
          )),
        ),
        const SizedBox(height: 6),
        // Username
        SizedBox(
          width: 80,
          child: Text(
            username + (isMe ? '\n(tu)' : ''),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isMe ? AppColors.neonCyan : AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        // Value
        Text(
          _fmt(rawValue),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        // Podium bar
        Container(
          width: rank == 1 ? 70 : 58,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.4), color.withOpacity(0.1)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(
              left:  BorderSide(color: color.withOpacity(0.4)),
              right: BorderSide(color: color.withOpacity(0.4)),
              top:   BorderSide(color: color.withOpacity(0.6), width: 2),
            ),
            boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)],
          ),
          child: Center(child: Text(
            '#$rank',
            style: TextStyle(
              color: color, fontSize: rank == 1 ? 20 : 16, fontWeight: FontWeight.w900,
              shadows: [Shadow(color: color, blurRadius: 8)],
            ),
          )),
        ),
      ],
    );
  }

  static String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Type selector ────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final LeaderboardType selected;
  final ValueChanged<LeaderboardType> onChanged;
  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        itemCount: LeaderboardType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t        = LeaderboardType.values[i];
          final isActive = t == selected;
          return GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? AppColors.neonGold.withOpacity(0.15) : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.neonGold : AppColors.border,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Center(child: Text(t.label, style: TextStyle(
                color: isActive ? AppColors.neonGold : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ))),
            ),
          );
        },
      ),
    );
  }
}

// ─── Leader row ───────────────────────────────────────────────────────────────

class _LeaderRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;
  final LeaderboardType type;
  final bool isMe;

  const _LeaderRow({
    required this.rank,
    required this.data,
    required this.type,
    required this.isMe,
  });

  Color get _rankColor {
    if (rank == 1) return AppColors.neonGold;
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final username = data['username'] as String? ?? '???';
    final rawValue = (data[type.field] as num?)?.toDouble() ?? 0;
    final isVip    = data['isVip'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.neonCyan.withOpacity(0.07)
            : rank <= 3
                ? _rankColor.withOpacity(0.06)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AppColors.neonCyan.withOpacity(0.5)
              : rank <= 3
                  ? _rankColor.withOpacity(0.35)
                  : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: (isMe || rank <= 3)
            ? [BoxShadow(
                color: (isMe ? AppColors.neonCyan : _rankColor).withOpacity(0.12),
                blurRadius: 12)]
            : null,
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 38,
            child: rank <= 3
                ? NeonText('#$rank', color: _rankColor, fontSize: 17, blurRadius: 8)
                : Text('#$rank', style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),

          // Medal icon
          if (rank <= 3) ...[
            Icon(_rankIcon, color: _rankColor, size: 18),
            const SizedBox(width: 8),
          ] else
            const SizedBox(width: 4),

          // Avatar circle
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (isMe ? AppColors.neonCyan : _rankColor).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: (isMe ? AppColors.neonCyan : _rankColor).withOpacity(0.5)),
            ),
            child: Center(child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: TextStyle(
                color: isMe ? AppColors.neonCyan : _rankColor,
                fontWeight: FontWeight.w900, fontSize: 15),
            )),
          ),
          const SizedBox(width: 10),

          // Name + VIP + level
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(child: Text(
                  username + (isMe ? '  (tu)' : ''),
                  style: TextStyle(
                    color: isMe ? AppColors.neonCyan : AppColors.textPrimary,
                    fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                )),
                if (isVip) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.neonGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.neonGold.withOpacity(0.6)),
                    ),
                    child: const Text('VIP', style: TextStyle(
                      color: AppColors.neonGold, fontSize: 8, fontWeight: FontWeight.w900)),
                  ),
                ],
              ]),
              Text('Lv. ${data['level'] ?? 1}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          )),

          // Value
          Text(
            _formatValue(rawValue, type),
            style: TextStyle(
              color: isMe ? AppColors.neonCyan : _rankColor,
              fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ],
      ),
    );
  }

  IconData get _rankIcon {
    if (rank == 1) return Icons.emoji_events_rounded;
    if (rank == 2) return Icons.military_tech_rounded;
    return Icons.workspace_premium_rounded;
  }

  static String _formatValue(double v, LeaderboardType type) {
    if (type != LeaderboardType.coins) {
      if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
      if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
      return v.toStringAsFixed(0);
    }
    if (v >= 1e12) return '🪙 ${(v / 1e12).toStringAsFixed(1)}T';
    if (v >= 1e9)  return '🪙 ${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6)  return '🪙 ${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3)  return '🪙 ${(v / 1e3).toStringAsFixed(1)}K';
    return '🪙 ${v.toStringAsFixed(0)}';
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('❌', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      const Text('Errore di connessione', style: TextStyle(
        color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('Controlla la connessione internet',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGold, foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('RIPROVA', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    ]),
  );
}
