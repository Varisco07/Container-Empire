import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF050A14);
  static const Color surface = Color(0xFF0D1526);
  static const Color surfaceLight = Color(0xFF162035);
  static const Color navBackground = Color(0xFF080F1F);

  // Neon accents
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color neonGold = Color(0xFFFFD700);
  static const Color neonPink = Color(0xFFFF0080);

  // Text
  static const Color textPrimary = Color(0xFFE8F4FD);
  static const Color textSecondary = Color(0xFF8BA4C0);
  static const Color textMuted = Color(0xFF4A6080);

  // Borders
  static const Color border = Color(0xFF1E3050);
  static const Color borderGlow = Color(0xFF00F5FF);

  // Rarity colors
  static const Color common = Color(0xFF9CA3AF);
  static const Color uncommon = Color(0xFF34D399);
  static const Color rare = Color(0xFF3B82F6);
  static const Color epic = Color(0xFFA855F7);
  static const Color legendary = Color(0xFFFFD700);
  static const Color mythic = Color(0xFFFF6B00);
  static const Color divine = Color(0xFFFF0080);
  static const Color secret = Color(0xFF00F5FF);
  static const Color cosmic = Color(0xFFFFFFFF); // prismatic white — glows with rainbow

  // Mutation colors
  static const Color golden = Color(0xFFFFD700);
  static const Color diamond = Color(0xFF7DF9FF);
  static const Color radioactive = Color(0xFF39FF14);
  static const Color galaxy = Color(0xFF8B5CF6);
  static const Color voidColor = Color(0xFF1A0030);

  // Status
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  // Currency
  static const Color coins = Color(0xFFFFD700);
  static const Color gems = Color(0xFF8B5CF6);

  static Color rarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common': return common;
      case 'uncommon': return uncommon;
      case 'rare': return rare;
      case 'epic': return epic;
      case 'legendary': return legendary;
      case 'mythic': return mythic;
      case 'divine': return divine;
      case 'secret': return secret;
      case 'cosmic': return cosmic;
      default: return common;
    }
  }

  static Color mutationColor(String? mutation) {
    switch (mutation?.toLowerCase()) {
      case 'golden': return golden;
      case 'diamond': return diamond;
      case 'radioactive': return radioactive;
      case 'galaxy': return galaxy;
      case 'void': return voidColor;
      default: return Colors.transparent;
    }
  }
}
