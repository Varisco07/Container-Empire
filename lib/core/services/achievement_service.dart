import '../models/achievement_def.dart';
import '../models/item_model.dart';
import '../models/player_model.dart';
import 'meta_service.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final MetaService _meta = MetaService();

  /// Chiamato dopo ogni apertura container. Ritorna achievement appena sbloccati.
  Future<List<AchievementDef>> onContainerOpened({
    required PlayerModel player,
    required ItemModel item,
    required bool isBatch,
    required int batchSize,
  }) async {
    final unlocked = <AchievementDef>[];

    Future<void> check(String id) async {
      final result = await _meta.unlockAchievement(id);
      unlocked.addAll(result);
    }

    // Record item obtained
    await _meta.recordItemObtained(item.name);

    // Opening achievements
    if (player.totalContainersOpened >= 1) await check('first_open');
    if (player.totalContainersOpened >= 10) await check('opens_10');
    if (player.totalContainersOpened >= 100) await check('opens_100');
    if (player.totalContainersOpened >= 1000) await check('opens_1000');
    if (player.totalContainersOpened >= 10000) await check('opens_10000');
    if (isBatch && batchSize >= 10) await check('batch_10');
    if (player.totalContainersOpened == 1 && item.containerId == 'free') await check('first_free');

    // Rarity achievements
    final r = item.rarityKey;
    if (r == 'rare' || item.rarity.index >= 2) await check('first_rare');
    if (item.rarity.index >= 3) await check('first_epic');
    if (item.rarity.index >= 4) await check('first_legendary');
    if (item.rarity.index >= 5) await check('first_mythic');
    if (item.rarity.index >= 6) await check('first_divine');
    if (item.rarity.index >= 7) await check('first_secret');
    if (r == 'cosmic') await check('first_cosmic');
    if (player.totalRaresFound >= 10) await check('rares_10');
    if (player.totalRaresFound >= 100) await check('rares_100');

    // Mutation achievements
    if (item.mutationKey != 'none') await check('first_mutation');
    if (item.mutationKey == 'voidMutation') await check('first_void');
    if (item.mutationKey == 'galaxy') await check('first_galaxy');

    return unlocked;
  }

  Future<List<AchievementDef>> onItemSold({required PlayerModel player}) async {
    final unlocked = <AchievementDef>[];
    Future<void> check(String id) async { unlocked.addAll(await _meta.unlockAchievement(id)); }
    if (player.totalItemsSold >= 1) await check('first_sell');
    if (player.totalItemsSold >= 100) await check('sold_100');
    if (player.totalItemsSold >= 10000) await check('sold_10000');
    if (player.totalEarned >= 1000000) await check('rich_1m');
    return unlocked;
  }

  Future<List<AchievementDef>> onLevelUp({required PlayerModel player}) async {
    final unlocked = <AchievementDef>[];
    Future<void> check(String id) async { unlocked.addAll(await _meta.unlockAchievement(id)); }
    if (player.level >= 10) await check('level_10');
    if (player.level >= 50) await check('level_50');
    if (player.level >= 100) await check('level_100');
    return unlocked;
  }

  Future<List<AchievementDef>> onPrestige({required PlayerModel player}) async {
    final unlocked = <AchievementDef>[];
    Future<void> check(String id) async { unlocked.addAll(await _meta.unlockAchievement(id)); }
    if (player.prestigeLevel >= 1) await check('prestige_1');
    if (player.prestigeLevel >= 5) await check('prestige_5');
    return unlocked;
  }

  Future<List<AchievementDef>> onDustAccumulated({required double totalDust}) async {
    final unlocked = <AchievementDef>[];
    Future<void> check(String id) async { unlocked.addAll(await _meta.unlockAchievement(id)); }
    if (totalDust >= 1000) await check('dust_1000');
    if (totalDust >= 100000) await check('dust_100000');
    return unlocked;
  }

  Future<List<AchievementDef>> onCraftPerformed() async =>
      await _meta.unlockAchievement('first_craft');

  Future<List<AchievementDef>> onTradeCompleted() async =>
      await _meta.unlockAchievement('first_trade');

  Future<List<AchievementDef>> onSecretContainerFound() async =>
      await _meta.unlockAchievement('secret_container');
}
