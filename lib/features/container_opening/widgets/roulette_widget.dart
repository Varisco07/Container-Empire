import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/container_model.dart';
import '../../../core/models/item_model.dart';
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

class RouletteWidget extends StatefulWidget {
  final ContainerModel container;
  final ItemModel? revealedItem;
  const RouletteWidget({super.key, required this.container, this.revealedItem});

  @override
  State<RouletteWidget> createState() => _RouletteWidgetState();
}

class _RouletteWidgetState extends State<RouletteWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  late List<_RoulEntry> _entries;

  static const _itemW    = 90.0;
  static const _itemH    = 104.0;
  static const _gap      = 8.0;
  static const _totalW   = _itemW + _gap;
  static const _count    = 32;       // total items in strip
  static const _landIdx  = 16;       // which index stops at center

  @override
  void initState() {
    super.initState();
    _buildEntries();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart);
    _ctrl.forward();
  }

  void _buildEntries() {
    final rng  = Random();
    final loot = widget.container.lootTable;
    _entries = List.generate(_count, (i) {
      if (i == _landIdx && widget.revealedItem != null) {
        final r = widget.revealedItem!;
        return _RoulEntry(
          name: r.name,
          emoji: _itemEmojis[r.name] ?? '📦',
          rarityKey: r.rarityKey,
        );
      }
      final e = loot[rng.nextInt(loot.length)];
      return _RoulEntry(
        name: e.itemName,
        emoji: _itemEmojis[e.itemName] ?? '📦',
        rarityKey: e.rarity.name,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      // How much the strip must scroll so _landIdx is at center
      // Strip starts with item-0 at center: left = w/2 - _itemW/2
      // Final: item-_landIdx at center → shift left by _landIdx * _totalW
      final scrollAmount = _landIdx * _totalW;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          const Text(
            'OPENING...',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.neonCyan,
              letterSpacing: 4,
              shadows: [Shadow(color: AppColors.neonCyan, blurRadius: 16)],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(begin: 1.0, end: 0.4, duration: 600.ms),

          const SizedBox(height: 28),

          // Strip container
          SizedBox(
            width: w,
            height: _itemH + 16,
            child: ClipRect(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Scrolling row ──────────────────────────────
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) {
                      // Initial left edge so item-0 is at center
                      final initialLeft = w / 2 - _itemW / 2;
                      // Shift left as animation progresses
                      final currentLeft = initialLeft - _anim.value * scrollAmount;

                      return Positioned(
                        left: currentLeft,
                        top: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _entries.map((e) {
                            final color = AppColors.rarityColor(e.rarityKey);
                            return Container(
                              width: _itemW,
                              height: _itemH,
                              margin: const EdgeInsets.only(right: _gap),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    color.withOpacity(0.22),
                                    color.withOpacity(0.05),
                                  ],
                                ),
                                border: Border.all(color: color.withOpacity(0.55), width: 1),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(e.emoji, style: const TextStyle(fontSize: 30)),
                                  const SizedBox(height: 5),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      e.name.length > 13
                                          ? '${e.name.substring(0, 12)}…'
                                          : e.name,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                  // ── Left fade ──────────────────────────────────
                  Positioned(
                    left: 0, top: 0, bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: w * 0.22,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppColors.background,
                            AppColors.background.withOpacity(0),
                          ]),
                        ),
                      ),
                    ),
                  ),

                  // ── Right fade ─────────────────────────────────
                  Positioned(
                    right: 0, top: 0, bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: w * 0.22,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppColors.background.withOpacity(0),
                            AppColors.background,
                          ]),
                        ),
                      ),
                    ),
                  ),

                  // ── Center selector ────────────────────────────
                  IgnorePointer(
                    child: Container(
                      width: _itemW + 8,
                      height: _itemH + 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: AppColors.neonCyan, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonCyan.withOpacity(0.45),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Top/bottom arrows ──────────────────────────
                  const Positioned(
                    top: 0,
                    child: Text('▼', style: TextStyle(color: AppColors.neonCyan, fontSize: 13)),
                  ),
                  const Positioned(
                    bottom: 0,
                    child: Text('▲', style: TextStyle(color: AppColors.neonCyan, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),
          const Text(
            'Sei fortunato? 🍀',
            style: TextStyle(color: AppColors.textMuted, fontSize: 15),
          ),
        ],
      );
    });
  }
}

class _RoulEntry {
  final String name;
  final String emoji;
  final String rarityKey;
  const _RoulEntry({required this.name, required this.emoji, required this.rarityKey});
}
