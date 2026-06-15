import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// EMPIRE BUILDINGS — generatori idle di profitto del Tycoon.
///
/// Ogni edificio produce coins/sec = baseIncome × level × milestoneMult(level).
/// Costo upgrade da L→L+1 = baseCost × costGrowth^L.
/// Gli edifici si sbloccano in cascata (serve L≥1 sul precedente).
/// ─────────────────────────────────────────────────────────────────────────────

/// Moltiplicatore "milestone" stile Idle Mafia: ad ogni soglia il profitto raddoppia.
double buildingMilestoneMult(int level) {
  const milestones = [10, 25, 50, 100, 150, 200, 300, 400];
  int m = 1;
  for (final ms in milestones) {
    if (level >= ms) m *= 2;
  }
  return m.toDouble();
}

class EmpireBuilding {
  final String id;
  final String name;
  final String emoji;
  final IconData icon;
  final Color color;
  final double baseIncome; // coins/sec per livello
  final double baseCost; // costo del primo livello
  final double costGrowth; // crescita costo per livello

  const EmpireBuilding({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.baseIncome,
    required this.baseCost,
    this.costGrowth = 1.135,
  });

  double incomeAt(int level) =>
      level <= 0 ? 0 : baseIncome * level * buildingMilestoneMult(level);

  double costAt(int level) => baseCost * pow(costGrowth, level);

  /// Prossima milestone (per la UI: "tra X livelli ×2 profitto").
  int? nextMilestone(int level) {
    const milestones = [10, 25, 50, 100, 150, 200, 300, 400];
    for (final ms in milestones) {
      if (level < ms) return ms;
    }
    return null;
  }
}

/// Catalogo degli edifici dell'impero (dal piccolo deposito al portale).
const List<EmpireBuilding> empireBuildings = [
  EmpireBuilding(
    id: 'depot', name: 'DEPOSITO', emoji: '🏚️',
    icon: Icons.warehouse_rounded, color: AppColors.neonGreen,
    baseIncome: 1, baseCost: 60,
  ),
  EmpireBuilding(
    id: 'factory', name: 'FABBRICA', emoji: '🏭',
    icon: Icons.factory_rounded, color: AppColors.neonCyan,
    baseIncome: 8, baseCost: 720,
  ),
  EmpireBuilding(
    id: 'bank', name: 'BANCA', emoji: '🏦',
    icon: Icons.account_balance_rounded, color: AppColors.neonGold,
    baseIncome: 48, baseCost: 8500,
  ),
  EmpireBuilding(
    id: 'port', name: 'PORTO', emoji: '⚓',
    icon: Icons.anchor_rounded, color: AppColors.rare,
    baseIncome: 300, baseCost: 95000,
  ),
  EmpireBuilding(
    id: 'ai', name: 'CENTRO AI', emoji: '🤖',
    icon: Icons.smart_toy_rounded, color: AppColors.neonPurple,
    baseIncome: 1800, baseCost: 1100000,
  ),
  EmpireBuilding(
    id: 'research', name: 'CENTRO RICERCA', emoji: '🔬',
    icon: Icons.science_rounded, color: AppColors.uncommon,
    baseIncome: 11000, baseCost: 13000000,
  ),
  EmpireBuilding(
    id: 'quantum', name: 'LAB QUANTISTICO', emoji: '⚛️',
    icon: Icons.blur_on_rounded, color: AppColors.secret,
    baseIncome: 68000, baseCost: 150000000,
  ),
  EmpireBuilding(
    id: 'reactor', name: 'REATTORE', emoji: '⚡',
    icon: Icons.bolt_rounded, color: AppColors.neonOrange,
    baseIncome: 420000, baseCost: 1700000000,
  ),
  EmpireBuilding(
    id: 'orbital', name: 'STAZIONE ORBITALE', emoji: '🛰️',
    icon: Icons.satellite_alt_rounded, color: AppColors.divine,
    baseIncome: 2600000, baseCost: 20000000000,
  ),
  EmpireBuilding(
    id: 'portal', name: 'PORTALE INTERDIMENSIONALE', emoji: '🌀',
    icon: Icons.all_inclusive_rounded, color: AppColors.cosmic,
    baseIncome: 16000000, baseCost: 240000000000,
  ),
  EmpireBuilding(
    id: 'dyson', name: 'SFERA DI DYSON', emoji: '☀️',
    icon: Icons.wb_sunny_rounded, color: AppColors.neonGold,
    baseIncome: 100000000, baseCost: 3000000000000,
  ),
  EmpireBuilding(
    id: 'galexch', name: 'BORSA GALATTICA', emoji: '🌠',
    icon: Icons.currency_exchange_rounded, color: AppColors.neonPink,
    baseIncome: 700000000, baseCost: 40000000000000,
  ),
  EmpireBuilding(
    id: 'multihub', name: 'HUB MULTIVERSO', emoji: '🪐',
    icon: Icons.hub_rounded, color: AppColors.secret,
    baseIncome: 5000000000, baseCost: 500000000000000,
  ),
];

