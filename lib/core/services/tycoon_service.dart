import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/empire_building.dart';
import 'player_service.dart';
import 'service_locator.dart';

class AscensionResult {
  final bool success;
  final int gained;
  final int total;
  final double newMultiplier;
  const AscensionResult({
    required this.success,
    required this.gained,
    required this.total,
    required this.newMultiplier,
  });
}

/// ─────────────────────────────────────────────────────────────────────────────
/// TYCOON SERVICE — motore idle: profitti continui, guadagni offline, upgrade,
/// ASCENSION (prestige con moltiplicatore permanente), TURBO (boost ×2), tap.
///
/// Stato in un box Hive *non tipizzato* separato (tycoon_<uid>): solo primitivi,
/// nessun adapter/.g.dart toccato.
/// ─────────────────────────────────────────────────────────────────────────────
class TycoonService {
  Box? _box;
  final Map<String, int> _levels = {};
  double _uncollected = 0;
  double _offlinePending = 0;
  int _ascensionPoints = 0;
  int _boostUntilMs = 0;

  /// Tetto guadagni offline: 8h (estendibile con rewarded ad → 24h).
  static const int offlineCapSeconds = 8 * 3600;

  /// Profitto/sec minimo per poter ascendere.
  static const double ascensionThreshold = 5000;

  /// Ogni punto Ascension = +2% profitti globali, per sempre.
  static const double ascensionBonusPerPoint = 0.02;

  /// TURBO: moltiplicatore e durata di default.
  static const double boostMultiplier = 2.0;
  static const int boostMinutes = 2;

  String _boxName(String? uid) => uid != null ? 'tycoon_$uid' : 'tycoon_local';

  Future<void> init({String? uid}) async {
    final name = _boxName(uid);
    _box = Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);

    _levels.clear();
    for (final b in empireBuildings) {
      _levels[b.id] = (_box!.get('lvl_${b.id}', defaultValue: 0) as num).toInt();
    }
    _uncollected = (_box!.get('uncollected', defaultValue: 0.0) as num).toDouble();
    _ascensionPoints = (_box!.get('ascension', defaultValue: 0) as num).toInt();
    _boostUntilMs = (_box!.get('boostUntil', defaultValue: 0) as num).toInt();

    // PREVIEW_EMPIRE (dart-define, default off): impero dimostrativo per screenshot.
    if (const bool.fromEnvironment('PREVIEW_EMPIRE') && baseIncomePerSec == 0) {
      const seed = {'depot': 9, 'factory': 5, 'bank': 2};
      for (final e in seed.entries) {
        _levels[e.key] = e.value;
        await _box?.put('lvl_${e.key}', e.value);
      }
    }

    // ── Guadagni offline (no boost: il boost a tempo è già scaduto) ────────────
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastMs = (_box!.get('lastSeen', defaultValue: nowMs) as num).toInt();
    final elapsedSec = ((nowMs - lastMs) ~/ 1000).clamp(0, offlineCapSeconds);
    _offlinePending = idleIncomePerSec * elapsedSec;
    _uncollected += _offlinePending;

