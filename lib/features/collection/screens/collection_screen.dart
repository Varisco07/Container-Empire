import 'package:flutter/material.dart';
import '../../../core/models/container_model.dart';
import '../../../core/models/rarity.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/neon_text.dart';

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

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = sl<InventoryService>();
    final discovered = inv.discoveredItems;

    // Build complete collection catalog from all loot tables
    final allItems = containerCatalog.expand((c) => c.lootTable).toList();
    final uniqueNames = <String>{};
    final unique = allItems.where((e) => uniqueNames.add(e.itemName)).toList();
    final total = unique.length;
    final found = unique.where((e) => discovered.containsKey(e.itemName)).length;
    final pct = total > 0 ? found / total : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('COLLEZIONE')),
      body: Column(
        children: [
          // Header stats
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.neonPurple.withOpacity(0.15), AppColors.neonCyan.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonPurple.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                NeonText('$found / $total', color: AppColors.neonCyan, fontSize: 36, blurRadius: 16),
                const Text('Oggetti scoperti', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(pct * 100).toStringAsFixed(1)}% completato',
                  style: const TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // Filter by rarity
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: Rarity.values.map((r) {
                final rItems = unique.where((e) => e.rarity == r).toList();
                if (rItems.isEmpty) return const SizedBox.shrink();
                return _RaritySection(
                  rarity: r,
                  items: rItems,
                  discovered: discovered,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaritySection extends StatelessWidget {
  final Rarity rarity;
  final List<LootEntry> items;
  final Map<String, bool> discovered;

  const _RaritySection({required this.rarity, required this.items, required this.discovered});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(rarity.name);
    final foundCount = items.where((i) => discovered.containsKey(i.itemName)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
              )),
              const SizedBox(width: 8),
              NeonText(rarity.displayName, color: color, fontSize: 14, blurRadius: 6),
              const Spacer(),
              Text('$foundCount/${items.length}', style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            final isFound = discovered.containsKey(item.itemName);
            final emoji = _itemEmojis[item.itemName] ?? '📦';
            return Container(
              decoration: BoxDecoration(
                color: isFound ? color.withOpacity(0.12) : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isFound ? color.withOpacity(0.7) : AppColors.border),
                boxShadow: isFound ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 6)] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFound ? emoji : '❓',
                    style: TextStyle(fontSize: 24, color: isFound ? null : const Color(0x44FFFFFF)),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      isFound ? item.itemName : '???',
                      style: TextStyle(
                        color: isFound ? color : AppColors.textMuted,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
