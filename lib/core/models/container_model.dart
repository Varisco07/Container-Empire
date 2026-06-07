import 'rarity.dart';

class LootEntry {
  final String itemName;
  final String itemCategory;
  final String iconAsset;
  final double baseValue;
  final Rarity rarity;
  final double weight;

  const LootEntry({
    required this.itemName,
    required this.itemCategory,
    required this.iconAsset,
    required this.baseValue,
    required this.rarity,
    required this.weight,
  });
}

class ContainerModel {
  final String id;
  final String name;
  final String description;
  final double cost;
  final bool isFree;
  final String colorHex;
  final String iconAsset;
  final String animationAsset;
  final List<LootEntry> lootTable;
  final int levelRequired;

  const ContainerModel({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.colorHex,
    required this.iconAsset,
    required this.animationAsset,
    required this.lootTable,
    this.isFree = false,
    this.levelRequired = 1,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ECONOMIA BILANCIATA v2
//
// finalValue = baseValue × rarity.valueMultiplier × mutation.valueMultiplier
//
// Rarità multiplier: common×1 | uncommon×3 | rare×8 | epic×22 |
//                    legendary×80 | mythic×250 | divine×600 | secret×2000
// Mutation multiplier: golden×1.5 | diamond×3 | radioactive×6 |
//                      galaxy×15 | void×40
//
// EV per container ≈ 1.05–1.3× costo (lieve profitto medio, grandi jackpot rari)
// Pesi loot: comune 75-80%, uncommon 15-18%, rare 3-5%, epic <3%, leg/div/sec <1%
// Luck cap: 2.5× (no più 10×), batch luck ridotta al 70%
// ─────────────────────────────────────────────────────────────────────────────

final List<ContainerModel> containerCatalog = [
  // FREE — gratuito ogni 6h
  ContainerModel(
    id: 'free',
    name: 'FREE CONTAINER',
    description: 'Il tuo container gratuito. Ritorna ogni 6 ore!',
    cost: 0,
    isFree: true,
    colorHex: '#34D399',
    iconAsset: 'assets/images/container_basic.png',
    animationAsset: 'assets/animations/container_basic.json',
    lootTable: _buildLootTable('free'),
  ),
  // BASIC — costo 100€, jackpot normale ~1K, jackpot void ~250K
  ContainerModel(
    id: 'basic',
    name: 'BASIC CONTAINER',
    description: 'Oggetti quotidiani con qualche sorpresa.',
    cost: 100,
    colorHex: '#34D399',
    iconAsset: 'assets/images/container_basic.png',
    animationAsset: 'assets/animations/container_basic.json',
    lootTable: _buildLootTable('basic'),
  ),
  // INDUSTRIAL — costo 500€, jackpot normale ~15K, jackpot void ~1M
  ContainerModel(
    id: 'industrial',
    name: 'INDUSTRIAL CONTAINER',
    description: 'Strumenti pesanti e componenti industriali.',
    cost: 500,
    colorHex: '#3B82F6',
    iconAsset: 'assets/images/container_industrial.png',
    animationAsset: 'assets/animations/container_industrial.json',
    lootTable: _buildLootTable('industrial'),
    levelRequired: 5,
  ),
  // MILITARY — costo 2K€, jackpot normale ~60K, jackpot void ~15M
  ContainerModel(
    id: 'military',
    name: 'MILITARY CONTAINER',
    description: 'Equipaggiamento tattico e tecnologia militare.',
    cost: 2000,
    colorHex: '#A855F7',
    iconAsset: 'assets/images/container_military.png',
    animationAsset: 'assets/animations/container_military.json',
    lootTable: _buildLootTable('military'),
    levelRequired: 15,
  ),
  // LUXURY — costo 10K€, jackpot normale ~500K, jackpot void ~100M
  ContainerModel(
    id: 'luxury',
    name: 'LUXURY CONTAINER',
    description: 'Gioielli, arte e oggetti di valore estremo.',
    cost: 10000,
    colorHex: '#FFD700',
    iconAsset: 'assets/images/container_luxury.png',
    animationAsset: 'assets/animations/container_luxury.json',
    lootTable: _buildLootTable('luxury'),
    levelRequired: 30,
  ),
  // SPACE — costo 100K€, jackpot normale ~5M, jackpot void ~1B
  ContainerModel(
    id: 'space',
    name: 'SPACE CONTAINER',
    description: 'Tecnologia aliena e meteoriti preziosi.',
    cost: 100000,
    colorHex: '#FF6B00',
    iconAsset: 'assets/images/container_space.png',
    animationAsset: 'assets/animations/container_space.json',
    lootTable: _buildLootTable('space'),
    levelRequired: 60,
  ),
  // QUANTUM — costo 1M€, jackpot normale ~200M, jackpot void ~50B
  ContainerModel(
    id: 'quantum',
    name: 'QUANTUM CONTAINER',
    description: 'Oggetti che esistono oltre la realtà conosciuta.',
    cost: 1000000,
    colorHex: '#00F5FF',
    iconAsset: 'assets/images/container_quantum.png',
    animationAsset: 'assets/animations/container_quantum.json',
    lootTable: _buildLootTable('quantum'),
    levelRequired: 100,
  ),
];

List<LootEntry> _buildLootTable(String containerId) {
  // Base values are set so that:
  //   baseValue × rarityMult ≈ target value for that rarity tier
  // All baseValues within a container are intentionally similar so that
  // rarity (not baseValue) drives the price difference.

  final tables = <String, List<LootEntry>>{

    // ── FREE (costo 0€) ───────────────────────────────────────────────────────
    'free': [
      // common:    4×1  =   4€
      LootEntry(itemName: 'Bullone Arrugginito',  itemCategory: 'Ferraglia',      iconAsset: '', baseValue: 4,   rarity: Rarity.common,   weight: 40),
      LootEntry(itemName: 'Bottiglia Vuota',       itemCategory: 'Oggetti',        iconAsset: '', baseValue: 4,   rarity: Rarity.common,   weight: 35),
      // uncommon:  4×3  =  12€
      LootEntry(itemName: 'Chiave Inglese',        itemCategory: 'Utensili',       iconAsset: '', baseValue: 4,   rarity: Rarity.uncommon, weight: 18),
      // rare:      4×10 =  40€
      LootEntry(itemName: 'Orologio Rotto',        itemCategory: 'Elettronica',    iconAsset: '', baseValue: 4,   rarity: Rarity.rare,     weight: 5),
      // epic:      4×35 = 140€
      LootEntry(itemName: 'Moneta Antica',         itemCategory: 'Collezionabili', iconAsset: '', baseValue: 4,   rarity: Rarity.epic,     weight: 2),
    ],

    // ── BASIC (costo 100€) ────────────────────────────────────────────────────
    // EV target ~110€ (1.1× costo). Max jackpot: leg×80=2400€, leg+void×40=96K€ (rarissimo)
    // Rarity chances: common≈75%, uncommon≈18%, rare≈5%, epic≈1.5%, legendary≈0.5%
    'basic': [
      LootEntry(itemName: 'Cacciavite',            itemCategory: 'Utensili',       iconAsset: '', baseValue: 30,  rarity: Rarity.common,   weight: 45),
      LootEntry(itemName: 'Martello',              itemCategory: 'Utensili',       iconAsset: '', baseValue: 30,  rarity: Rarity.common,   weight: 30),
      LootEntry(itemName: 'Smartphone Vecchio',    itemCategory: 'Elettronica',    iconAsset: '', baseValue: 30,  rarity: Rarity.uncommon, weight: 18),
      LootEntry(itemName: 'Orologio Vintage',      itemCategory: 'Gioielleria',    iconAsset: '', baseValue: 30,  rarity: Rarity.rare,     weight: 5),
      LootEntry(itemName: 'Chitarra Acustica',     itemCategory: 'Strumenti',      iconAsset: '', baseValue: 30,  rarity: Rarity.epic,     weight: 1.5),
      LootEntry(itemName: 'Vaso Ming',             itemCategory: 'Arte',           iconAsset: '', baseValue: 30,  rarity: Rarity.legendary,weight: 0.5),
    ],

    // ── INDUSTRIAL (costo 500€) ───────────────────────────────────────────────
    // EV target ~530€ (1.06× costo). Max jackpot: mythic×250=22500€, +void=900K€
    // Rarity chances: common≈55%, uncommon≈28%, rare≈13%, epic≈3%, leg≈1%, mythic≈0.5%
    'industrial': [
      LootEntry(itemName: 'Trapano Industriale',   itemCategory: 'Macchinari',     iconAsset: '', baseValue: 90,  rarity: Rarity.common,   weight: 35),
      LootEntry(itemName: 'Saldatrice',            itemCategory: 'Macchinari',     iconAsset: '', baseValue: 90,  rarity: Rarity.uncommon, weight: 28),
      LootEntry(itemName: 'Generatore',            itemCategory: 'Energia',        iconAsset: '', baseValue: 90,  rarity: Rarity.rare,     weight: 13),
      LootEntry(itemName: 'CNC Machine Part',      itemCategory: 'Macchinari',     iconAsset: '', baseValue: 90,  rarity: Rarity.epic,     weight: 3),
      LootEntry(itemName: 'Prototipo Robot',       itemCategory: 'Robotica',       iconAsset: '', baseValue: 90,  rarity: Rarity.legendary,weight: 0.8),
      LootEntry(itemName: 'Core Nucleare Piccolo', itemCategory: 'Energia',        iconAsset: '', baseValue: 90,  rarity: Rarity.mythic,   weight: 0.2),
    ],

    // ── MILITARY (costo 2.000€) ───────────────────────────────────────────────
    // EV target ~2200€ (1.1× costo). Max jackpot: mythic×250=87500€, +void=3.5M€
    // Rarity chances: common≈50%, uncommon≈30%, rare≈17%, epic≈2.5%, leg≈0.4%, mythic≈0.1%
    'military': [
      LootEntry(itemName: 'Elmetto Tattico',         itemCategory: 'Equipaggiamento', iconAsset: '', baseValue: 350, rarity: Rarity.common,   weight: 50),
      LootEntry(itemName: 'Giubbotto Antiproiettile',itemCategory: 'Equipaggiamento', iconAsset: '', baseValue: 350, rarity: Rarity.uncommon, weight: 30),
      LootEntry(itemName: 'Drone Militare',          itemCategory: 'Tech Militare',   iconAsset: '', baseValue: 350, rarity: Rarity.rare,     weight: 17),
      LootEntry(itemName: 'Visore Notturno',         itemCategory: 'Tech Militare',   iconAsset: '', baseValue: 350, rarity: Rarity.epic,     weight: 2.5),
      LootEntry(itemName: 'Esoscheletro Prototipo',  itemCategory: 'Tech Militare',   iconAsset: '', baseValue: 350, rarity: Rarity.legendary,weight: 0.4),
      LootEntry(itemName: 'Stealth Tech Module',     itemCategory: 'Tech Militare',   iconAsset: '', baseValue: 350, rarity: Rarity.mythic,   weight: 0.1),
    ],

    // ── LUXURY (costo 10.000€) ────────────────────────────────────────────────
    // EV target ~11K€ (1.1× costo). Max jackpot: divine×600=900K€, +void=36M€
    // Rarity chances: common≈50%, uncommon≈30%, rare≈17%, epic≈2.5%, leg≈0.4%, divine≈0.1%
    'luxury': [
      LootEntry(itemName: 'Orologio Rolex',          itemCategory: 'Gioielleria',    iconAsset: '', baseValue: 1500, rarity: Rarity.common,   weight: 50),
      LootEntry(itemName: 'Borsa Hermès',            itemCategory: 'Fashion',        iconAsset: '', baseValue: 1500, rarity: Rarity.uncommon, weight: 30),
      LootEntry(itemName: 'Anello con Diamante',     itemCategory: 'Gioielleria',    iconAsset: '', baseValue: 1500, rarity: Rarity.rare,     weight: 17),
      LootEntry(itemName: 'Ferrari Miniatura d\'Oro',itemCategory: 'Collezionabili', iconAsset: '', baseValue: 1500, rarity: Rarity.epic,     weight: 2.5),
      LootEntry(itemName: 'Quadro Picasso',          itemCategory: 'Arte',           iconAsset: '', baseValue: 1500, rarity: Rarity.legendary,weight: 0.4),
      LootEntry(itemName: 'Corona Reale',            itemCategory: 'Regali',         iconAsset: '', baseValue: 1500, rarity: Rarity.divine,   weight: 0.1),
    ],

    // ── SPACE (costo 100.000€) ────────────────────────────────────────────────
    // EV target ~115K€ (1.15× costo). Max jackpot: secret×2000=30M€, +void=1.2B€ (1/1M eventi)
    // Rarity chances: common≈50%, uncommon≈30%, rare≈17%, epic≈2.5%, leg≈0.4%, secret≈0.1%
    'space': [
      LootEntry(itemName: 'Meteorite Frammento',     itemCategory: 'Spaziale',       iconAsset: '', baseValue: 15000, rarity: Rarity.common,   weight: 50),
      LootEntry(itemName: 'Luna Rock Certificato',   itemCategory: 'Spaziale',       iconAsset: '', baseValue: 15000, rarity: Rarity.uncommon, weight: 30),
      LootEntry(itemName: 'Satellite Disattivato',   itemCategory: 'Tech Spaziale',  iconAsset: '', baseValue: 15000, rarity: Rarity.rare,     weight: 17),
      LootEntry(itemName: 'Cristallo Alieno',        itemCategory: 'Alieno',         iconAsset: '', baseValue: 15000, rarity: Rarity.epic,     weight: 2.5),
      LootEntry(itemName: 'Stardust Vial',           itemCategory: 'Alieno',         iconAsset: '', baseValue: 15000, rarity: Rarity.legendary,weight: 0.4),
      LootEntry(itemName: 'Nucleo di Stella di Neutroni', itemCategory: 'Alieno',    iconAsset: '', baseValue: 15000, rarity: Rarity.secret,   weight: 0.1),
    ],

    // ── QUANTUM (costo 1.000.000€) ────────────────────────────────────────────
    // EV target ~1.3M€ (1.3× costo). Max jackpot: secret×2000=300M€, +void=12B€ (1/5M)
    // Rarity chances: common≈45%, uncommon≈30%, rare≈18%, epic≈5%, leg≈1.5%, div≈0.4%, sec≈0.1%
    'quantum': [
      LootEntry(itemName: 'Bit Quantistico',         itemCategory: 'Quantum',        iconAsset: '', baseValue: 150000, rarity: Rarity.common,   weight: 45),
      LootEntry(itemName: 'Entangled Particle Pair', itemCategory: 'Quantum',        iconAsset: '', baseValue: 150000, rarity: Rarity.uncommon, weight: 30),
      LootEntry(itemName: 'Quantum Processor',       itemCategory: 'Quantum',        iconAsset: '', baseValue: 150000, rarity: Rarity.rare,     weight: 18),
      LootEntry(itemName: 'Materia Oscura Campione', itemCategory: 'Quantum',        iconAsset: '', baseValue: 150000, rarity: Rarity.epic,     weight: 5),
      LootEntry(itemName: 'Singolarità Compressa',   itemCategory: 'Quantum',        iconAsset: '', baseValue: 150000, rarity: Rarity.legendary,weight: 1.5),
      LootEntry(itemName: 'Frammento Big Bang',      itemCategory: 'Quantum',        iconAsset: '', baseValue: 150000, rarity: Rarity.divine,   weight: 0.4),
      LootEntry(itemName: 'Ω Omega Particle',        itemCategory: 'Quantum',        iconAsset: '', baseValue: 150000, rarity: Rarity.secret,   weight: 0.1),
      // 1 in ~1,000,000: notifica globale quando trovato
      LootEntry(itemName: 'Fenice Cosmica',          itemCategory: 'Cosmico',        iconAsset: '', baseValue: 150000, rarity: Rarity.cosmic,   weight: 0.00001),
      LootEntry(itemName: 'Cristallo dell\'Universo',itemCategory: 'Cosmico',        iconAsset: '', baseValue: 150000, rarity: Rarity.cosmic,   weight: 0.000005),
      LootEntry(itemName: 'Singolarità Primordiale', itemCategory: 'Cosmico',        iconAsset: '', baseValue: 150000, rarity: Rarity.cosmic,   weight: 0.000003),
    ],
  };
  return tables[containerId] ?? tables['free']!;
}
