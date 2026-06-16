import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_model.dart';
import '../models/player_model.dart';
import 'achievement_service.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'iap_service.dart';
import 'inventory_service.dart';
import 'meta_service.dart';
import 'player_service.dart';
import 'rewarded_ad_service.dart';
import 'rng_service.dart';
import 'tycoon_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  await Hive.initFlutter();

  // Register Hive adapters (idempotent)
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ItemModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlayerModelAdapter());

  // DatabaseService — layer Firestore
  sl.registerSingleton<DatabaseService>(DatabaseService());

  // AuthService
  final authService = AuthService();
  await authService.init();
  sl.registerSingleton<AuthService>(authService);

  // PlayerService — inizializzato qui senza utente; sarà re-init dopo login
  final playerService = PlayerService();
  await playerService.init(uid: authService.currentUid);
  sl.registerSingleton<PlayerService>(playerService);

  final inventoryService = InventoryService(playerService);
  await inventoryService.init(uid: authService.currentUid);
  sl.registerSingleton<InventoryService>(inventoryService);

  // TycoonService — motore idle (profitti, guadagni offline, strutture)
  final tycoonService = TycoonService();
  await tycoonService.init(uid: authService.currentUid);
  sl.registerSingleton<TycoonService>(tycoonService);

  sl.registerSingleton<RngService>(RngService());
  sl.registerSingleton<RewardedAdService>(RewardedAdService());

  sl.registerSingleton<MetaService>(MetaService());
  sl.registerSingleton<AchievementService>(AchievementService());

  // IapService — inizializzato e pronto all'uso (non bloccante su web/desktop)
  final iapService = IapService(playerService);
  sl.registerSingleton<IapService>(iapService);
  try {
    await iapService.init();
  } catch (e) {
    debugPrint('⚠️ IAP init saltato (piattaforma non supportata): $e');
  }
}

/// Chiamato dopo login/register per ricaricare i dati del nuovo utente
Future<void> reloadUserServices(String uid) async {
  final ps = sl<PlayerService>();
  await ps.init(uid: uid);
  final inv = sl<InventoryService>();
  await inv.init(uid: uid);
  await sl<TycoonService>().init(uid: uid);
  await sl<MetaService>().init(uid: uid);
}

/// Elimina account + TUTTI i dati, cloud e locali (GDPR / requisito store).
/// Dopo questa chiamata l'app va riavviata: i box locali sono stati rimossi.
Future<AccountDeletionResult> deleteAccountAndAllData() async {
  final auth = sl<AuthService>();
  final uid = auth.currentUid;
  final result = await auth.deleteAccount();

  // Pulizia dei box Hive locali (per-utente e ospite) — best effort.
  final boxes = <String>{
    'tycoon_empire', 'tycoon_local', 'player_local', 'inventory_local',
    if (uid != null) 'player_$uid',
    if (uid != null) 'inventory_$uid',
    if (uid != null) 'tycoon_$uid',
  };
  for (final name in boxes) {
    try {
      await Hive.deleteBoxFromDisk(name);
    } catch (_) {}
  }
  return result;
}
