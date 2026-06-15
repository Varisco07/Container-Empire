import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/achievement_def.dart';
import '../../../core/services/meta_service.dart';
import '../../../core/theme/app_colors.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _meta = MetaService();
  String _filter = 'all'; // 'all' | 'unlocked' | 'locked' | category

  List<AchievementDef> get _filtered {
    return AchievementDefs.all.where((a) {
      if (_filter == 'unlocked') return _meta.isUnlocked(a.id);
      if (_filter == 'locked') return !_meta.isUnlocked(a.id);
      if (_filter == 'all') return true;
      return a.category == _filter;
    }).toList();
  }

  int get _unlockedCount => AchievementDefs.all.where((a) => _meta.isUnlocked(a.id)).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1020),
        title: const Text('ACHIEVEMENT', style: TextStyle(
          color: AppColors.neonGold, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18,
        )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_unlockedCount / ${AchievementDefs.all.length} sbloccati',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        Text(
                          '${(_unlockedCount / AchievementDefs.all.length * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: AppColors.neonGold, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _unlockedCount / AchievementDefs.all.length,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(AppColors.neonGold),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              children: [
                _FilterChip(label: 'Tutti', key2: 'all', active: _filter == 'all',
                    color: AppColors.neonGold, onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 6),
                _FilterChip(label: '✅ Sbloccati', key2: 'unlocked', active: _filter == 'unlocked',
                    color: AppColors.neonGreen, onTap: () => setState(() => _filter = 'unlocked')),
                const SizedBox(width: 6),
                _FilterChip(label: '🔒 Bloccati', key2: 'locked', active: _filter == 'locked',
                    color: AppColors.textMuted, onTap: () => setState(() => _filter = 'locked')),
                const SizedBox(width: 6),
                _FilterChip(label: '📦 Aperture', key2: 'opening', active: _filter == 'opening',
                    color: AppColors.neonCyan, onTap: () => setState(() => _filter = 'opening')),
                const SizedBox(width: 6),
                _FilterChip(label: '🏆 Collezione', key2: 'collection', active: _filter == 'collection',
                    color: AppColors.neonPurple, onTap: () => setState(() => _filter = 'collection')),
                const SizedBox(width: 6),
                _FilterChip(label: '💰 Economia', key2: 'economy', active: _filter == 'economy',
                    color: AppColors.coins, onTap: () => setState(() => _filter = 'economy')),
                const SizedBox(width: 6),
                _FilterChip(label: '⭐ Speciali', key2: 'special', active: _filter == 'special',
                    color: AppColors.neonOrange, onTap: () => setState(() => _filter = 'special')),
              ],
            ),
          ),

          // Achievement list
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Nessun achievement trovato',
                    style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final a = filtered[i];
                      final isUnlocked = _meta.isUnlocked(a.id);
                      return _AchievementCard(a: a, isUnlocked: isUnlocked, index: i);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Achievement card ─────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final AchievementDef a;
  final bool isUnlocked;
  final int index;

  const _AchievementCard({required this.a, required this.isUnlocked, required this.index});

  Color get _categoryColor {
    switch (a.category) {
      case 'opening':    return AppColors.neonCyan;
      case 'collection': return AppColors.neonPurple;
      case 'economy':    return AppColors.coins;
      case 'social':     return AppColors.neonGreen;
      case 'special':    return AppColors.neonGold;
      default:           return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnlocked ? _categoryColor.withOpacity(0.07) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnlocked ? _categoryColor.withOpacity(0.4) : AppColors.border,
        ),
        boxShadow: isUnlocked
            ? [BoxShadow(color: _categoryColor.withOpacity(0.1), blurRadius: 10)]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isUnlocked ? _categoryColor.withOpacity(0.15) : AppColors.border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUnlocked ? _categoryColor.withOpacity(0.5) : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  isUnlocked ? a.emoji : '🔒',
                  style: TextStyle(fontSize: isUnlocked ? 26 : 22),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(a.title, style: TextStyle(
                        color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                        fontWeight: FontWeight.w800, fontSize: 14,
                      )),
                    ),
                    if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
                        ),
                        child: const Text('✓', style: TextStyle(
                          color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    isUnlocked ? a.description : '???',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  if (a.badgeTitle != null && isUnlocked) ...[
                    const SizedBox(height: 5),
                    Row(children: [
                      const Text('🏷️ Titolo: ', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      Text(a.badgeTitle!, style: TextStyle(
                        color: _categoryColor, fontSize: 10, fontWeight: FontWeight.w800)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 30))
      .fadeIn(duration: 200.ms).slideX(begin: -0.03, end: 0);
  }
}

// ─── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label, key2;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.key2, required this.active,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? color : AppColors.border, width: active ? 1.5 : 1),
      ),
      child: Center(
        child: Text(label, style: TextStyle(
          color: active ? color : AppColors.textMuted,
          fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.normal,
        )),
      ),
    ),
  );
}
