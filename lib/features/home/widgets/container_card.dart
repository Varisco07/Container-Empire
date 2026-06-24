import 'package:flutter/material.dart';
import '../../../core/models/container_model.dart';
import '../../../core/theme/app_colors.dart';

class ContainerCard extends StatelessWidget {
  final ContainerModel container;
  final bool isSelected;
  final VoidCallback onTap;

  const ContainerCard({
    super.key,
    required this.container,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(container.colorHex);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 16, spreadRadius: 1)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Container icon placeholder (replace with actual asset)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              container.name.split(' ').first,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!container.isFree) ...[
              const SizedBox(height: 2),
              Text(
                _fmtPrice(container.cost),
                style: TextStyle(
                  color: isSelected ? color : AppColors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else
              const SizedBox(height: 2),
              const Text(
                'FREE',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtPrice(double v) {
    if (v >= 1e6) return '🪙 ${(v / 1e6).toStringAsFixed(0)}M';
    if (v >= 1e3) return '🪙 ${(v / 1e3).toStringAsFixed(0)}K';
    return '🪙 ${v.toStringAsFixed(0)}';
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
