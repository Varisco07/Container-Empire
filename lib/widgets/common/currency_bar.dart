import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/profile/providers/player_provider.dart';

class CurrencyBar extends ConsumerWidget {
  const CurrencyBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);

    return SafeArea(
      bottom: false,
      child: Container(
        height: 58,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
        decoration: BoxDecoration(
          color: AppColors.navBackground,
          border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: player.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (p) => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Level + XP block
              _LevelBlock(level: p.level, xpProgress: p.xpProgress.clamp(0.0, 1.0), xp: p.xp, xpReq: p.xpRequired),
              const SizedBox(width: 10),
              const Spacer(),
              // Prestige badge
              if (p.prestigeLevel > 0) ...[
                _PrestigeBadge(p.prestigeLevel),
                const SizedBox(width: 8),
              ],
              // Currencies
              _CurrencyPill(
                icon: '🪙',
                value: _fmt(p.coins),
                color: AppColors.coins,
              ),
              const SizedBox(width: 6),
              _CurrencyPill(
                icon: '💎',
                value: '${p.gems}',
                color: AppColors.gems,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _LevelBlock extends StatelessWidget {
  final int level;
  final double xpProgress;
  final double xp;
  final double xpReq;
  const _LevelBlock({required this.level, required this.xpProgress, required this.xp, required this.xpReq});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level badge
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.neonCyan, AppColors.neonPurple],
            ),
            boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.35), blurRadius: 10)],
          ),
          child: Center(
            child: Text(
              '$level',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // XP bar + label
        SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIVELLO',
                style: TextStyle(color: AppColors.textMuted, fontSize: 7, letterSpacing: 1.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(height: 5, color: AppColors.surface),
                    FractionallySizedBox(
                      widthFactor: xpProgress,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple]),
                          boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.7), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${xp.toStringAsFixed(0)} / ${xpReq.toStringAsFixed(0)} XP',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final String icon;
  final String value;
  final Color color;
  const _CurrencyPill({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestigeBadge extends StatelessWidget {
  final int level;
  const _PrestigeBadge(this.level);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.neonPurple, AppColors.neonPink]),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.4), blurRadius: 8)],
      ),
      child: Text(
        '⚜️ P$level',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}
