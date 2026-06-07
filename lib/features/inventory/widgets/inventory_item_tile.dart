import 'package:flutter/material.dart';
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
  'Ferrari Miniatura d\'Oro': '🏎️', 'Quadro Picasso': '🖼️', 'Corona Reale': '👑',
  'Meteorite Frammento': '☄️', 'Luna Rock Certificato': '🌙',
  'Satellite Disattivato': '🛰️', 'Cristallo Alieno': '💎',
  'Stardust Vial': '✨', 'Nucleo di Stella di Neutroni': '⭐',
  'Bit Quantistico': '🔮', 'Entangled Particle Pair': '🌀',
  'Quantum Processor': '💻', 'Materia Oscura Campione': '🕳️',
  'Singolarità Compressa': '🌌', 'Frammento Big Bang': '💥',
  'Ω Omega Particle': '⚛️',
};

class InventoryItemTile extends StatelessWidget {
  final ItemModel item;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback onLock;
  final VoidCallback onSell;

  const InventoryItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onLock,
    required this.onSell,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(item.rarityKey);
    final hasMutation = item.mutation != Mutation.none;
    final mutColor = hasMutation ? AppColors.mutationColor(item.mutationKey) : Colors.transparent;
    final emoji = _itemEmojis[item.name] ?? '📦';

    return GestureDetector(
      onTap: onTap ?? () => _showDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isSelected ? color.withOpacity(0.3) : color.withOpacity(0.1),
              isSelected ? color.withOpacity(0.1) : AppColors.surface,
            ],
          ),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (hasMutation)
              BoxShadow(color: mutColor.withOpacity(0.35), blurRadius: 14, spreadRadius: 1),
            if (item.rarity.index >= 4)
              BoxShadow(color: color.withOpacity(0.2), blurRadius: 10),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji icon
                  Expanded(
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 34)),
                    ),
                  ),

                  // Mutation tag
                  if (hasMutation)
                    Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: mutColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: mutColor.withOpacity(0.6), width: 1),
                      ),
                      child: Text(
                        '✦ ${item.mutation.displayName}',
                        style: TextStyle(color: mutColor, fontSize: 7, fontWeight: FontWeight.w800),
                      ),
                    ),

                  // Name
                  Text(
                    item.name,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Value
                  Row(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 9)),
                      const SizedBox(width: 2),
                      Text(
                        _fmt(item.finalValue),
                        style: const TextStyle(
                          color: AppColors.coins,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top badges
            Positioned(
              top: 6,
              right: 6,
              child: Column(
                children: [
                  if (item.isLocked)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text('🔒', style: TextStyle(fontSize: 10)),
                    ),
                  if (isSelected)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 12, color: Colors.black),
                    ),
                ],
              ),
            ),

            // Rarity corner dot
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.8), blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final color = AppColors.rarityColor(item.rarityKey);
    final emoji = _itemEmojis[item.name] ?? '📦';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text(item.name, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text(item.rarity.displayName,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            if (item.mutation != Mutation.none) ...[
              const SizedBox(height: 6),
              Text('✦ ${item.mutation.displayName}',
                style: TextStyle(color: AppColors.mutationColor(item.mutationKey),
                  fontSize: 13, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(_fmt(item.finalValue),
                  style: const TextStyle(color: AppColors.coins, fontSize: 28, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { onLock(); Navigator.pop(context); },
                    icon: Text(item.isLocked ? '🔓' : '🔒', style: const TextStyle(fontSize: 16)),
                    label: Text(item.isLocked ? 'Sblocca' : 'Blocca'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neonCyan,
                      side: const BorderSide(color: AppColors.neonCyan),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: item.isLocked ? null : () { onSell(); Navigator.pop(context); },
                    icon: const Text('💰', style: TextStyle(fontSize: 16)),
                    label: const Text('Vendi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coins,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T€';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B€';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M€';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K€';
    return '${v.toStringAsFixed(0)}€';
  }
}
