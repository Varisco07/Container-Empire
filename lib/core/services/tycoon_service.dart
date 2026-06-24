import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/empire_building.dart';
import 'database_service.dart';
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

/// Un CONTRATTO DEL PORTO: obiettivo a tempo che alimenta il loop di gioco.
/// "Consegna [target] entro [deadline]" → riscatti gemme + coin bonus.
/// Il progresso si riempie con TUTTA la produzione attiva (idle + tap + TURBO).
class EmpireContract {
  final String title;
  final String emoji;
  final double target;
  final int startMs;
  final int deadlineMs;
  final double startProduced; // valore di _producedTotal alla creazione
  final int rewardGems;
  final double rewardCoins;
  bool completed;

  EmpireContract({
    required this.title,
    required this.emoji,
    required this.target,
    required this.startMs,
    required this.deadlineMs,
    required this.startProduced,
    required this.rewardGems,
    required this.rewardCoins,
    this.completed = false,
  });
}

/// ─────────────────────────────────────────────────────────────────────────────
/// TYCOON SERVICE — motore idle: profitti continui, guadagni offline, upgrade,
/// ASCENSION (prestige con moltiplicatore permanente), TURBO (boost ×2), tap.
///
/// Stato in un box Hive *non tipizzato* stabile (`tycoon_empire`): solo
/// primitivi, nessun adapter/.g.dart toccato. Se l'utente è loggato lo stato è
/// anche sincronizzato su Firestore (users/{uid}/data/empire) con merge "prendi
/// il migliore", così l'impero sopravvive a reinstall / browser puliti / cambio
/// dispositivo, esattamente come i coins.
/// ─────────────────────────────────────────────────────────────────────────────
class TycoonService {
  Box? _box;
  final DatabaseService _db = DatabaseService();
  final Random _rng = Random();
  final Map<String, int> _levels = {};
  double _uncollected = 0;
  double _offlinePending = 0;
  int _ascensionPoints = 0;
  int _boostUntilMs = 0;
  // Timestamp (ms) fino al quale i profitti sono già stati accumulati.
  int _lastSeenMs = 0;
  // Utente loggato corrente: se presente, l'impero si sincronizza su Firestore.
  String? _uid;
  // Produzione attiva totale di sessione (idle + tap + TURBO). Riempie i
  // contratti. In memoria (si azzera al riavvio: i contratti sono effimeri).
  double _producedTotal = 0;
  // Contratto del porto attivo (obiettivo a tempo). In memoria, non persistito.
  EmpireContract? _contract;

  /// Tetto guadagni offline: 8h (estendibile con rewarded ad → 24h).
  static const int offlineCapSeconds = 8 * 3600;

  /// Profitto/sec minimo per poter ascendere.
  static const double ascensionThreshold = 5000;

  /// Ogni punto Ascension = +2% profitti globali, per sempre.
  static const double ascensionBonusPerPoint = 0.02;

  /// TURBO: moltiplicatore e durata di default.
  static const double boostMultiplier = 2.0;
  static const int boostMinutes = 2;

  /// L'impero è UNO per dispositivo: vive in un box stabile e indipendente
  /// dall'account. Così non si perde MAI passando da ospite a login, da offline
  /// a online o cambiando utente. (I coins restano per-utente, sincronizzati a
  /// parte.) Prima si appoggiava a `tycoon_<uid>`: cambiando login il box era
  /// vuoto e l'impero sembrava azzerato — è il bug "offline mi cancella l'impero".
  static const String _empireBox = 'tycoon_empire';

