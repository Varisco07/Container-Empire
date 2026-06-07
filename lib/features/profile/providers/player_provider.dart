import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/player_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/service_locator.dart';

// Reactive player notifier
class PlayerNotifier extends StateNotifier<AsyncValue<PlayerModel>> {
  PlayerNotifier() : super(const AsyncLoading()) {
    _load();
  }

  PlayerService get _svc => sl<PlayerService>();

  Future<void> _load() async {
    try {
      // Use the correct uid so we don't create with wrong defaults
      final uid = sl<AuthService>().currentUid ?? 'local';
      final account = sl<AuthService>().currentAccount;
      final username = account?.username ?? 'Player';
      final p = await _svc.loadOrCreate(username: username, uid: uid);
      // Apply any upgrade effects on load
      await _svc.applyUpgradeEffects();
      state = AsyncData(_svc.localPlayer ?? p);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> refresh() async {
    final p = _svc.localPlayer;
    if (p != null) state = AsyncData(p);
  }
}

final playerNotifierProvider =
    StateNotifierProvider<PlayerNotifier, AsyncValue<PlayerModel>>(
  (ref) => PlayerNotifier(),
);

// Alias per compatibilità con CurrencyBar
final playerProvider = playerNotifierProvider;
