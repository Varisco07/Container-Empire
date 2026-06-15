import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/achievement_def.dart';

class MetaService {
  static final MetaService _instance = MetaService._internal();
  factory MetaService() => _instance;
  MetaService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _uid;

  // In-memory cache
  Set<String> _unlockedAchievements = {};
  Map<String, int> _masteryProgress = {}; // containerId → opens
  Set<String> _obtainedItems = {};        // set of item names obtained
  String _equippedTitle = '';
  Set<String> _unlockedTitles = {};

  // Getters
  Set<String> get unlockedAchievements => _unlockedAchievements;
  Map<String, int> get masteryProgress => _masteryProgress;
  Set<String> get obtainedItems => _obtainedItems;
  String get equippedTitle => _equippedTitle;
  Set<String> get unlockedTitles => _unlockedTitles;
  bool isUnlocked(String id) => _unlockedAchievements.contains(id);

  Future<void> init({required String uid}) async {
    _uid = uid;
    await _load();
  }

  Future<void> _load() async {
    if (_uid == null) return;
    try {
      final doc = await _db
          .collection('users').doc(_uid)
          .collection('data').doc('meta')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _unlockedAchievements = Set<String>.from(
            (data['achievements'] as List<dynamic>?)?.cast<String>() ?? []);
        _masteryProgress = Map<String, int>.from(
            (data['mastery'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt())) ?? {});
        _obtainedItems = Set<String>.from(
            (data['obtainedItems'] as List<dynamic>?)?.cast<String>() ?? []);
        _equippedTitle = data['equippedTitle'] as String? ?? '';
        _unlockedTitles = Set<String>.from(
            (data['unlockedTitles'] as List<dynamic>?)?.cast<String>() ?? []);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_uid == null) return;
    try {
      await _db
          .collection('users').doc(_uid)
          .collection('data').doc('meta')
          .set({
        'achievements': _unlockedAchievements.toList(),
        'mastery': _masteryProgress,
        'obtainedItems': _obtainedItems.toList(),
        'equippedTitle': _equippedTitle,
        'unlockedTitles': _unlockedTitles.toList(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Returns list of newly unlocked achievements (to show notification)
  Future<List<AchievementDef>> unlockAchievement(String id) async {
    if (_unlockedAchievements.contains(id)) return [];
    final def = AchievementDefs.find(id);
    if (def == null) return [];
    _unlockedAchievements.add(id);
    if (def.badgeTitle != null) {
      _unlockedTitles.add(def.badgeTitle!);
      if (_equippedTitle.isEmpty) _equippedTitle = def.badgeTitle!;
    }
    await _save();
    return [def];
  }

  Future<void> recordItemObtained(String itemName) async {
    if (_obtainedItems.contains(itemName)) return;
    _obtainedItems.add(itemName);
    await _save();
  }

  Future<void> incrementMastery(String containerId) async {
    _masteryProgress[containerId] = (_masteryProgress[containerId] ?? 0) + 1;
    // Save every 10 opens to reduce writes
    if (_masteryProgress[containerId]! % 10 == 0) await _save();
  }

  Future<void> equipTitle(String title) async {
    if (!_unlockedTitles.contains(title)) return;
    _equippedTitle = title;
    await _save();
  }

  // Mastery level for a container
  String masteryLabel(String containerId) {
    final opens = _masteryProgress[containerId] ?? 0;
    if (opens >= 10000) return 'COSMICO ⭐';
    if (opens >= 2000)  return 'DIAMANTE 💎';
    if (opens >= 500)   return 'ORO 🥇';
    if (opens >= 100)   return 'ARGENTO 🥈';
    if (opens >= 10)    return 'BRONZO 🥉';
    return 'NESSUNO';
  }

  int masteryTier(String containerId) {
    final opens = _masteryProgress[containerId] ?? 0;
    if (opens >= 10000) return 5;
    if (opens >= 2000)  return 4;
    if (opens >= 500)   return 3;
    if (opens >= 100)   return 2;
    if (opens >= 10)    return 1;
    return 0;
  }

  int masteryNextTarget(String containerId) {
    final opens = _masteryProgress[containerId] ?? 0;
    if (opens < 10)    return 10;
    if (opens < 100)   return 100;
    if (opens < 500)   return 500;
    if (opens < 2000)  return 2000;
    if (opens < 10000) return 10000;
    return 10000;
  }
}
