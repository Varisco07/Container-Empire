import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/container_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/neon_text.dart';

class SelectedContainerDisplay extends StatelessWidget {
  final ContainerModel container;
  const SelectedContainerDisplay({super.key, required this.container});

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(container.colorHex);
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background glow rings
        ...List.generate(3, (i) => Container(
          width: 200.0 + i * 60,
          height: 200.0 + i * 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.08 - i * 0.02),
              width: 1,
            ),
          ),
        )).animate(onPlay: (c) => c.repeat()).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.05, 1.05),
          duration: 2000.ms,
          curve: Curves.easeInOut,
        ),

        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main container icon
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withOpacity(0.6), width: 2),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.4), blurRadius: 40, spreadRadius: 4),
                  BoxShadow(color: color.withOpacity(0.2), blurRadius: 80, spreadRadius: 8),
                ],
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: color,
                size: 80,
              ),
            ).animate(onPlay: (c) => c.repeat()).then().shimmer(
              duration: 3000.ms,
              color: color.withOpacity(0.3),
            ),

            const SizedBox(height: 20),

            NeonText(
              container.name,
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              blurRadius: 12,
            ),
            const SizedBox(height: 6),
            Text(
              container.description,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Drop rate pills
            Wrap(
              spacing: 8,
              children: [
                _RarityPill('COMUNE 70%', AppColors.common),
                _RarityPill('RARO 7%', AppColors.rare),
                _RarityPill('LEGGEND. 0.8%', AppColors.legendary),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class _RarityPill extends StatelessWidget {
  final String label;
  final Color color;
  const _RarityPill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
