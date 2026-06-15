// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      coins: fields[2] as double,
      gems: fields[3] as int,
      level: fields[4] as int,
      xp: fields[5] as double,
      totalContainersOpened: fields[6] as int,
      totalEarned: fields[7] as double,
      inventorySlots: fields[8] as int,
      isVip: fields[9] as bool,
      luckBoost: fields[10] as double,
      speedBoost: fields[11] as double,
      valueBoost: fields[12] as double,
      autoOpenEnabled: fields[13] as bool,
      autoSellEnabled: fields[14] as bool,
      lastFreeContainerAt: fields[15] as DateTime?,
      luckUpgradeLevel: fields[16] as int,
      valueUpgradeLevel: fields[17] as int,
      slotsUpgradeLevel: fields[18] as int,
      mutationUpgradeLevel: fields[19] as int,
      autoOpenUpgradeLevel: fields[20] as int,
      autoSellUpgradeLevel: fields[21] as int,
      dailyLoginStreak: fields[22] as int,
      lastLoginAt: fields[23] as DateTime?,
      pityCounter: fields[24] as int,
      totalItemsSold: fields[25] as int,
      totalRaresFound: fields[26] as int,
      mutationBoost: fields[27] as double,
      prestigeLevel: fields[28] as int,
      prestigeLuckBonus: fields[29] as double,
      dust: fields[30] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerModel obj) {
    writer
      ..writeByte(31)
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
      ..write(obj.prestigeLuckBonus)
      ..writeByte(30)
      ..write(obj.dust);
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
