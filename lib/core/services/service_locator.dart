import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_model.dart';
import '../models/player_model.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'iap_service.dart';
import 'inventory_service.dart';
import 'player_service.dart';
import 'rng_service.dart';

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

  sl.registerSingleton<RngService>(RngService());

  // IapService — inizializzato e pronto all'uso
  final iapService = IapService(playerService);
  sl.registerSingleton<IapService>(iapService);
  await iapService.init();
}

/// Chiamato dopo login/register per ricaricare i dati del nuovo utente
Future<void> reloadUserServices(String uid) async {
  final ps = sl<PlayerService>();
  await ps.init(uid: uid);
  final inv = sl<InventoryService>();
  await inv.init(uid: uid);
}
