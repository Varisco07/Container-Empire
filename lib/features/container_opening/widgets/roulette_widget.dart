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

// Colore e label per ogni mutazione
const _mutationData = {
  'golden':        (label: '✨ GOLDEN',      color: Color(0xFFFFD700)),
  'diamond':       (label: '💎 DIAMOND',     color: Color(0xFF00F5FF)),
  'radioactive':   (label: '☢️ RADIO',       color: Color(0xFF39FF14)),
  'galaxy':        (label: '🌌 GALAXY',      color: Color(0xFFBF5FFF)),
  'voidMutation':  (label: '🕳️ VOID',        color: Color(0xFFFF0080)),
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

  static const _itemW   = 90.0;
  static const _itemH   = 110.0;
  static const _gap     = 8.0;
  static const _totalW  = _itemW + _gap;
  static const _count   = 60;
  static const _landIdx = 48;

  @override
  void initState() {
    super.initState();
    _buildEntries();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuint);
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
          mutationKey: r.mutationKey,
        );
      }
      final e = loot[rng.nextInt(loot.length)];
      return _RoulEntry(
        name: e.itemName,
        emoji: _itemEmojis[e.itemName] ?? '📦',
        rarityKey: e.rarity.name,
        mutationKey: 'none',
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
    // Schermo intero — niente AppBar durante la roulette
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: LayoutBuilder(builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          const scrollAmount = _landIdx * _totalW;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // ── Titolo ──────────────────────────────────────────
              const Text(
                'OPENING...',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neonCyan,
                  letterSpacing: 4,
                  shadows: [Shadow(color: AppColors.neonCyan, blurRadius: 20)],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 1.0, end: 0.4, duration: 600.ms),

              const SizedBox(height: 40),

              // ── Striscia ────────────────────────────────────────
              SizedBox(
                width: w,
                height: _itemH + 20,
                child: ClipRect(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Scrolling row
                      AnimatedBuilder(
                        animation: _anim,
                        builder: (_, __) {
                          final initialLeft = w / 2 - _itemW / 2;
                          final currentLeft = initialLeft - _anim.value * scrollAmount;
                          return Positioned(
                            left: currentLeft,
                            top: 10,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: _entries.map((e) {
                                final color = AppColors.rarityColor(e.rarityKey);
                                final mutData = _mutationData[e.mutationKey];
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: _itemW,
                                      height: _itemH,
                                      margin: const EdgeInsets.only(right: _gap),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            color.withOpacity(0.12),
                                            color.withOpacity(0.03),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: mutData != null
                                              ? mutData.color.withOpacity(0.6)
                                              : color.withOpacity(0.25),
                                          width: 1,
                                        ),
                                        boxShadow: mutData != null
                                            ? [BoxShadow(
                                                color: mutData.color.withOpacity(0.5),
                                                blurRadius: 14,
                                              )]
                                            : null,
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
                                                decoration: TextDecoration.none,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                            ),
                                          ),
                                          // Badge mutazione
                                          if (mutData != null) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: mutData.color.withOpacity(0.20),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: mutData.color, width: 1),
                                              ),
                                              child: Text(
                                                mutData.label,
                                                style: TextStyle(
                                                  color: mutData.color,
                                                  fontSize: 7,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),

                      // Fade sinistro
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

                      // Fade destro
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

                      // Selettore centrale
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

                      // Frecette top/bottom
                      const Positioned(
                        top: 0,
                        child: Text('▼',
                            style: TextStyle(color: AppColors.neonCyan, fontSize: 13)),
                      ),
                      const Positioned(
                        bottom: 0,
                        child: Text('▲',
                            style: TextStyle(color: AppColors.neonCyan, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              const Text(
                'Sei fortunato? 🍀',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),

              const Spacer(),
            ],
          );
        }),
      ),
    );
  }
}

class _RoulEntry {
  final String name;
  final String emoji;
  final String rarityKey;
  final String mutationKey;
  const _RoulEntry({
    required this.name,
    required this.emoji,
    required this.rarityKey,
    required this.mutationKey,
  });
}
