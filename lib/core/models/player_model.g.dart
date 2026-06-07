// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: dart run build_runner build

part of 'player_model.dart';

class PlayerModelAdapter extends TypeAdapter<PlayerModel> {
  @override
  final int typeId = 1;

  @override
  PlayerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerModel(
      uid: fields[0] as String,
      username: fields[1] as String,
      coins: (fields[2] as num?)?.toDouble() ?? 1000,
      gems: (fields[3] as num?)?.toInt() ?? 5,
      level: (fields[4] as num?)?.toInt() ?? 1,
      xp: (fields[5] as num?)?.toDouble() ?? 0,
      totalContainersOpened: (fields[6] as num?)?.toInt() ?? 0,
      totalEarned: (fields[7] as num?)?.toDouble() ?? 0,
      inventorySlots: (fields[8] as num?)?.toInt() ?? 50,
      isVip: fields[9] as bool? ?? false,
      luckBoost: (fields[10] as num?)?.toDouble() ?? 1.0,
      speedBoost: (fields[11] as num?)?.toDouble() ?? 1.0,
      valueBoost: (fields[12] as num?)?.toDouble() ?? 1.0,
      autoOpenEnabled: fields[13] as bool? ?? false,
      autoSellEnabled: fields[14] as bool? ?? false,
      lastFreeContainerAt: fields[15] as DateTime? ?? DateTime(2000),
      luckUpgradeLevel: (fields[16] as num?)?.toInt() ?? 0,
      valueUpgradeLevel: (fields[17] as num?)?.toInt() ?? 0,
      slotsUpgradeLevel: (fields[18] as num?)?.toInt() ?? 0,
      mutationUpgradeLevel: (fields[19] as num?)?.toInt() ?? 0,
      autoOpenUpgradeLevel: (fields[20] as num?)?.toInt() ?? 0,
      autoSellUpgradeLevel: (fields[21] as num?)?.toInt() ?? 0,
      dailyLoginStreak: (fields[22] as num?)?.toInt() ?? 0,
      lastLoginAt: fields[23] as DateTime? ?? DateTime(2000),
      pityCounter: (fields[24] as num?)?.toInt() ?? 0,
      totalItemsSold: (fields[25] as num?)?.toInt() ?? 0,
      totalRaresFound: (fields[26] as num?)?.toInt() ?? 0,
      mutationBoost: (fields[27] as num?)?.toDouble() ?? 1.0,
      prestigeLevel: (fields[28] as num?)?.toInt() ?? 0,
      prestigeLuckBonus: (fields[29] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerModel obj) {
    writer
      ..writeByte(30)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.coins)
      ..writeByte(3)
      ..write(obj.gems)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.xp)
      ..writeByte(6)
      ..write(obj.totalContainersOpened)
      ..writeByte(7)
      ..write(obj.totalEarned)
      ..writeByte(8)
      ..write(obj.inventorySlots)
      ..writeByte(9)
      ..write(obj.isVip)
      ..writeByte(10)
      ..write(obj.luckBoost)
      ..writeByte(11)
      ..write(obj.speedBoost)
      ..writeByte(12)
      ..write(obj.valueBoost)
      ..writeByte(13)
      ..write(obj.autoOpenEnabled)
      ..writeByte(14)
      ..write(obj.autoSellEnabled)
      ..writeByte(15)
      ..write(obj.lastFreeContainerAt)
      ..writeByte(16)
      ..write(obj.luckUpgradeLevel)
      ..writeByte(17)
      ..write(obj.valueUpgradeLevel)
      ..writeByte(18)
      ..write(obj.slotsUpgradeLevel)
      ..writeByte(19)
      ..write(obj.mutationUpgradeLevel)
      ..writeByte(20)
      ..write(obj.autoOpenUpgradeLevel)
      ..writeByte(21)
      ..write(obj.autoSellUpgradeLevel)
      ..writeByte(22)
      ..write(obj.dailyLoginStreak)
      ..writeByte(23)
      ..write(obj.lastLoginAt)
      ..writeByte(24)
      ..write(obj.pityCounter)
      ..writeByte(25)
      ..write(obj.totalItemsSold)
      ..writeByte(26)
      ..write(obj.totalRaresFound)
      ..writeByte(27)
      ..write(obj.mutationBoost)
      ..writeByte(28)
      ..write(obj.prestigeLevel)
      ..writeByte(29)
      ..write(obj.prestigeLuckBonus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