    await _persist();
  }

  // ── Moltiplicatori ──────────────────────────────────────────────────────────

  /// Moltiplicatore permanente da Ascension.
  double get globalMultiplier => 1 + _ascensionPoints * ascensionBonusPerPoint;

  int get ascensionPoints => _ascensionPoints;

  bool get boostActive => DateTime.now().millisecondsSinceEpoch < _boostUntilMs;

  Duration get boostRemaining {
    final ms = _boostUntilMs - DateTime.now().millisecondsSinceEpoch;
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  // ── Profitti ──────────────────────────────────────────────────────────────

  /// Somma grezza dei profitti degli edifici (senza moltiplicatori).
  double get baseIncomePerSec {
    double sum = 0;
    for (final b in empireBuildings) {
      sum += b.incomeAt(_levels[b.id] ?? 0);
    }
    return sum;
  }

  /// Profitto/sec usato per l'accumulo offline e per il rank (Ascension, no boost).
  double get idleIncomePerSec => baseIncomePerSec * globalMultiplier;

  /// Profitto/sec effettivo mostrato e accumulato dal vivo (include TURBO).
  double get totalIncomePerSec =>
      idleIncomePerSec * (boostActive ? boostMultiplier : 1.0);

  double get uncollected => _uncollected;

  EmpireRank get rank => empireRankFor(idleIncomePerSec);

  // ── Edifici ─────────────────────────────────────────────────────────────────

  int level(String id) => _levels[id] ?? 0;

  bool isUnlocked(EmpireBuilding b) {
    final idx = empireBuildings.indexOf(b);
    if (idx <= 0) return true;
    return (_levels[empireBuildings[idx - 1].id] ?? 0) >= 1;
  }

  double upgradeCost(EmpireBuilding b) => b.costAt(_levels[b.id] ?? 0);

  Future<bool> buyUpgrade(EmpireBuilding b) async {
    final ps = sl<PlayerService>();
    final player = ps.localPlayer;
    if (player == null) return false;
    final cost = upgradeCost(b);
    if (player.coins < cost) return false;

    await ps.spendCoins(cost);
    final newLevel = (_levels[b.id] ?? 0) + 1;
    _levels[b.id] = newLevel;
    await _box?.put('lvl_${b.id}', newLevel);
    return true;
  }

  // ── Tick / collect ──────────────────────────────────────────────────────────

  void tick(double seconds) {
    _uncollected += totalIncomePerSec * seconds;
  }

  /// Aggiunge profitti bonus ai non incassati (es. raddoppio offline da rewarded ad).
  void addBonus(double v) {
    if (v > 0) _uncollected += v;
  }

  /// Tap manuale sulla città: profitto istantaneo (~½ secondo di rendita + base).
  double tapEarn() {
    final value = baseIncomePerSec * globalMultiplier * 0.5 + 5 * globalMultiplier;
    _uncollected += value;
    return value;
  }

  Future<double> collect() async {
    final amount = _uncollected;
    if (amount <= 0) return 0;
    await sl<PlayerService>().addCoins(amount);
    _uncollected = 0;
    await _persist();
    return amount;
  }

  double consumeOfflineEarnings() {
    final v = _offlinePending;
    _offlinePending = 0;
    return v;
  }

  // ── TURBO ─────────────────────────────────────────────────────────────────

  void activateBoost({int minutes = boostMinutes}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Estende il boost se già attivo.
    final base = boostActive ? _boostUntilMs : now;
    _boostUntilMs = base + minutes * 60 * 1000;
    _box?.put('boostUntil', _boostUntilMs);
  }

  // ── ASCENSION (prestige) ────────────────────────────────────────────────────

  /// Punti ottenibili ascendendo ora (cresce con la dimensione dell'impero).
  int get pendingAscensionPoints {
    final inc = baseIncomePerSec;
    if (inc < ascensionThreshold) return 0;
    return sqrt(inc / 50).floor();
  }

  bool get canAscend => pendingAscensionPoints >= 1;

  Future<AscensionResult> ascend() async {
    final gained = pendingAscensionPoints;
    if (gained < 1) {
      return AscensionResult(
        success: false,
        gained: 0,
        total: _ascensionPoints,
        newMultiplier: globalMultiplier,
      );
    }
    _ascensionPoints += gained;
    for (final b in empireBuildings) {
      _levels[b.id] = 0;
      await _box?.put('lvl_${b.id}', 0);
    }
    _uncollected = 0;
    await _box?.put('ascension', _ascensionPoints);
    await _persist();
    return AscensionResult(
      success: true,
      gained: gained,
      total: _ascensionPoints,
      newMultiplier: globalMultiplier,
    );
  }

  // ── Persistenza ─────────────────────────────────────────────────────────────

  Future<void> persist() => _persist();

  Future<void> _persist() async {
    final box = _box;
    if (box == null) return;
    await box.put('uncollected', _uncollected);
    await box.put('lastSeen', DateTime.now().millisecondsSinceEpoch);
  }
}
