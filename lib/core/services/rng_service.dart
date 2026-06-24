import 'dart:math';
import '../models/container_model.dart';
import '../models/item_model.dart';
import '../models/player_model.dart';
import '../models/rarity.dart';
import 'package:uuid/uuid.dart';

/// Advanced RNG system with luck boosts, pity system, and mutation rates.
class RngService {
  static final RngService _instance = RngService._internal();
  factory RngService() => _instance;
  RngService._internal();

  final Random _random = Random.secure();
  final Uuid _uuid = const Uuid();

  // Active event multipliers
  double eventLuckMultiplier = 1.0;
  double eventMutationMultiplier = 1.0;

  // Temporary luck boosts from mutations (Diamond mutation)
  double _tempLuckBonus = 0.0;
  int _tempLuckRemainingOpens = 0;

  /// Apply a temporary luck bonus for N opens (Diamond mutation effect).
  void applyTemporaryLuck(double bonus, int opens) {
    _tempLuckBonus += bonus;
    _tempLuckRemainingOpens += opens;
  }

  double get _effectiveTempLuck {
    if (_tempLuckRemainingOpens <= 0) return 0;
    _tempLuckRemainingOpens--;
    if (_tempLuckRemainingOpens <= 0) {
      final b = _tempLuckBonus;
      _tempLuckBonus = 0;
      return b;
    }
    return _tempLuckBonus;
  }

  /// Roll a complete item from the container loot table.
  /// Returns (item, isPityActivated)
  ItemModel rollItem({
    required ContainerModel container,
    required PlayerModel player,
    bool forcedRare = false, // pity system: force at least rare
  }) {
    final tempLuck = _effectiveTempLuck;
    final effectiveLuck = (player.luckBoost + tempLuck) * eventLuckMultiplier * (player.isVip ? 1.5 : 1.0);
    final effectiveMutation = player.mutationBoost * eventMutationMultiplier * (player.isVip ? 2.0 : 1.0);

    final entry = _rollLootEntry(container.lootTable, effectiveLuck, forcedRare: forcedRare);
    final mutation = _rollMutation(effectiveMutation);

    return ItemModel(
      id: _uuid.v4(),
      name: entry.itemName,
      category: entry.itemCategory,
      rarityKey: entry.rarity.name,
      mutationKey: mutation.name,
      baseValue: entry.baseValue,
      iconAsset: entry.iconAsset,
      obtainedAt: DateTime.now(),
      containerId: container.id,
    );
  }

  LootEntry _rollLootEntry(List<LootEntry> table, double luckMultiplier, {bool forcedRare = false}) {
    var workingTable = table;

    // Pity: if forced rare, exclude common and uncommon
    if (forcedRare) {
      final rareOrBetter = table.where(
        (e) => e.rarity != Rarity.common && e.rarity != Rarity.uncommon,
      ).toList();
      if (rareOrBetter.isNotEmpty) workingTable = rareOrBetter;
    }

    // Apply luck boost: reduce common weight, increase rare weight.
    // Hard cap at 2.5× to prevent exponential gains from upgrades.
    final clampedLuck = luckMultiplier.clamp(1.0, 2.5);
    final adjusted = workingTable.map((e) {
      double w = e.weight;
      if (e.rarity == Rarity.common || e.rarity == Rarity.uncommon) {
        w = w / clampedLuck;
      } else {
        w = w * clampedLuck;
      }
      return _WeightedEntry(e, w.clamp(0.01, double.infinity));
    }).toList();

    final totalWeight = adjusted.fold(0.0, (s, e) => s + e.weight);
    double roll = _random.nextDouble() * totalWeight;

    for (final entry in adjusted) {
      roll -= entry.weight;
      if (roll <= 0) return entry.entry;
    }

    return workingTable.last;
  }

