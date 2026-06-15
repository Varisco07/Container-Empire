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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1929), Color(0xFF0A1628)],
          ),
          border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 2)),
          ],
        ),
        child: player.when(
          loading: () => const SizedBox(height: 48),
          error: (_, __) => const SizedBox(height: 48),
          data: (p) => Row(
            children: [
              _AvatarSection(
                level: p.level,
                username: p.username,
                xpProgress: p.xpProgress.clamp(0.0, 1.0),
                xp: p.xp,
                xpReq: p.xpRequired,
              ),
              const Spacer(),
              _CurrencyPill(
                label: _fmt(p.coins),
                color: AppColors.coins,
                emoji: '🪙',
                glow: true,
              ),
              const SizedBox(width: 8),
              _CurrencyPill(
                label: '${p.gems}',
                color: AppColors.gems,
                emoji: '💎',
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T';
    if (v >= 1e9)  return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6)  return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3)  return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final int level;
  final String username;
  final double xpProgress, xp, xpReq;

  const _AvatarSection({
    required this.level, required this.username,
    required this.xpProgress, required this.xp, required this.xpReq,
  });

  @override
  Widget build(BuildContext context) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'P';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circle with XP ring
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // XP ring
              SizedBox(
                width: 48, height: 48,
                child: CircularProgressIndicator(
                  value: xpProgress,
                  strokeWidth: 2.5,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.neonCyan),
                ),
              ),
              // Avatar
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A3A5C), Color(0xFF0F2035)],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.neonCyan.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none),
                  ),
                ),
              ),
              // Level badge
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.neonCyan, Color(0xFF3A6BD4)]),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.5), blurRadius: 4)],
                  ),
                  child: Text(
                    '$level',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              username,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                decoration: TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${_fmtXp(xp)} / ${_fmtXp(xpReq)} XP',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9,
                  decoration: TextDecoration.none),
            ),
          ],
        ),
      ],
    );
  }

  static String _fmtXp(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Currency pill ────────────────────────────────────────────────────────────

class _CurrencyPill extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final bool glow;
  const _CurrencyPill({
    required this.label,
    required this.emoji,
    required this.color,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.35), width: 1),
      boxShadow: glow
          ? [BoxShadow(color: color.withOpacity(0.20), blurRadius: 10, spreadRadius: 1)]
          : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14, decoration: TextDecoration.none)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    ),
  );
}