/// ─────────────────────────────────────────────────────────────────────────────
/// RANK DELL'IMPERO — titolo dinamico in base al profitto/sec totale.
/// ─────────────────────────────────────────────────────────────────────────────
class EmpireRank {
  final int level;
  final String title;
  final Color color;
  const EmpireRank(this.level, this.title, this.color);
}

const List<EmpireRank> _ranks = [
  EmpireRank(1, 'PICCOLO DEPOSITO', AppColors.neonGreen),
  EmpireRank(2, 'CENTRO LOGISTICO', AppColors.uncommon),
  EmpireRank(3, 'PORTO INDUSTRIALE', AppColors.neonCyan),
  EmpireRank(4, 'MEGA PORTO', AppColors.rare),
  EmpireRank(5, 'SMART CITY', AppColors.neonPurple),
  EmpireRank(6, 'CONTINENTE COMMERCIALE', AppColors.neonGold),
  EmpireRank(7, 'CORPORAZIONE GLOBALE', AppColors.neonOrange),
  EmpireRank(8, 'IMPERO QUANTISTICO', AppColors.secret),
  EmpireRank(9, 'PIANETA INDUSTRIALE', AppColors.divine),
  EmpireRank(10, 'GALACTIC TRADE EMPIRE', AppColors.neonGold),
  EmpireRank(11, 'DOMINIO STELLARE', AppColors.neonPink),
  EmpireRank(12, 'IMPERO MULTIVERSALE', AppColors.secret),
  EmpireRank(13, 'ENTITÀ COSMICA', AppColors.cosmic),
];

EmpireRank empireRankFor(double incomePerSec) {
  // Soglie esponenziali: ogni rank ~ ×30 il precedente.
  if (incomePerSec < 50) return _ranks[0];
  if (incomePerSec < 1500) return _ranks[1];
  if (incomePerSec < 40000) return _ranks[2];
  if (incomePerSec < 1200000) return _ranks[3];
  if (incomePerSec < 35000000) return _ranks[4];
  if (incomePerSec < 1000000000) return _ranks[5];
  if (incomePerSec < 30000000000) return _ranks[6];
  if (incomePerSec < 900000000000) return _ranks[7];
  if (incomePerSec < 30000000000000) return _ranks[8];
  if (incomePerSec < 900000000000000) return _ranks[9];
  if (incomePerSec < 30000000000000000) return _ranks[10];
  if (incomePerSec < 900000000000000000) return _ranks[11];
  return _ranks[12];
}

/// ─────────────────────────────────────────────────────────────────────────────
/// FORMATTAZIONE NUMERI GRANDI — 1.2K / 3.4M / 5.6B / 7.8T / ...
/// ─────────────────────────────────────────────────────────────────────────────
String fmtNum(double v) {
  if (v.isNaN || v.isInfinite) return '0';
  if (v < 1000) return v.toStringAsFixed(0);
  const units = ['K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc'];
  int u = -1;
  double n = v;
  while (n >= 1000 && u < units.length - 1) {
    n /= 1000;
    u++;
  }
  final dec = n >= 100 ? 0 : (n >= 10 ? 1 : 2);
  return '${n.toStringAsFixed(dec)}${units[u]}';
}
