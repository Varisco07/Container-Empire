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
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.navBackground,
          border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: player.when(
          loading: () => const SizedBox.shrink(),
          error: (e, __) => const SizedBox.shrink(),
          data: (p) => Row(
            children: [
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.neonCyan.withOpacity(0.2),
                    AppColors.neonPurple.withOpacity(0.1),
                  ]),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.neonCyan.withOpacity(0.7), width: 1),
                  boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.2), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'LVL ${p.level}',
                      style: const TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(color: AppColors.neonCyan, blurRadius: 6)],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // XP bar
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(height: 6, color: AppColors.surface),
                          FractionallySizedBox(
                            widthFactor: p.xpProgress.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.neonCyan, AppColors.neonPurple],
                                ),
                                boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.6), blurRadius: 4)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.xp.toStringAsFixed(0)} / ${p.xpRequired.toStringAsFixed(0)} XP',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Coins
              _CurrencyBadge(icon: '🪙', value: _fmt(p.coins), color: AppColors.coins),
              const SizedBox(width: 8),
              // Gems
              _CurrencyBadge(icon: '💎', value: '${p.gems}', color: AppColors.gems),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _CurrencyBadge extends StatelessWidget {
  final String icon;
  final String value;
  final Color color;
  const _CurrencyBadge({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
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
              shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
