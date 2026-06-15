import 'package:hive_flutter/hive_flutter.dart';
import '../models/battle_pass.dart';
import 'player_service.dart';
import 'service_locator.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// BATTLE PASS SERVICE — XP stagionale, traccia free/premium, claim, acquisto.
/// Stato in box Hive non tipizzato (battlepass_<uid>): solo primitivi.
/// Premium sbloccabile con gemme (le gemme si comprano via IAP → monetizzazione).
/// ─────────────────────────────────────────────────────────────────────────────
class BattlePassService {
  Box? _box;
  int _xp = 0;
  bool _premium = false;
  final Set<int> _claimedFree = {};
  final Set<int> _claimedPremium = {};
  final List<String> _ownedCosmetics = [];

  final List<BattlePassTier> tiers = buildSeasonTiers();

  static const int premiumGemCost = 500;

  String _boxName(String? uid) => uid != null ? 'battlepass_$uid' : 'battlepass_local';

  Future<void> init({String? uid}) async {
    final name = _boxName(uid);
    _box = Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
    _xp = (_box!.get('xp', defaultValue: 0) as num).toInt();
    _premium = _box!.get('premium', defaultValue: false) as bool;
    _claimedFree
      ..clear()
      ..addAll(((_box!.get('claimedFree', defaultValue: <int>[]) as List).cast<int>()));
    _claimedPremium
      ..clear()
      ..addAll(((_box!.get('claimedPremium', defaultValue: <int>[]) as List).cast<int>()));
    _ownedCosmetics
      ..clear()
      ..addAll(((_box!.get('cosmetics', defaultValue: <String>[]) as List).cast<String>()));
  }

  // ── Letture ─────────────────────────────────────────────────────────────────

  int get xp => _xp;
  bool get premiumOwned => _premium;

  /// Tier attualmente sbloccata (0..passTiers).
  int get currentTier => (_xp ~/ xpPerTier).clamp(0, passTiers);

  /// Progresso 0..1 verso la prossima tier.
  double get tierProgress => currentTier >= passTiers ? 1.0 : (_xp % xpPerTier) / xpPerTier;

  bool isUnlocked(int tier) => currentTier >= tier;
  bool freeClaimed(int tier) => _claimedFree.contains(tier);
  bool premiumClaimed(int tier) => _claimedPremium.contains(tier);

  bool canClaimFree(int tier) => isUnlocked(tier) && !freeClaimed(tier);
  bool canClaimPremium(int tier) => _premium && isUnlocked(tier) && !premiumClaimed(tier);

  /// Numero di ricompense pronte da riscuotere (per il badge).
  int get claimableCount {
    int n = 0;
    for (final t in tiers) {
      if (canClaimFree(t.tier)) n++;
      if (canClaimPremium(t.tier)) n++;
    }
    return n;
  }

  List<String> get ownedCosmetics => List.unmodifiable(_ownedCosmetics);

  // ── XP ────────────────────────────────────────────────────────────────────

  void addXp(int v) {
    if (v <= 0) return;
    _xp += v;
    _box?.put('xp', _xp);
  }

  // ── Claim ─────────────────────────────────────────────────────────────────

  Future<void> claimFree(int tier) async {
    if (!canClaimFree(tier)) return;
    await _grant(tiers[tier - 1].free);
    _claimedFree.add(tier);
    await _box?.put('claimedFree', _claimedFree.toList());
  }

  Future<void> claimPremium(int tier) async {
    if (!canClaimPremium(tier)) return;
    await _grant(tiers[tier - 1].premium);
    _claimedPremium.add(tier);
    await _box?.put('claimedPremium', _claimedPremium.toList());
  }

  /// Riscuote in blocco tutto il riscuotibile. Ritorna quante ne ha date.
  Future<int> claimAll() async {
    int n = 0;
    for (final t in tiers) {
      if (canClaimFree(t.tier)) {
        await claimFree(t.tier);
        n++;
      }
      if (canClaimPremium(t.tier)) {
        await claimPremium(t.tier);
        n++;
      }
    }
    return n;
  }

  Future<void> _grant(PassReward r) async {
    final ps = sl<PlayerService>();
    switch (r.type) {
      case RewardType.coins:
        await ps.addCoins(r.amount);
      case RewardType.gems:
        await ps.addGems(r.amount.toInt());
      case RewardType.cosmetic:
        if (!_ownedCosmetics.contains(r.label)) {
          _ownedCosmetics.add(r.label);
          await _box?.put('cosmetics', _ownedCosmetics);
        }
    }
  }

  // ── Acquisto premium (con gemme) ────────────────────────────────────────────

  Future<bool> buyPremium() async {
    if (_premium) return true;
    final ok = await sl<PlayerService>().spendGems(premiumGemCost);
    if (!ok) return false;
    _premium = true;
    await _box?.put('premium', true);
    return true;
  }
}
