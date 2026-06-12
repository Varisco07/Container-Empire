import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/item_model.dart';
import '../../../core/models/rarity.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/profile/providers/player_provider.dart';

// ─── Ricette di fusione ───────────────────────────────────────────────────────
//
// 3 ingredient di rarità X → 1 item di rarità X+1
// Esempio: 3 Common → 1 Uncommon

class _Recipe {
  final String label;
  final String inputRarity;
  final String outputRarity;
  final int inputCount;
  final Color color;
  const _Recipe({
    required this.label,
    required this.inputRarity,
    required this.outputRarity,
    required this.inputCount,
    required this.color,
  });
}

const _recipes = [
  _Recipe(label: 'Comune → Non Comune', inputRarity: 'common', outputRarity: 'uncommon',
      inputCount: 3, color: AppColors.common),
  _Recipe(label: 'Non Comune → Raro', inputRarity: 'uncommon', outputRarity: 'rare',
      inputCount: 3, color: AppColors.uncommon),
  _Recipe(label: 'Raro → Epico', inputRarity: 'rare', outputRarity: 'epic',
      inputCount: 3, color: AppColors.rare),
  _Recipe(label: 'Epico → Leggendario', inputRarity: 'epic', outputRarity: 'legendary',
      inputCount: 4, color: AppColors.epic),
  _Recipe(label: 'Leggendario → Mitico', inputRarity: 'legendary', outputRarity: 'mythic',
      inputCount: 5, color: AppColors.legendary),
  _Recipe(label: 'Mitico → Divino', inputRarity: 'mythic', outputRarity: 'divine',
      inputCount: 6, color: AppColors.mythic),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class CraftingScreen extends ConsumerStatefulWidget {
  const CraftingScreen({super.key});

  @override
  ConsumerState<CraftingScreen> createState() => _CraftingScreenState();
}

class _CraftingScreenState extends ConsumerState<CraftingScreen>
    with TickerProviderStateMixin {
  int _selectedRecipe = 0;
  final Set<String> _selectedItemIds = {};
  bool _crafting = false;
  ItemModel? _craftResult;
  late AnimationController _sparkCtrl;

  @override
  void initState() {
    super.initState();
    _sparkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void dispose() {
    _sparkCtrl.dispose();
    super.dispose();
  }

  _Recipe get _recipe => _recipes[_selectedRecipe];

  List<ItemModel> get _ingredients {
    return sl<InventoryService>()
        .filter(sort: SortMode.newest)
        .where((i) => i.rarityKey == _recipe.inputRarity && !i.isLocked)
        .toList();
  }

  bool get _canCraft =>
      _selectedItemIds.length >= _recipe.inputCount;

  Future<void> _doCraft() async {
    if (!_canCraft || _crafting) return;
    setState(() { _crafting = true; _craftResult = null; });

    final inv = sl<InventoryService>();

    // Rimuovi gli ingredienti
    final toRemove = _selectedItemIds.take(_recipe.inputCount).toList();
    for (final id in toRemove) {
      await inv.removeItem(id);
    }

    // Genera item risultante
    final rng      = Random();
    final allItems = inv.filter(sort: SortMode.newest);
    // Prendi la categoria più comune tra gli ingredienti
    final usedItems = allItems.where((i) => toRemove.contains(i.id)).toList();
    final categoryFreq = <String, int>{};
    for (final i in usedItems) categoryFreq[i.category] = (categoryFreq[i.category] ?? 0) + 1;

    // Se non c'erano item (già rimossi), scegli categoria random dal pool
    final allPool = sl<InventoryService>().filter(sort: SortMode.newest);
    final randomCategory = allPool.isNotEmpty
        ? allPool[rng.nextInt(allPool.length)].category
        : 'Elettronica';
    final category = categoryFreq.isNotEmpty
        ? (categoryFreq.entries.reduce((a, b) => a.value >= b.value ? a : b).key)
        : randomCategory;

    // Mutazione: piccola chance in base alla rarità output
    final mutChance = _mutationChance(_recipe.outputRarity);
    final mutKey    = rng.nextDouble() < mutChance ? _randomMutation(rng) : 'none';

    // Genera un item casuale dalla rarità output con il catalog items list
    final craftedItem = _buildCraftedItem(
      rarityKey:  _recipe.outputRarity,
      category:   category,
      mutationKey: mutKey,
    );

    await inv.addItem(craftedItem);
    ref.read(playerNotifierProvider.notifier).refresh();

    // Haptic + play spark animation
    HapticFeedback.heavyImpact();
    _sparkCtrl.forward(from: 0);

    setState(() {
      _crafting    = false;
      _craftResult = craftedItem;
      _selectedItemIds.clear();
    });
  }

  double _mutationChance(String rarity) {
    switch (rarity) {
      case 'uncommon':  return 0.02;
      case 'rare':      return 0.05;
      case 'epic':      return 0.10;
      case 'legendary': return 0.18;
      case 'mythic':    return 0.28;
      case 'divine':    return 0.40;
      default:          return 0.01;
    }
  }

  String _randomMutation(Random rng) {
    const mutations = ['golden', 'diamond', 'radioactive', 'galaxy', 'voidMutation'];
    return mutations[rng.nextInt(mutations.length)];
  }

  // Helper — mappa string key → Rarity
  static Rarity _rarityFromKey(String key) {
    switch (key) {
      case 'uncommon':  return Rarity.uncommon;
      case 'rare':      return Rarity.rare;
      case 'epic':      return Rarity.epic;
      case 'legendary': return Rarity.legendary;
      case 'mythic':    return Rarity.mythic;
      case 'divine':    return Rarity.divine;
      case 'secret':    return Rarity.secret;
      case 'cosmic':    return Rarity.cosmic;
      default:          return Rarity.common;
    }
  }

  // Base value per rarità (valore di un item base, senza moltiplicatori)
  static double _baseValueForRarity(Rarity r) => r.valueMultiplier * 120.0;

  ItemModel _buildCraftedItem({
    required String rarityKey,
    required String category,
    required String mutationKey,
  }) {
    // Pool di nomi per categoria e rarità
    final rarity  = _rarityFromKey(rarityKey);
    final baseVal = _baseValueForRarity(rarity) * (0.85 + Random().nextDouble() * 0.30);

    // Nomi tematici basati su categoria
    final namePool = _namePool(category, rarityKey);
    final name     = namePool[Random().nextInt(namePool.length)];

    return ItemModel(
      id:          'craft_${DateTime.now().millisecondsSinceEpoch}',
      name:        name,
      category:    category,
      rarityKey:   rarityKey,
      mutationKey: mutationKey,
      baseValue:   baseVal,
      iconAsset:   '',
      obtainedAt:  DateTime.now(),
      containerId: 'crafting',
    );
  }

  List<String> _namePool(String category, String rarity) {
    final rarityPrefix = {
      'uncommon':  'Potenziato', 'rare': 'Avanzato', 'epic': 'Elite',
      'legendary': 'Supremo',   'mythic': 'Mitico',  'divine': 'Divino',
    }[rarity] ?? 'Forgiato';

    switch (category.toLowerCase()) {
      case 'elettronica': return ['$rarityPrefix Chip', '$rarityPrefix Processore', '$rarityPrefix Modulo'];
      case 'gioielleria': return ['$rarityPrefix Diamante', '$rarityPrefix Rubino', '$rarityPrefix Cristallo'];
      case 'arte':        return ['$rarityPrefix Capolavoro', '$rarityPrefix Scultura', '$rarityPrefix Dipinto'];
      case 'energia':     return ['$rarityPrefix Nucleo', '$rarityPrefix Cella', '$rarityPrefix Reattore'];
      case 'robotica':    return ['$rarityPrefix Bot', '$rarityPrefix Androide', '$rarityPrefix Meccanismo'];
      case 'quantum':     return ['$rarityPrefix Quark', '$rarityPrefix Antimateria', '$rarityPrefix Acceleratore'];
      default:            return ['$rarityPrefix Oggetto', '$rarityPrefix Manufatto', '$rarityPrefix Reliquia'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = _ingredients;
    final recipe      = _recipe;
    final rarityColor = AppColors.rarityColor(recipe.outputRarity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('FUSIONE', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // ── Selettore ricette ──────────────────────────────────────────────
          Container(
            height: 52,
            color: AppColors.background,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _recipes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final r       = _recipes[i];
                final isSelected = i == _selectedRecipe;
                // Conta disponibilità
                final available = sl<InventoryService>()
                    .filter(sort: SortMode.newest)
                    .where((item) => item.rarityKey == r.inputRarity && !item.isLocked)
                    .length;
                final canDo = available >= r.inputCount;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedRecipe = i;
                    _selectedItemIds.clear();
                    _craftResult = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? r.color.withOpacity(0.18) : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? r.color : (canDo ? r.color.withOpacity(0.4) : AppColors.border),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      if (canDo) Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: r.color),
                      ),
                      Center(child: Text(r.label, style: TextStyle(
                        color: isSelected ? r.color : (canDo ? r.color : AppColors.textMuted),
                        fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500))),
                    ]),
                  ),
                );
              },
            ),
          ),

          // ── Area di fusione ───────────────────────────────────────────────
          _FusionArea(
            recipe:           recipe,
            selectedCount:    _selectedItemIds.length,
            rarityColor:      rarityColor,
            canCraft:         _canCraft,
            crafting:         _crafting,
            craftResult:      _craftResult,
            sparkController:  _sparkCtrl,
            onCraft:          _doCraft,
            onDismissResult:  () => setState(() => _craftResult = null),
          ),

          // ── Lista ingredienti selezionabili ───────────────────────────────
          Expanded(
            child: _IngredientGrid(
              items:           ingredients,
              selectedIds:     _selectedItemIds,
              neededCount:     recipe.inputCount,
              rarityColor:     rarityColor,
              onToggle: (id) {
                setState(() {
                  if (_selectedItemIds.contains(id)) {
                    _selectedItemIds.remove(id);
                  } else if (_selectedItemIds.length < recipe.inputCount) {
                    _selectedItemIds.add(id);
                  }
                });
                _craftResult = null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fusion area ──────────────────────────────────────────────────────────────

class _FusionArea extends StatelessWidget {
  final _Recipe recipe;
  final int selectedCount;
  final Color rarityColor;
  final bool canCraft, crafting;
  final ItemModel? craftResult;
  final AnimationController sparkController;
  final VoidCallback onCraft, onDismissResult;

  const _FusionArea({
    required this.recipe, required this.selectedCount, required this.rarityColor,
    required this.canCraft, required this.crafting, required this.craftResult,
    required this.sparkController, required this.onCraft, required this.onDismissResult,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: canCraft ? rarityColor.withOpacity(0.7) : AppColors.border,
          width: canCraft ? 1.5 : 1,
        ),
        boxShadow: canCraft
            ? [BoxShadow(color: rarityColor.withOpacity(0.2), blurRadius: 20)]
            : null,
      ),
      child: craftResult != null
          ? _ResultView(item: craftResult!, color: rarityColor, onDismiss: onDismissResult)
          : Column(
              children: [
                // Ingredienti → Risultato
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RarityBox(rarityKey: recipe.inputRarity,
                        label: '${selectedCount}/${recipe.inputCount}'),
                    const SizedBox(width: 10),
                    AnimatedBuilder(
                      animation: sparkController,
                      builder: (_, __) => Transform.rotate(
                        angle: sparkController.value * 2 * pi,
                        child: Icon(Icons.auto_fix_high_rounded,
                          color: canCraft ? rarityColor : AppColors.textMuted, size: 28),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _RarityBox(rarityKey: recipe.outputRarity, label: '1'),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: selectedCount / recipe.inputCount,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(rarityColor),
                  ),
                ),
                const SizedBox(height: 12),
                // Craft button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: canCraft && !crafting ? onCraft : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canCraft ? rarityColor : AppColors.border,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: crafting
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            canCraft ? '⚗️  FONDI ADESSO' : 'Seleziona ${recipe.inputCount} item',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RarityBox extends StatelessWidget {
  final String rarityKey, label;
  const _RarityBox({required this.rarityKey, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(rarityKey);
    final name  = _CraftingScreenState._rarityFromKey(rarityKey).displayName;
    return Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.6), width: 2),
          ),
          child: Center(child: Text(_emoji(rarityKey), style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  String _emoji(String key) {
    switch (key) {
      case 'common':    return '⬜';
      case 'uncommon':  return '🟩';
      case 'rare':      return '🟦';
      case 'epic':      return '🟣';
      case 'legendary': return '🟡';
      case 'mythic':    return '🔴';
      case 'divine':    return '✨';
      default:          return '📦';
    }
  }
}

class _ResultView extends StatelessWidget {
  final ItemModel item;
  final Color color;
  final VoidCallback onDismiss;
  const _ResultView({required this.item, required this.color, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final rarity = _CraftingScreenState._rarityFromKey(item.rarityKey);
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('✨', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text('FUSIONE RIUSCITA!', style: TextStyle(
            color: color, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5,
            shadows: [Shadow(color: color, blurRadius: 12)])),
          const SizedBox(width: 8),
          const Text('✨', style: TextStyle(fontSize: 24)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(children: [
            Text(_categoryEmoji(item.category), style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
              Text(rarity.displayName, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
            ])),
            Text('🪙 ${_fmt(item.finalValue)}', style: TextStyle(
              color: color, fontWeight: FontWeight.w900, fontSize: 16)),
          ]),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onDismiss,
          child: const Text('Continua a fondere', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      ],
    ).animate().scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut, duration: 500.ms).fadeIn();
  }

  String _categoryEmoji(String cat) {
    switch (cat.toLowerCase()) {
      case 'elettronica': return '📱';
      case 'gioielleria': return '💍';
      case 'arte':        return '🖼️';
      case 'energia':     return '⚡';
      case 'robotica':    return '🤖';
      case 'quantum':     return '⚛️';
      default:            return '📦';
    }
  }

  static String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Ingredient grid ──────────────────────────────────────────────────────────

class _IngredientGrid extends StatelessWidget {
  final List<ItemModel> items;
  final Set<String> selectedIds;
  final int neededCount;
  final Color rarityColor;
  final ValueChanged<String> onToggle;

  const _IngredientGrid({
    required this.items, required this.selectedIds, required this.neededCount,
    required this.rarityColor, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📭', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        const Text('Nessun ingrediente disponibile', style: TextStyle(
          color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Apri container per ottenere item di questa rarità',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center),
      ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(children: [
            const Text('INGREDIENTI', style: TextStyle(
              color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const Spacer(),
            Text('${items.length} disponibili', style: const TextStyle(
              color: AppColors.textMuted, fontSize: 10)),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, childAspectRatio: 0.8,
              crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item       = items[i];
              final isSelected = selectedIds.contains(item.id);
              final isDisabled = !isSelected && selectedIds.length >= neededCount;
              return GestureDetector(
                onTap: isDisabled ? null : () => onToggle(item.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? rarityColor.withOpacity(0.2)
                        : isDisabled
                            ? AppColors.surface.withOpacity(0.4)
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? rarityColor : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: rarityColor.withOpacity(0.3), blurRadius: 10)]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: isDisabled ? 0.4 : 1.0,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(_categoryEmoji(item.category), style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 3),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Text(item.name, textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 7),
                              overflow: TextOverflow.ellipsis, maxLines: 2),
                          ),
                          Text('🪙 ${_fmt(item.finalValue)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 7,
                                fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 4, right: 4,
                          child: Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: rarityColor),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: (i * 20).clamp(0, 200)))
                  .fadeIn(duration: 200.ms),
              );
            },
          ),
        ),
      ],
    );
  }

  String _categoryEmoji(String cat) {
    switch (cat.toLowerCase()) {
      case 'elettronica': return '📱';
      case 'gioielleria': return '💍';
      case 'arte':        return '🖼️';
      case 'energia':     return '⚡';
      case 'robotica':    return '🤖';
      case 'quantum':     return '⚛️';
      case 'spaziale':    return '🌌';
      case 'alieno':      return '👽';
      case 'macchinari':  return '⚙️';
      case 'strumenti':   return '🎸';
      default:            return '📦';
    }
  }

  static String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
