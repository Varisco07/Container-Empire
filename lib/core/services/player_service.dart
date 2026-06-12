import 'package:hive_flutter/hive_flutter.dart';
import '../models/player_model.dart';
import 'database_service.dart';

class LevelUpResult {
  final bool didLevelUp;
  final int newLevel;
  final double coinsBonus;
  final int gemsBonus;
  const LevelUpResult({
    required this.didLevelUp,
    required this.newLevel,
    required this.coinsBonus,
    required this.gemsBonus,
  });
}

class DailyBonusResult {
  final bool success;
  final double coins;
  final int gems;
  final int streak;
  const DailyBonusResult({
    required this.success,
    required this.coins,
    required this.gems,
    required this.streak,
  });
}

class PlayerService {
  Box<PlayerModel>? _box;
  String? _uid;
  final DatabaseService _db = DatabaseService();

  String _boxName(String? uid) => uid != null ? 'player_$uid' : 'player_local';

  Future<void> init({String? uid}) async {
    _uid = uid;
    final name = _boxName(uid);
    if (!Hive.isBoxOpen(name)) {
      _box = await Hive.openBox<PlayerModel>(name);
    } else {
      _box = Hive.box<PlayerModel>(name);
    }

    // Sincronizza da Firestore se connesso
    if (uid != null) {
      try {
        final remote = await _db.loadPlayer(uid);
        if (remote != null) {
          await _box!.put(0, remote);
        }
      } catch (_) {
        // Nessuna connessione — usa Hive locale
      }
    }
  }

  PlayerModel? get localPlayer {
    final box = _box;
    if (box == null || box.isEmpty) return null;
    return box.getAt(0);
  }

  Future<PlayerModel> loadOrCreate({String username = 'Player', String uid = 'local'}) async {
    final box = _box;
    if (box != null && box.isNotEmpty) {
      return box.getAt(0)!;
    }
    // New player — start with 300 coins (enough for 3 basic containers)
    final newPlayer = PlayerModel(uid: uid, username: username, coins: 300, gems: 0);
    await savePlayer(newPlayer);
    return newPlayer;
  }

  Future<void> savePlayer(PlayerModel player) async {
    // 1. Salva locale (immediato, sempre disponibile)
    await _box?.put(0, player);
    // 2. Sincronizza su Firestore (asincrono, fallisce silenziosamente offline)
    if (_uid != null) {
      _db.savePlayer(_uid!, player).catchError((_) {});
      // 3. Aggiorna classifica globale (fire & forget)
      _db.updateLeaderboard(player).catchError((_) {});
    }
  }

  Future<void> addCoins(double amount) async {
    final player = localPlayer;
    if (player == null) return;
    player.coins += amount;
    player.totalEarned += amount;
    await savePlayer(player);
  }

  Future<void> spendCoins(double amount) async {
    final player = localPlayer;
    if (player == null) return;
    player.coins -= amount;
    await savePlayer(player);
  }

  /// Returns LevelUpResult to tell caller if a level-up happened
  Future<LevelUpResult> addXp(double xp) async {
    final player = localPlayer;
    if (player == null) return const LevelUpResult(didLevelUp: false, newLevel: 1, coinsBonus: 0, gemsBonus: 0);

    player.xp += xp;
    bool leveled = false;
    double coinBonus = 0;
    int gemBonus = 0;

    while (player.xp >= player.xpRequired) {
      player.xp -= player.xpRequired;
      player.level++;
      final reward = _onLevelUp(player);
      coinBonus += reward.$1;
      gemBonus += reward.$2;
      leveled = true;
    }

    await savePlayer(player);
    return LevelUpResult(
      didLevelUp: leveled,
      newLevel: player.level,
      coinsBonus: coinBonus,
      gemsBonus: gemBonus,
    );
  }

  (double, int) _onLevelUp(PlayerModel player) {
    final coinReward = player.level * 500.0;
    final gemReward = player.level >= 10 ? 5 : 2;
    player.coins += coinReward;
    player.gems += gemReward;
    return (coinReward, gemReward);
  }

  Future<bool> spendGems(int amount) async {
    final player = localPlayer;
    if (player == null || player.gems < amount) return false;
    player.gems -= amount;
    await savePlayer(player);
    return true;
  }

  Future<void> addGems(int amount) async {
    final player = localPlayer;
    if (player == null) return;
    player.gems += amount;
    await savePlayer(player);
  }

  Future<void> activateVip() async {
    final player = localPlayer;
    if (player == null) return;
    player.isVip = true;
    await savePlayer(player);
  }

