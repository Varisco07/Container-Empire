import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SnackType { success, error, info, coins }

void showSnack(
  BuildContext context,
  String message, {
  SnackType type = SnackType.info,
}) {
  final (Color bg, Color border, String icon) = switch (type) {
    SnackType.success => (const Color(0xFF1A3A2A), AppColors.neonGreen, '✅'),
    SnackType.error   => (const Color(0xFF3A1A1A), AppColors.error,     '❌'),
    SnackType.coins   => (const Color(0xFF2E2210), AppColors.coins,     '🪙'),
    SnackType.info    => (const Color(0xFF0F2035), AppColors.neonCyan,  'ℹ️'),
  };

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(color: border.withOpacity(0.2), blurRadius: 16),
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: border,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
