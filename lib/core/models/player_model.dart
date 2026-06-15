import 'package:hive/hive.dart';

part 'player_model.g.dart';

@HiveType(typeId: 1)
class PlayerModel extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String username;

  @HiveField(2)
  double coins;

  @HiveField(3)
  int gems;

  @HiveField(4)
  int level;

  @HiveField(5)
  double xp;

  @HiveField(6)
  int totalContainersOpened;

  @HiveField(7)
  double totalEarned;

  @HiveField(8)
  int inventorySlots;

  @HiveField(9)
  bool isVip;

  @HiveField(10)
  double luckBoost;

  @HiveField(11)
  double speedBoost;

  @HiveField(12)
  double valueBoost;

  @HiveField(13)
  bool autoOpenEnabled;

  @HiveField(14)
  bool autoSellEnabled;

  @HiveField(15)
  DateTime lastFreeContainerAt;

  // ── Upgrade levels (persisted) ────────────────────────────────────────────
  @HiveField(16)
  int luckUpgradeLevel;

  @HiveField(17)
  int valueUpgradeLevel;

  @HiveField(18)
  int slotsUpgradeLevel;

  @HiveField(19)
  int mutationUpgradeLevel;

  @HiveField(20)
  int autoOpenUpgradeLevel;

  @HiveField(21)
  int autoSellUpgradeLevel;

  // ── Daily login ───────────────────────────────────────────────────────────
  @HiveField(22)
  int dailyLoginStreak;

  @HiveField(23)
  DateTime lastLoginAt;

  // ── Pity system ───────────────────────────────────────────────────────────
  // Increases on each non-rare open; reset on rare+. At 50 → guaranteed rare
  @HiveField(24)
  int pityCounter;

  // ── Extra stats ───────────────────────────────────────────────────────────
  @HiveField(25)
  int totalItemsSold;

  @HiveField(26)
  int totalRaresFound;

  @HiveField(27)
  double mutationBoost; // extra mutation chance from upgrades

  // ── Prestige system ───────────────────────────────────────────────────────
  @HiveField(28)
  int prestigeLevel;

  @HiveField(29)
  double prestigeLuckBonus; // +0.15 luck per prestige level, permanent

  @HiveField(30)
  double dust;

  PlayerModel({
    required this.uid,
    required this.username,
    this.coins = 1000,
    this.gems = 5,
    this.level = 1,
    this.xp = 0,
    this.totalContainersOpened = 0,
    this.totalEarned = 0,
    this.inventorySlots = 50,
    this.isVip = false,
    this.luckBoost = 1.0,
    this.speedBoost = 1.0,
    this.valueBoost = 1.0,
    this.autoOpenEnabled = false,
    this.autoSellEnabled = false,
    DateTime? lastFreeContainerAt,
    this.luckUpgradeLevel = 0,
    this.valueUpgradeLevel = 0,
    this.slotsUpgradeLevel = 0,
    this.mutationUpgradeLevel = 0,
    this.autoOpenUpgradeLevel = 0,
    this.autoSellUpgradeLevel = 0,
    this.dailyLoginStreak = 0,
    DateTime? lastLoginAt,
    this.pityCounter = 0,
    this.totalItemsSold = 0,
    this.totalRaresFound = 0,
    this.mutationBoost = 1.0,
    this.prestigeLevel = 0,
    this.prestigeLuckBonus = 0.0,
    this.dust = 0,
  })  : lastFreeContainerAt = lastFreeContainerAt ?? DateTime(2000),
        lastLoginAt = lastLoginAt ?? DateTime(2000);

  // ── Computed ──────────────────────────────────────────────────────────────

  double get xpRequired => 100 * (level * 1.5).ceilToDouble();
  double get xpProgress => xp / xpRequired;

  bool get canClaimFreeContainer => true;

  Duration get freeContainerCooldown => Duration.zero;

  bool get canClaimDailyBonus {
    final diff = DateTime.now().difference(lastLoginAt);
    return diff.inHours >= 20; // 20h window to be lenient
  }

  bool get pityReady => pityCounter >= 50;
}