  Future<LevelUpResult> incrementContainersOpened() async {
    final player = localPlayer;
    if (player == null) return const LevelUpResult(didLevelUp: false, newLevel: 1, coinsBonus: 0, gemsBonus: 0);
    player.totalContainersOpened++;
    await savePlayer(player);
    return addXp(10 + player.level.toDouble());
  }

  Future<void> incrementItemsSold() async {
    final player = localPlayer;
    if (player == null) return;
    player.totalItemsSold++;
    await savePlayer(player);
  }

  Future<void> incrementRaresFound() async {
    final player = localPlayer;
    if (player == null) return;
    player.totalRaresFound++;
    await savePlayer(player);
  }

  // ── Pity system ───────────────────────────────────────────────────────────

  Future<bool> incrementPity() async {
    final player = localPlayer;
    if (player == null) return false;
    player.pityCounter++;
    await savePlayer(player);
    return player.pityReady;
  }

  Future<void> resetPity() async {
    final player = localPlayer;
    if (player == null) return;
    player.pityCounter = 0;
    await savePlayer(player);
  }

  // ── Free container ────────────────────────────────────────────────────────

  Future<void> markFreeContainerClaimed() async {
    final player = localPlayer;
    if (player == null) return;
    player.lastFreeContainerAt = DateTime.now();
    await savePlayer(player);
  }

  // ── Daily login bonus ─────────────────────────────────────────────────────

  Future<DailyBonusResult> claimDailyBonus() async {
    final player = localPlayer;
    if (player == null || !player.canClaimDailyBonus) {
      return const DailyBonusResult(success: false, coins: 0, gems: 0, streak: 0);
    }

    // Check if streak is still alive (< 48h gap)
    final diff = DateTime.now().difference(player.lastLoginAt);
    if (diff.inHours >= 48) {
      player.dailyLoginStreak = 0; // reset streak
    }

    player.dailyLoginStreak++;
    player.lastLoginAt = DateTime.now();

    // Reward scales with streak
    final streak = player.dailyLoginStreak;
    double coinsBonus = 200 + streak * 100.0;
    int gemsBonus = 1 + (streak ~/ 5); // +1 gem every 5 days
    if (streak % 7 == 0) {
      // Week bonus
      coinsBonus *= 3;
      gemsBonus += 10;
    }

    player.coins += coinsBonus;
    player.gems += gemsBonus;
    await savePlayer(player);

    return DailyBonusResult(
      success: true,
      coins: coinsBonus,
      gems: gemsBonus,
      streak: streak,
    );
  }

  // ── Upgrade helpers ───────────────────────────────────────────────────────

  /// Apply all upgrade effects to the player model based on stored levels
  Future<void> applyUpgradeEffects() async {
    final player = localPlayer;
    if (player == null) return;

    player.luckBoost = 1.0 + player.luckUpgradeLevel * 0.15 + player.prestigeLuckBonus;
    player.valueBoost = 1.0 + player.valueUpgradeLevel * 0.20;
    player.inventorySlots = 50 + player.slotsUpgradeLevel * 25;
    player.mutationBoost = 1.0 + player.mutationUpgradeLevel * 0.10;

    await savePlayer(player);
  }

  // ── Prestige system ───────────────────────────────────────────────────────

  static const int prestigeMinLevel = 20;
  static const double prestigeLuckPerLevel = 0.15;

  bool get canPrestige => (localPlayer?.level ?? 0) >= prestigeMinLevel;

  Future<PrestigeResult> prestige() async {
    final player = localPlayer;
    if (player == null || player.level < prestigeMinLevel) {
      return PrestigeResult(success: false, prestigeLevel: 0, totalLuckBonus: 0);
    }

    player.prestigeLevel += 1;
    player.prestigeLuckBonus += prestigeLuckPerLevel;

    // Reset progression — keep gems and prestige data
    player.level = 1;
    player.xp = 0;
    player.coins = 500;
    player.luckUpgradeLevel = 0;
    player.valueUpgradeLevel = 0;
    player.slotsUpgradeLevel = 0;
    player.mutationUpgradeLevel = 0;
    player.autoOpenUpgradeLevel = 0;
    player.autoSellUpgradeLevel = 0;

    // Re-apply effects so luckBoost includes prestige bonus
    player.luckBoost = 1.0 + player.prestigeLuckBonus;
    player.valueBoost = 1.0;
    player.inventorySlots = 50;
    player.mutationBoost = 1.0;

    await savePlayer(player);
    return PrestigeResult(
      success: true,
      prestigeLevel: player.prestigeLevel,
      totalLuckBonus: player.prestigeLuckBonus,
    );
  }
}

class PrestigeResult {
  final bool success;
  final int prestigeLevel;
  final double totalLuckBonus;
  const PrestigeResult({
    required this.success,
    required this.prestigeLevel,
    required this.totalLuckBonus,
  });
}
