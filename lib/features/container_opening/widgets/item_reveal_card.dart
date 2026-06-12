import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/item_model.dart';
import '../../../core/models/rarity.dart';
import '../../../core/theme/app_colors.dart';

const _itemEmojis = {
  'Bullone Arrugginito': '🔩', 'Bottiglia Vuota': '🍶', 'Chiave Inglese': '🔧',
  'Orologio Rotto': '⌚', 'Moneta Antica': '🪙', 'Cacciavite': '🪛',
  'Martello': '🔨', 'Smartphone Vecchio': '📱', 'Orologio Vintage': '⌚',
  'Chitarra Acustica': '🎸', 'Vaso Ming': '🏺', 'Trapano Industriale': '🔧',
  'Saldatrice': '⚡', 'Generatore': '🔋', 'CNC Machine Part': '⚙️',
  'Prototipo Robot': '🤖', 'Core Nucleare Piccolo': '☢️', 'Elmetto Tattico': '🪖',
  'Giubbotto Antiproiettile': '🦺', 'Drone Militare': '🚁', 'Visore Notturno': '🔭',
  'Esoscheletro Prototipo': '🦾', 'Stealth Tech Module': '🛡️',
  'Orologio Rolex': '⌚', 'Borsa Hermès': '👜', 'Anello con Diamante': '💍',
  'Quadro Picasso': '🖼️', 'Corona Reale': '👑',
  'Meteorite Frammento': '☄️', 'Luna Rock Certificato': '🌙',
  'Satellite Disattivato': '🛰️', 'Cristallo Alieno': '💎',
  'Stardust Vial': '✨', 'Nucleo di Stella di Neutroni': '⭐',
  'Bit Quantistico': '🔮', 'Entangled Particle Pair': '🌀',
  'Quantum Processor': '💻', 'Materia Oscura Campione': '🕳️',
  'Singolarità Compressa': '🌌', 'Frammento Big Bang': '💥',
  'Ω Omega Particle': '⚛️',
};

class ItemRevealCard extends StatelessWidget {
  final ItemModel item;
  const ItemRevealCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(item.rarityKey);
    final hasMutation = item.mutation != Mutation.none;
    final mutColor = hasMutation ? AppColors.mutationColor(item.mutationKey) : Colors.transparent;
    final emoji = _itemEmojis[item.name] ?? '📦';

    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            AppColors.surface,
            color.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 40, spreadRadius: 4),
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 80, spreadRadius: 8),
          if (hasMutation)
            BoxShadow(color: mutColor.withOpacity(0.3), blurRadius: 60, spreadRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rarity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 1),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)],
            ),
            child: Text(
              item.rarity.displayName,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [Shadow(color: color, blurRadius: 8)],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Emoji icon with glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: RadialGradient(colors: [color.withOpacity(0.2), Colors.transparent]),
              border: Border.all(color: color.withOpacity(0.4), width: 1),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 68))),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.06, 1.06), duration: 1200.ms),

          const SizedBox(height: 16),

          // Mutation badge
          if (hasMutation) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [mutColor.withOpacity(0.3), mutColor.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mutColor, width: 1),
                boxShadow: [BoxShadow(color: mutColor.withOpacity(0.4), blurRadius: 10)],
              ),
              child: Text(
                '✦  ${item.mutation.displayName}  ×${item.mutation.valueMultiplier.toStringAsFixed(0)}',
                style: TextStyle(
                  color: mutColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: mutColor, blurRadius: 6)],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Name
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            item.category,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),

          const SizedBox(height: 20),

          // Divider
          Container(height: 1, color: color.withOpacity(0.2)),
          const SizedBox(height: 16),

          // Value
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                _fmt(item.finalValue),
                style: TextStyle(
                  color: AppColors.coins,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: AppColors.coins.withOpacity(0.6), blurRadius: 10)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(2)}T';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