  Mutation _rollMutation(double mutationMultiplier) {
    final effectiveChance = mutationMultiplier * eventMutationMultiplier;
    final roll = _random.nextDouble() * 100;

    double cumulative = 0;
    for (final m in [
      Mutation.voidMutation,
      Mutation.galaxy,
      Mutation.radioactive,
      Mutation.diamond,
      Mutation.golden,
    ]) {
      cumulative += m.dropRate * effectiveChance;
      if (roll < cumulative) return m;
    }
    return Mutation.none;
  }

  /// Probabilità di trovare un Container Ombra (1/500 per apertura).
  /// Ritorna true se il giocatore ha trovato il container segreto.
  bool rollSecretContainer() => _random.nextInt(500) == 0;

  /// Genera un item speciale dal Container Ombra (solo Epic+).
  ItemModel rollShadowItem({required PlayerModel player}) {
    // Crea una loot table virtuale con solo item Epic+
    const shadowTable = _shadowLootTable;
    final idx = _random.nextInt(shadowTable.length);
    final entry = shadowTable[idx];
    final mutation = _rollMutation(player.mutationBoost * 2.0); // double mutation chance
    return ItemModel(
      id: _uuid.v4(),
      name: entry.$1,
      category: 'Shadow Vault',
      rarityKey: entry.$2,
      mutationKey: mutation.name,
      baseValue: entry.$3,
      iconAsset: '',
      obtainedAt: DateTime.now(),
      containerId: 'shadow',
    );
  }

  static const _shadowLootTable = [
    ('Cristallo Alieno',            'epic',      180.0),
    ('Stardust Vial',               'epic',      180.0),
    ('Esoscheletro Prototipo',      'epic',      180.0),
    ('Orologio Rolex',              'legendary', 300.0),
    ('Borsa Hermès',                'legendary', 300.0),
    ('Corona Reale',                'legendary', 300.0),
    ('Satellite Disattivato',       'mythic',    800.0),
    ('Nucleo di Stella di Neutroni','mythic',    800.0),
    ('Bit Quantistico',             'divine',   2000.0),
    ('Quantum Processor',           'divine',   2000.0),
    ('Ω Omega Particle',            'secret',  10000.0),
  ];

  /// Check if rarity counts as "rare+" for pity reset purposes
  bool isRarePlus(String rarityKey) {
    const rarePlus = {'rare', 'epic', 'legendary', 'mythic', 'divine', 'secret', 'cosmic'};
    return rarePlus.contains(rarityKey);
  }

  /// Roll a single item with reduced luck (for batch opening).
  /// Uses 65% of the player's luck boost to prevent exponential gains
  /// from opening hundreds of containers simultaneously.
  ItemModel rollItemBatch({
    required ContainerModel container,
    required PlayerModel player,
    bool forcedRare = false,
  }) {
    // Reduce luck in batch to 65% — still benefits from upgrades but not exploitable
    final reducedLuck = 1.0 + (player.luckBoost - 1.0) * 0.65;
    final effectiveLuck = reducedLuck * eventLuckMultiplier * (player.isVip ? 1.3 : 1.0);
    // Mutation boost reduced to 80% in batch
    final effectiveMutation = player.mutationBoost * 0.8 * eventMutationMultiplier;

    final entry = _rollLootEntry(container.lootTable, effectiveLuck, forcedRare: forcedRare);
    final mutation = _rollMutation(effectiveMutation);

    return ItemModel(
      id: _uuid.v4(),
      name: entry.itemName,
      category: entry.itemCategory,
      rarityKey: entry.rarity.name,
      mutationKey: mutation.name,
      baseValue: entry.baseValue,
      iconAsset: entry.iconAsset,
      obtainedAt: DateTime.now(),
      containerId: container.id,
    );
  }

  /// Simulate multiple rolls (used internally, not for batch opening UI)
  List<ItemModel> rollBatch({
    required ContainerModel container,
    required PlayerModel player,
    required int count,
  }) {
    return List.generate(count, (i) => rollItemBatch(container: container, player: player));
  }
}

class _WeightedEntry {
  final LootEntry entry;
  final double weight;
  const _WeightedEntry(this.entry, this.weight);
}
