import 'empire_building.dart' show fmtNum;

/// ─────────────────────────────────────────────────────────────────────────────
/// BATTLE PASS — stagione con traccia gratuita + premium.
/// Si avanza guadagnando Pass XP (aprendo container, incassando profitti, tap).
/// ─────────────────────────────────────────────────────────────────────────────

const String seasonName = 'STAGIONE 1 — GENESI';
const int xpPerTier = 100;
const int passTiers = 30;

enum RewardType { coins, gems, cosmetic }

class PassReward {
  final RewardType type;
  final double amount;
  final String label;
  final String emoji;
  const PassReward(this.type, this.amount, this.label, this.emoji);
}

class BattlePassTier {
  final int tier;
  final PassReward free;
  final PassReward premium;
  const BattlePassTier({required this.tier, required this.free, required this.premium});
}

/// Genera le 30 tier della stagione con ricompense crescenti.
List<BattlePassTier> buildSeasonTiers() {
  return List.generate(passTiers, (i) {
    final tier = i + 1;

    // Traccia GRATUITA: coins crescenti, gemme ogni 5 livelli.
    final PassReward free = (tier % 5 == 0)
        ? PassReward(RewardType.gems, 10, '10 Gemme', '💎')
        : PassReward(RewardType.coins, 1000.0 * tier * tier, '${fmtNum(1000.0 * tier * tier)} Coins', '🪙');

    // Traccia PREMIUM: ricompense molto più ricche + skin ai traguardi.
    final PassReward premium;
    if (tier % 10 == 0) {
      premium = PassReward(RewardType.cosmetic, 0, 'Skin Container Esclusiva', '🎨');
    } else if (tier % 3 == 0) {
      premium = PassReward(RewardType.gems, 25.0 + tier, '${(25 + tier)} Gemme', '💎');
    } else {
      premium = PassReward(RewardType.coins, 6000.0 * tier * tier, '${fmtNum(6000.0 * tier * tier)} Coins', '🪙');
    }

    return BattlePassTier(tier: tier, free: free, premium: premium);
  });
}
