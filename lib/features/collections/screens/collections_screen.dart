import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/services/meta_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';

// ─── Static collection definitions ───────────────────────────────────────────

class CollectionDef {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final Color color;
  final List<String> itemNames;
  final String rewardBadge;

  const CollectionDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.color,
    required this.itemNames,
    required this.rewardBadge,
  });
}

const _collections = [
  CollectionDef(
    id: 'rust_junk',
    name: 'Rottami & Scarti',
    emoji: '🔩',
    description: 'I residui della civiltà industriale. Economici ma abbondanti.',
    color: Color(0xFF9E9E9E),
    rewardBadge: 'Raccattabrighe',
    itemNames: [
      'Bullone Arrugginito', 'Bottiglia Vuota', 'Chiave Inglese',
      'Orologio Rotto', 'Moneta Antica', 'Cacciavite', 'Martello',
    ],
  ),
  CollectionDef(
    id: 'tech_lab',
    name: 'Laboratorio Tech',
    emoji: '⚙️',
    description: 'Tecnologia non comune, strumenti e macchinari da officina.',
    color: Color(0xFF4CAF50),
    rewardBadge: 'Tecnico',
    itemNames: [
      'Smartphone Vecchio', 'Orologio Vintage', 'Chitarra Acustica',
      'Trapano Industriale', 'Saldatrice', 'Generatore', 'CNC Machine Part',
      'Vaso Ming',
    ],
  ),
  CollectionDef(
    id: 'prototype_zone',
    name: 'Zona Prototipo',
    emoji: '🤖',
    description: 'Tecnologia avanzata frutto di ricerca e ingegneria di punta.',
    color: Color(0xFF2196F3),
    rewardBadge: 'Prototipista',
    itemNames: [
      'Prototipo Robot', 'Core Nucleare Piccolo',
    ],
  ),
  CollectionDef(
    id: 'military_ops',
    name: 'Operazioni Militari',
    emoji: '🪖',
    description: 'Equipaggiamento militare di grado epico. Sicurezza ed efficacia.',
    color: Color(0xFF9C27B0),
    rewardBadge: 'Soldato d\'Elite',
    itemNames: [
      'Elmetto Tattico', 'Giubbotto Antiproiettile', 'Drone Militare',
      'Visore Notturno', 'Esoscheletro Prototipo', 'Stealth Tech Module',
    ],
  ),
  CollectionDef(
    id: 'luxury_vault',
    name: 'Caveau del Lusso',
    emoji: '💍',
    description: 'Il meglio che il denaro possa comprare. Eleganza pura.',
    color: Color(0xFFFFB300),
    rewardBadge: 'Magnate',
    itemNames: [
      'Orologio Rolex', 'Borsa Hermès', 'Anello con Diamante',
      'Ferrari Miniatura d\'Oro', 'Quadro Picasso', 'Corona Reale',
    ],
  ),
  CollectionDef(
    id: 'space_archive',
    name: 'Archivio Spaziale',
    emoji: '🛰️',
    description: 'Manufatti cosmici dall\'universo più profondo.',
    color: Color(0xFFE91E63),
    rewardBadge: 'Cosmonauta',
    itemNames: [
      'Meteorite Frammento', 'Luna Rock Certificato', 'Satellite Disattivato',
      'Cristallo Alieno', 'Stardust Vial', 'Nucleo di Stella di Neutroni',
    ],
  ),
  CollectionDef(
    id: 'quantum_set',
    name: 'Set Quantistico',
    emoji: '⚛️',
    description: 'La frontiera della fisica quantistica. Praticamente inestimabile.',
    color: Color(0xFF00BCD4),
    rewardBadge: '★ Quantum Master ★',
    itemNames: [
      'Bit Quantistico', 'Entangled Particle Pair', 'Quantum Processor',
      'Materia Oscura Campione', 'Singolarità Compressa',
      'Frammento Big Bang', 'Ω Omega Particle',
    ],
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = MetaService();
    final obtained = meta.obtainedItems;
    // Also check inventory for items currently owned
    final inv = sl<InventoryService>();
    final ownedNames = inv.allItems.map((i) => i.name).toSet();
    final allKnown = {...obtained, ...ownedNames};

    final totalCollections = _collections.length;
    final completedCollections = _collections
        .where((c) => c.itemNames.every((n) => allKnown.contains(n)))
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1020),
        title: const Text('COLLEZIONI', style: TextStyle(
          color: AppColors.neonCyan, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18,
        )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$completedCollections / $totalCollections complete',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(
                      '${allKnown.length} item scoperti',
                      style: const TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completedCollections / totalCollections,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.neonCyan),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _collections.length,
        itemBuilder: (ctx, i) {
          final c = _collections[i];
          final found = c.itemNames.where((n) => allKnown.contains(n)).length;
          final isComplete = found == c.itemNames.length;
          return _CollectionCard(
            collection: c,
            found: found,
            isComplete: isComplete,
            allKnown: allKnown,
            index: i,
          );
        },
      ),
    );
  }
}

