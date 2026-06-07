import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class LuckyMeter extends StatelessWidget {
  final int pityCounter;
  final int pityMax;

  const LuckyMeter({super.key, required this.pityCounter, this.pityMax = 50});

  @override
  Widget build(BuildContext context) {
    final progress = (pityCounter / pityMax).clamp(0.0, 1.0);
    final isReady = pityCounter >= pityMax;

    final Color barStart = isReady ? AppColors.neonGold : AppColors.rare;
    final Color barEnd = isReady ? AppColors.neonOrange : AppColors.mythic;
    final Color borderColor = isReady ? AppColors.neonGold : AppColors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isReady ? 1.5 : 1),
        boxShadow: isReady
            ? [BoxShadow(color: AppColors.neonGold.withOpacity(0.25), blurRadius: 16)]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(isReady ? '⚡' : '🍀', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'LUCKY METER',
                  style: TextStyle(
                    color: isReady ? AppColors.neonGold : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Text(
                isReady ? '🔥 GARANTITO!' : '$pityCounter / $pityMax',
                style: TextStyle(
                  color: isReady ? AppColors.neonGold : Color.lerp(barStart, barEnd, progress)!,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (_, constraints) => Stack(
              children: [
                Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  height: 9,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(colors: [barStart, barEnd]),
                    boxShadow: [
                      BoxShadow(
                        color: barEnd.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isReady) ...[
            const SizedBox(height: 6),
            Text(
              'Il prossimo drop è garantito RARO+!',
              style: TextStyle(
                color: AppColors.neonGold.withOpacity(0.85),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 700.ms),
          ],
        ],
      ),
    );
  }
}
