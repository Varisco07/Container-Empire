class AchievementDef {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category; // 'opening' | 'collection' | 'economy' | 'social' | 'special'
  final String? badgeTitle; // titolo equipaggiabile che sblocca

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    this.badgeTitle,
  });
}

class AchievementDefs {
  static const all = <AchievementDef>[
    // Opening
    AchievementDef(id: 'first_open',    emoji: '📦', category: 'opening', title: 'Prima Apertura',      description: 'Apri il tuo primo container'),
    AchievementDef(id: 'opens_10',      emoji: '🔟', category: 'opening', title: 'Collezionista',        description: 'Apri 10 container'),
    AchievementDef(id: 'opens_100',     emoji: '💯', category: 'opening', title: 'Appassionato',         description: 'Apri 100 container'),
    AchievementDef(id: 'opens_1000',    emoji: '🏆', category: 'opening', title: 'Veterano',             description: 'Apri 1.000 container',  badgeTitle: 'Veterano'),
    AchievementDef(id: 'opens_10000',   emoji: '👑', category: 'opening', title: 'Leggenda',             description: 'Apri 10.000 container', badgeTitle: 'Leggenda'),
    AchievementDef(id: 'first_free',    emoji: '🎁', category: 'opening', title: 'Gratis si mangia!',    description: 'Apri il container gratuito'),
    AchievementDef(id: 'batch_10',      emoji: '⚡', category: 'opening', title: 'In serie',             description: 'Apri 10 container in una volta'),
    // Rarity
    AchievementDef(id: 'first_rare',    emoji: '💙', category: 'collection', title: 'Primo Raro',        description: 'Ottieni il tuo primo item RARO'),
    AchievementDef(id: 'first_epic',    emoji: '💜', category: 'collection', title: 'Primo Epico',       description: 'Ottieni il tuo primo item EPICO'),
    AchievementDef(id: 'first_legendary', emoji: '💛', category: 'collection', title: 'Primo Leggendario', description: 'Ottieni il tuo primo item LEGGENDARIO', badgeTitle: 'Cacciatore'),
    AchievementDef(id: 'first_mythic',  emoji: '🟠', category: 'collection', title: 'Primo Mitico',     description: 'Ottieni il tuo primo item MITICO', badgeTitle: 'Eletto'),
    AchievementDef(id: 'first_divine',  emoji: '💗', category: 'collection', title: 'Primo Divino',     description: 'Ottieni il tuo primo item DIVINO', badgeTitle: 'Divino'),
    AchievementDef(id: 'first_secret',  emoji: '🩵', category: 'collection', title: 'Primo Segreto',    description: 'Ottieni il tuo primo item SEGRETO', badgeTitle: 'Scelto'),
    AchievementDef(id: 'first_cosmic',  emoji: '⭐', category: 'collection', title: 'COSMICO!',          description: 'Ottieni un item COSMICO',            badgeTitle: '★ Cosmico ★'),
    AchievementDef(id: 'rares_10',      emoji: '🔮', category: 'collection', title: 'Fortuna sfacciata', description: 'Trova 10 item rari+'),
    AchievementDef(id: 'rares_100',     emoji: '✨', category: 'collection', title: 'Blessed',           description: 'Trova 100 item rari+',              badgeTitle: 'Blessed'),
    // Mutation
    AchievementDef(id: 'first_mutation', emoji: '🧬', category: 'collection', title: 'Mutante!',        description: 'Ottieni il tuo primo item mutato'),
    AchievementDef(id: 'first_void',    emoji: '🕳️', category: 'collection', title: 'Into the Void',    description: 'Ottieni una mutazione VOID',         badgeTitle: 'Void Walker'),
    AchievementDef(id: 'first_galaxy',  emoji: '🌌', category: 'collection', title: 'Galassia',         description: 'Ottieni una mutazione GALAXY'),
    // Economy
    AchievementDef(id: 'first_sell',    emoji: '💰', category: 'economy', title: 'Prima Vendita',       description: 'Vendi il tuo primo item'),
    AchievementDef(id: 'sold_100',      emoji: '🤑', category: 'economy', title: 'Mercante',            description: 'Vendi 100 item'),
    AchievementDef(id: 'sold_10000',    emoji: '🏦', category: 'economy', title: 'Magnate',             description: 'Vendi 10.000 item',                  badgeTitle: 'Magnate'),
    AchievementDef(id: 'dust_1000',     emoji: '🌫️', category: 'economy', title: 'Polvere d\'oro',     description: 'Accumula 1.000 Dust'),
    AchievementDef(id: 'dust_100000',   emoji: '🌪️', category: 'economy', title: 'Tempesta di Polvere', description: 'Accumula 100.000 Dust',             badgeTitle: 'Alchimista'),
    AchievementDef(id: 'first_craft',   emoji: '⚗️', category: 'economy', title: 'Alchimista',         description: 'Esegui la tua prima fusione'),
    AchievementDef(id: 'first_trade',   emoji: '🤝', category: 'economy', title: 'Trader',              description: 'Completa il tuo primo trade'),
    AchievementDef(id: 'rich_1m',       emoji: '💎', category: 'economy', title: 'Milionario',          description: 'Guadagna 1.000.000 monete in totale', badgeTitle: 'Milionario'),
    // Progression
    AchievementDef(id: 'level_10',      emoji: '⬆️', category: 'special', title: 'Livello 10',          description: 'Raggiungi il livello 10'),
    AchievementDef(id: 'level_50',      emoji: '🚀', category: 'special', title: 'Livello 50',          description: 'Raggiungi il livello 50',             badgeTitle: 'Esperto'),
    AchievementDef(id: 'level_100',     emoji: '🌟', category: 'special', title: 'Centurione',          description: 'Raggiungi il livello 100',            badgeTitle: 'Centurione'),
    AchievementDef(id: 'prestige_1',    emoji: '♻️', category: 'special', title: 'Rinato',              description: 'Esegui il tuo primo Prestige',       badgeTitle: 'Rinato'),
    AchievementDef(id: 'prestige_5',    emoji: '🔱', category: 'special', title: 'Asceso',              description: 'Raggiungi Prestige 5',               badgeTitle: 'Asceso'),
    AchievementDef(id: 'secret_container', emoji: '👻', category: 'special', title: 'Ombra',           description: 'Trova un Container Ombra',           badgeTitle: 'Ombra'),
  ];

  static AchievementDef? find(String id) {
    try { return all.firstWhere((a) => a.id == id); } catch (_) { return null; }
  }
}