  Future<void> init({String? uid}) async {
    _uid = uid;
    _box = Hive.isBoxOpen(_empireBox) ? Hive.box(_empireBox) : await Hive.openBox(_empireBox);

    // Migrazione una-tantum dei vecchi salvataggi per-utente verso il box
    // stabile, così nessun impero già costruito va perso al primo avvio.
    if (_isEmpty(_box!)) {
      for (final legacy in <String>{if (uid != null) 'tycoon_$uid', 'tycoon_local'}) {
        if (legacy == _empireBox || !await Hive.boxExists(legacy)) continue;
        final old = Hive.isBoxOpen(legacy) ? Hive.box(legacy) : await Hive.openBox(legacy);
        if (old.isNotEmpty) {
          for (final key in old.keys) {
            await _box!.put(key, old.get(key));
          }
          break;
        }
      }
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _levels.clear();
    for (final b in empireBuildings) {
      _levels[b.id] = (_box!.get('lvl_${b.id}', defaultValue: 0) as num).toInt();
    }
    _uncollected = (_box!.get('uncollected', defaultValue: 0.0) as num).toDouble();
    _ascensionPoints = (_box!.get('ascension', defaultValue: 0) as num).toInt();
    _boostUntilMs = (_box!.get('boostUntil', defaultValue: 0) as num).toInt();
    _lastSeenMs = (_box!.get('lastSeen', defaultValue: nowMs) as num).toInt();

    // PREVIEW_EMPIRE (dart-define, default off): impero dimostrativo per screenshot.
    if (const bool.fromEnvironment('PREVIEW_EMPIRE') && baseIncomePerSec == 0) {
      const seed = {'depot': 9, 'factory': 5, 'bank': 2};
      for (final e in seed.entries) {
        _levels[e.key] = e.value;
        await _box?.put('lvl_${e.key}', e.value);
      }
    }

    // ── Sync cloud ─────────────────────────────────────────────────────────────
    // Se loggato, fonde lo stato salvato su Firestore con quello locale tenendo
    // sempre il progresso migliore. Così un box locale azzerato (reinstall,
    // browser pulito, nuovo dispositivo, `flutter run` con profilo Chrome usa e
    // getta) NON cancella più l'impero: viene ripescato dal cloud.
    if (uid != null) {
      try {
        final cloud = await _db.loadEmpire(uid);
        if (cloud != null) _mergeFromCloud(cloud);
      } catch (_) {
        // offline / Firestore non disponibile → si prosegue col locale
      }
    }

    // ── Guadagni offline (no boost: il boost a tempo è già scaduto) ────────────
    final endMs = DateTime.now().millisecondsSinceEpoch;
    final elapsedSec = ((endMs - _lastSeenMs) ~/ 1000).clamp(0, offlineCapSeconds);
    _offlinePending = idleIncomePerSec * elapsedSec;
    _uncollected += _offlinePending;
    _lastSeenMs = endMs;

    await _persistFull();
    _pushCloud();
  }

  /// True se nel box non c'è ancora alcun impero (nessun livello salvato).
  bool _isEmpty(Box b) => empireBuildings.every((e) => b.get('lvl_${e.id}') == null);

  // ── Sync cloud (Firestore) ──────────────────────────────────────────────────

  /// Stato completo dell'impero come mappa di primitivi (per Firestore).
  Map<String, dynamic> _cloudState() => {
        for (final b in empireBuildings) 'lvl_${b.id}': _levels[b.id] ?? 0,
        'uncollected': _uncollected,
        'ascension': _ascensionPoints,
        'boostUntil': _boostUntilMs,
        'lastSeen': _lastSeenMs,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  /// Fonde lo stato cloud nel locale prendendo SEMPRE il valore più alto: né il
  /// cloud azzera un impero locale più avanzato, né un box locale vuoto azzera
  /// il cloud. È la regola giusta per un idle game: non si regredisce mai.
  void _mergeFromCloud(Map<String, dynamic> c) {
    for (final b in empireBuildings) {
      final lvl = (c['lvl_${b.id}'] as num?)?.toInt() ?? 0;
      if (lvl > (_levels[b.id] ?? 0)) _levels[b.id] = lvl;
    }
    final asc = (c['ascension'] as num?)?.toInt() ?? 0;
    if (asc > _ascensionPoints) _ascensionPoints = asc;
    final unc = (c['uncollected'] as num?)?.toDouble() ?? 0;
    if (unc > _uncollected) _uncollected = unc;
    final boost = (c['boostUntil'] as num?)?.toInt() ?? 0;
    if (boost > _boostUntilMs) _boostUntilMs = boost;
    final seen = (c['lastSeen'] as num?)?.toInt() ?? 0;
    if (seen > _lastSeenMs) _lastSeenMs = seen;
  }

  /// Salva lo stato su Firestore (fire & forget; no-op da ospite o offline).
  void _pushCloud() {
    final uid = _uid;
    if (uid == null) return;
    _db.saveEmpire(uid, _cloudState()).catchError((_) {});
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
    _pushCloud();
    return true;
  }

  // ── Accumulo / collect ──────────────────────────────────────────────────────

  /// Accumula i profitti in base al TEMPO REALE trascorso (wall-clock).
  /// Così l'impero continua a farmare SEMPRE: mentre guardi, cambiando schermata
  /// e ad app chiusa (capped a [offlineCapSeconds]). Usa il rate idle (no boost).
  void accrue() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSec =
        ((now - _lastSeenMs) / 1000).clamp(0.0, offlineCapSeconds.toDouble());
    if (elapsedSec <= 0) return;
    final produced = idleIncomePerSec * elapsedSec;
    _uncollected += produced;
    _producedTotal += produced;
    _lastSeenMs = now;
    _persist();
  }

  /// Tick "dal vivo" (chiamato ogni secondo dalla schermata Impero): accumula i
  /// profitti idle, applica il TURBO ai secondi live e fa avanzare il contratto.
  void tickLive() {
    accrue();
    if (boostActive) {
      final extra = idleIncomePerSec * (boostMultiplier - 1);
      _uncollected += extra;
      _producedTotal += extra;
    }
    _refreshContract();
  }

  /// Aggiunge profitti bonus ai non incassati (es. raddoppio offline da rewarded
  /// ad). NON conta per i contratti: è una ricompensa, non produzione attiva.
  void addBonus(double v) {
    if (v > 0) _uncollected += v;
  }

  /// Tap manuale sulla città: profitto istantaneo (~½ secondo di rendita + base).
  double tapEarn() {
    final value = baseIncomePerSec * globalMultiplier * 0.5 + 5 * globalMultiplier;
    _uncollected += value;
    _producedTotal += value;
    return value;
  }

  Future<double> collect() async {
    accrue(); // banca anche i profitti maturati fino a questo istante
    final amount = _uncollected;
    if (amount <= 0) return 0;
    await sl<PlayerService>().addCoins(amount);
    _uncollected = 0;
    await _persist();
    _pushCloud();
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
    _pushCloud();
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
    _pushCloud();
    return AscensionResult(
      success: true,
      gained: gained,
      total: _ascensionPoints,
      newMultiplier: globalMultiplier,
    );
  }

  // ── CONTRATTI DEL PORTO (obiettivi a tempo) ──────────────────────────────────

  EmpireContract? get activeContract => _contract;

  /// Quanto del contratto è stato consegnato finora (≤ target).
  double get contractProgress {
    final c = _contract;
    if (c == null) return 0;
    return (_producedTotal - c.startProduced).clamp(0.0, c.target);
  }

  /// Frazione 0..1 di completamento del contratto attivo.
  double get contractFraction {
    final c = _contract;
    if (c == null || c.target <= 0) return 0;
    return (contractProgress / c.target).clamp(0.0, 1.0);
  }

  /// Tempo rimasto prima della scadenza (0 se scaduto/assente).
  Duration get contractTimeLeft {
    final c = _contract;
    if (c == null) return Duration.zero;
    final ms = c.deadlineMs - DateTime.now().millisecondsSinceEpoch;
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  /// True quando il contratto è stato completato in tempo ed è riscattabile.
  bool get contractReady => _contract?.completed ?? false;

  /// Garantisce che ci sia sempre un contratto attivo (ne genera uno se manca o
  /// se quello corrente è scaduto senza essere completato). Da chiamare quando
  /// si apre la schermata Impero, DOPO accrue() (così l'eventuale recupero
  /// offline non riempie "gratis" un contratto appena nato).
  void ensureContract() {
    final c = _contract;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (c == null || (!c.completed && now > c.deadlineMs)) {
      _contract = _generateContract();
    }
  }

  /// Aggiorna lo stato del contratto ad ogni tick: lo marca completato se il
  /// target è raggiunto in tempo, oppure lo rigenera se è scaduto.
  void _refreshContract() {
    final c = _contract;
    if (c == null) {
      _contract = _generateContract();
      return;
    }
    if (c.completed) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (contractProgress >= c.target && now <= c.deadlineMs) {
      c.completed = true;
    } else if (now > c.deadlineMs) {
      _contract = _generateContract();
    }
  }

  /// Crea un contratto calibrato sulla dimensione attuale dell'impero: il target
  /// è circa la produzione del periodo ×0.9–1.5, così serve un po' di gioco
  /// attivo (tap/TURBO) per chiuderlo in tempo. Reward in gemme + bonus coin.
  EmpireContract _generateContract() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final inc = idleIncomePerSec;
    // (minuti, emoji, titolo)
    const presets = [
      [4, '🚤', 'Spedizione Express'],
      [8, '🚚', 'Carico Standard'],
      [12, '🚢', 'Grande Convoglio'],
    ];
    final p = presets[_rng.nextInt(presets.length)];
    final durMin = p[0] as int;
    final emoji = p[1] as String;
    final title = p[2] as String;
    final durSec = durMin * 60;
    final factor = 0.9 + _rng.nextDouble() * 0.6; // 0.9–1.5
    var target = inc * durSec * factor;
    final floor = 150 + _rng.nextInt(150).toDouble(); // imperi piccoli: tap-friendly
    if (target < floor) target = floor;
    target = _round2sig(target);
    final gems = (durMin / 4 + factor * 0.5).round().clamp(1, 8);
    final coins = target * 0.4;
    return EmpireContract(
      title: title,
      emoji: emoji,
      target: target,
      startMs: now,
      deadlineMs: now + durSec * 1000,
      startProduced: _producedTotal,
      rewardGems: gems,
      rewardCoins: coins,
    );
  }

  /// Arrotonda a 2 cifre significative (numeri "tondi" più leggibili).
  double _round2sig(double v) {
    if (v <= 0) return 0;
    final d = (log(v) / ln10).floor() - 1;
    final m = pow(10, d).toDouble();
    return (v / m).round() * m;
  }

  /// Riscatta il contratto completato: accredita gemme + coin e genera il
  /// prossimo. Ritorna la ricompensa, o null se non c'è nulla da riscattare.
  Future<({int gems, double coins, String title})?> claimContract() async {
    final c = _contract;
    if (c == null || !c.completed) return null;
    final ps = sl<PlayerService>();
    if (c.rewardGems > 0) await ps.addGems(c.rewardGems);
    if (c.rewardCoins > 0) await ps.addCoins(c.rewardCoins);
    final reward = (gems: c.rewardGems, coins: c.rewardCoins, title: c.title);
    _contract = _generateContract();
    return reward;
  }

  // ── Persistenza ─────────────────────────────────────────────────────────────

  Future<void> persist() => _persist();

  /// Salva e forza la scrittura su disco (chiamato all'uscita/pausa dell'app
  /// per non perdere i progressi dell'impero) e spinge l'ultimo stato sul cloud.
  Future<void> persistAndFlush() async {
    await _persist();
    await _box?.flush();
    _pushCloud();
  }

  Future<void> _persist() async {
    final box = _box;
    if (box == null) return;
    await box.put('uncollected', _uncollected);
    // Salva il timestamp fino a cui abbiamo accumulato (non "ora"), così la
    // ripresa offline calcola correttamente il tempo trascorso.
    await box.put('lastSeen', _lastSeenMs);
  }

  /// Scrive TUTTO lo stato sul box locale (usato dopo init/merge cloud).
  Future<void> _persistFull() async {
    final box = _box;
    if (box == null) return;
    for (final b in empireBuildings) {
      await box.put('lvl_${b.id}', _levels[b.id] ?? 0);
    }
    await box.put('uncollected', _uncollected);
    await box.put('ascension', _ascensionPoints);
    await box.put('boostUntil', _boostUntilMs);
    await box.put('lastSeen', _lastSeenMs);
  }
}