// ─── Collection card ──────────────────────────────────────────────────────────

class _CollectionCard extends StatefulWidget {
  final CollectionDef collection;
  final int found;
  final bool isComplete;
  final Set<String> allKnown;
  final int index;

  const _CollectionCard({
    required this.collection, required this.found, required this.isComplete,
    required this.allKnown, required this.index,
  });

  @override
  State<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<_CollectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.collection;
    final progress = widget.found / c.itemNames.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.isComplete ? c.color.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isComplete ? c.color.withOpacity(0.6) : AppColors.border,
          width: widget.isComplete ? 1.5 : 1,
        ),
        boxShadow: widget.isComplete
            ? [BoxShadow(color: c.color.withOpacity(0.2), blurRadius: 16)]
            : null,
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: c.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.color.withOpacity(0.5)),
                      boxShadow: widget.isComplete
                          ? [BoxShadow(color: c.color.withOpacity(0.4), blurRadius: 12)]
                          : null,
                    ),
                    child: Center(child: Text(
                      widget.isComplete ? '✅' : c.emoji,
                      style: const TextStyle(fontSize: 26),
                    )),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text(c.name, style: TextStyle(
                            color: widget.isComplete ? c.color : AppColors.textPrimary,
                            fontWeight: FontWeight.w800, fontSize: 14,
                          ))),
                          if (widget.isComplete)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: c.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: c.color.withOpacity(0.6)),
                              ),
                              child: Text('COMPLETA!', style: TextStyle(
                                color: c.color, fontSize: 9, fontWeight: FontWeight.w900)),
                            ),
                        ]),
                        const SizedBox(height: 3),
                        Text(c.description, style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10, height: 1.3)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation(c.color),
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${widget.found}/${c.itemNames.length}',
                              style: TextStyle(
                                color: progress == 1 ? c.color : AppColors.textMuted,
                                fontWeight: FontWeight.w800, fontSize: 11,
                              )),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted, size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded: item grid
          if (_expanded) ...[
            Container(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reward
                  if (widget.isComplete)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.color.withOpacity(0.4)),
                      ),
                      child: Row(children: [
                        const Text('🏅 ', style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(
                          'Titolo sbloccato: "${c.rewardBadge}"',
                          style: TextStyle(color: c.color, fontWeight: FontWeight.w700, fontSize: 12),
                        )),
                      ]),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        const Text('🏅 Ricompensa: ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Text('"${c.rewardBadge}"', style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: c.itemNames.map((name) {
                      final found = widget.allKnown.contains(name);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: found ? c.color.withOpacity(0.12) : AppColors.border.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: found ? c.color.withOpacity(0.5) : AppColors.border,
                          ),
                        ),
                        child: Text(
                          found ? name : '???',
                          style: TextStyle(
                            color: found ? c.color : AppColors.textMuted,
                            fontSize: 10, fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: Duration(milliseconds: widget.index * 50))
      .fadeIn(duration: 220.ms).slideY(begin: 0.04, end: 0);
  }
}
