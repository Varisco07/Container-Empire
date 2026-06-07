import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/neon_text.dart';

enum LeaderboardType { coins, level, inventory, secrets }

// Sample leaderboard data (Firebase verrà aggiunto in seguito)
final _sampleData = [
  {'username': 'QuantumKing', 'totalEarned': 9.8e12, 'level': 247},
  {'username': 'VoidHunter99', 'totalEarned': 4.2e12, 'level': 198},
  {'username': 'GalaxyTrader', 'totalEarned': 1.9e12, 'level': 155},
  {'username': 'NeonLegend', 'totalEarned': 8.5e11, 'level': 134},
  {'username': 'StarCollector', 'totalEarned': 3.1e11, 'level': 112},
  {'username': 'DiamondRush', 'totalEarned': 9.4e10, 'level': 98},
  {'username': 'MythicHunter', 'totalEarned': 4.7e10, 'level': 87},
  {'username': 'CryptoBox', 'totalEarned': 1.2e10, 'level': 76},
  {'username': 'LootMaster', 'totalEarned': 5.8e9, 'level': 65},
  {'username': 'Player', 'totalEarned': 0, 'level': 1},
];

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardType _type = LeaderboardType.coins;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('CLASSIFICA GLOBALE')),
      body: Column(
        children: [
          // Category tabs
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: LeaderboardType.values.map((t) {
                  final selected = t == _type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.neonGold.withOpacity(0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? AppColors.neonGold : AppColors.border),
                        ),
                        child: Text(
                          _typeLabel(t),
                          style: TextStyle(
                            color: selected ? AppColors.neonGold : AppColors.textMuted,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sampleData.length,
              itemBuilder: (_, i) {
                final data = _sampleData[i];
                return _LeaderRow(
                  rank: i + 1,
                  username: data['username'] as String,
                  value: (data['totalEarned'] as num).toDouble(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(LeaderboardType t) {
    switch (t) {
      case LeaderboardType.coins: return '💰 Guadagni';
      case LeaderboardType.level: return '⭐ Livello';
      case LeaderboardType.inventory: return '📦 Inventario';
      case LeaderboardType.secrets: return '🔮 Segreti';
    }
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final String username;
  final double value;

  const _LeaderRow({required this.rank, required this.username, required this.value});

  Color get _rankColor {
    if (rank == 1) return AppColors.neonGold;
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rank <= 3 ? _rankColor.withOpacity(0.07) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rank <= 3 ? _rankColor.withOpacity(0.4) : AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: rank <= 3
                ? NeonText('#$rank', color: _rankColor, fontSize: 18, blurRadius: 8)
                : Text('#$rank', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          if (rank <= 3) ...[
            Icon(_rankIcon, color: _rankColor, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(username, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          Text(_fmt(value), style: TextStyle(color: _rankColor, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  IconData get _rankIcon {
    if (rank == 1) return Icons.emoji_events_rounded;
    if (rank == 2) return Icons.military_tech_rounded;
    return Icons.workspace_premium_rounded;
  }

  String _fmt(double v) {
    if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T€';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B€';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M€';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K€';
    return '${v.toStringAsFixed(0)}€';
  }
}
