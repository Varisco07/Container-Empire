import 'package:flutter/material.dart';

class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────────
  static const Color background    = Color(0xFF0A1628);
  static const Color surface       = Color(0xFF0F2035);
  static const Color surfaceLight  = Color(0xFF162840);
  static const Color navBackground = Color(0xFF08121E);

  // ── Brand / accents (replacing neon names – same API, cleaner values) ────────
  static const Color neonCyan      = Color(0xFF4B7BEC);  // primary blue
  static const Color neonPurple    = Color(0xFF7C5CBF);  // muted purple
  static const Color neonGreen     = Color(0xFF27AE60);  // natural green
  static const Color neonOrange    = Color(0xFFE67E22);  // warm orange
  static const Color neonGold      = Color(0xFFF39C12);  // amber gold
  static const Color neonPink      = Color(0xFFD63384);  // rose

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFE2EBF6);
  static const Color textSecondary = Color(0xFF8BA4BE);
  static const Color textMuted     = Color(0xFF4A6278);

  // ── Borders ──────────────────────────────────────────────────────────────────
  static const Color border        = Color(0xFF1A3048);
  static const Color borderGlow    = Color(0xFF2A4A6A);

  // ── Rarity ───────────────────────────────────────────────────────────────────
  static const Color common        = Color(0xFF8FA3B8);
  static const Color uncommon      = Color(0xFF2ECC71);
  static const Color rare          = Color(0xFF3498DB);
  static const Color epic          = Color(0xFF9B59B6);
  static const Color legendary     = Color(0xFFF39C12);
  static const Color mythic        = Color(0xFFE67E22);
  static const Color divine        = Color(0xFFD63384);
  static const Color secret        = Color(0xFF1ABC9C);
  static const Color cosmic        = Color(0xFFFFFFFF);

  // ── Mutations ────────────────────────────────────────────────────────────────
  static const Color golden        = Color(0xFFF39C12);
  static const Color diamond       = Color(0xFF5DADE2);
  static const Color radioactive   = Color(0xFF27AE60);
  static const Color galaxy        = Color(0xFF7C5CBF);
  static const Color voidColor     = Color(0xFF1A0830);

  // ── Status ───────────────────────────────────────────────────────────────────
  static const Color error         = Color(0xFFE74C3C);
  static const Color success       = Color(0xFF27AE60);
  static const Color warning       = Color(0xFFF39C12);

  // ── Currency ─────────────────────────────────────────────────────────────────
  static const Color coins         = Color(0xFFF5A623);
  static const Color gems          = Color(0xFF7C5CBF);

  static Color rarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':    return common;
      case 'uncommon':  return uncommon;
      case 'rare':      return rare;
      case 'epic':      return epic;
      case 'legendary': return legendary;
      case 'mythic':    return mythic;
      case 'divine':    return divine;
      case 'secret':    return secret;
      case 'cosmic':    return cosmic;
      default:          return common;
    }
  }

  static Color mutationColor(String? mutation) {
    switch (mutation?.toLowerCase()) {
      case 'golden':      return golden;
      case 'diamond':     return diamond;
      case 'radioactive': return radioactive;
      case 'galaxy':      return galaxy;
      case 'void':        return voidColor;
      default:            return Colors.transparent;
    }
  }
}
