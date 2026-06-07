enum Rarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
  divine,
  secret;

  String get displayName {
    switch (this) {
      case Rarity.common: return 'COMUNE';
      case Rarity.uncommon: return 'NON COMUNE';
      case Rarity.rare: return 'RARO';
      case Rarity.epic: return 'EPICO';
      case Rarity.legendary: return 'LEGGENDARIO';
      case Rarity.mythic: return 'MITICO';
      case Rarity.divine: return 'DIVINO';
      case Rarity.secret: return 'SEGRETO';
    }
  }

  // Base drop rate (%)
  double get baseRate {
    switch (this) {
      case Rarity.common: return 70.00;
      case Rarity.uncommon: return 20.00;
      case Rarity.rare: return 7.00;
      case Rarity.epic: return 2.00;
      case Rarity.legendary: return 0.80;
      case Rarity.mythic: return 0.15;
      case Rarity.divine: return 0.04;
      case Rarity.secret: return 0.01;
    }
  }

  double get valueMultiplier {
    switch (this) {
      case Rarity.common: return 1.0;
      case Rarity.uncommon: return 3.0;
      case Rarity.rare: return 8.0;      // was 10
      case Rarity.epic: return 22.0;     // was 35
      case Rarity.legendary: return 80.0;  // was 150
      case Rarity.mythic: return 250.0;  // was 600
      case Rarity.divine: return 600.0;  // was 3000
      case Rarity.secret: return 2000.0; // was 15000
    }
  }

  int get sortOrder => index;
}

enum Mutation {
  none,
  golden,
  diamond,
  radioactive,
  galaxy,
  voidMutation;

  String get displayName {
    switch (this) {
      case Mutation.none: return '';
      case Mutation.golden: return 'GOLDEN';
      case Mutation.diamond: return 'DIAMOND';
      case Mutation.radioactive: return 'RADIOACTIVE';
      case Mutation.galaxy: return 'GALAXY';
      case Mutation.voidMutation: return 'VOID';
    }
  }

  // Drop rate out of total items (%)
  double get dropRate {
    switch (this) {
      case Mutation.none: return 0;
      case Mutation.golden: return 5.0;
      case Mutation.diamond: return 2.0;
      case Mutation.radioactive: return 0.8;
      case Mutation.galaxy: return 0.3;
      case Mutation.voidMutation: return 0.1;
    }
  }

  double get valueMultiplier {
    switch (this) {
      case Mutation.none: return 1.0;
      case Mutation.golden: return 1.5;   // was 3
      case Mutation.diamond: return 3.0;  // was 10
      case Mutation.radioactive: return 6.0;  // was 25
      case Mutation.galaxy: return 15.0;  // was 75
      case Mutation.voidMutation: return 40.0; // was 250
    }
  }
}
