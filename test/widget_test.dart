// Unit test della logica di gioco (formattazione, rank impero, economia, pass).
import 'package:flutter_test/flutter_test.dart';

import 'package:container_empire/core/models/empire_building.dart';
import 'package:container_empire/core/models/battle_pass.dart';

void main() {
  group('fmtNum', () {
    test('formatta numeri grandi', () {
      expect(fmtNum(999), '999');
      expect(fmtNum(1500), '1.50K');
      expect(fmtNum(2500000), '2.50M');
      expect(fmtNum(3200000000), '3.20B');
      expect(fmtNum(125000), '125K');
    });
  });

  group('EmpireBuilding', () {
    test('income e costo scalano col livello', () {
      final b = empireBuildings.first;
      expect(b.incomeAt(0), 0);
      expect(b.incomeAt(1), b.baseIncome);
      expect(b.costAt(1) > b.costAt(0), true);
    });
  });

  group('empireRankFor', () {
    test('rank cresce col profitto', () {
      expect(empireRankFor(0).level, 1);
      expect(empireRankFor(1e18).level, 13);
    });
  });

  group('BattlePass', () {
    test('genera tutte le tier della stagione', () {
      final tiers = buildSeasonTiers();
      expect(tiers.length, passTiers);
      expect(tiers.first.tier, 1);
      expect(tiers.last.tier, passTiers);
    });
  });
}
