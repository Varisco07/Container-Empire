// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemModelAdapter extends TypeAdapter<ItemModel> {
  @override
  final int typeId = 0;

  @override
  ItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      rarityKey: fields[3] as String,
      mutationKey: fields[4] as String,
      baseValue: fields[5] as double,
      iconAsset: fields[6] as String,
      obtainedAt: fields[7] as DateTime,
      containerId: fields[9] as String,
      isLocked: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ItemModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.rarityKey)
      ..writeByte(4)
      ..write(obj.mutationKey)
      ..writeByte(5)
      ..write(obj.baseValue)
      ..writeByte(6)
      ..write(obj.iconAsset)
      ..writeByte(7)
      ..write(obj.obtainedAt)
      ..writeByte(8)
      ..write(obj.isLocked)
      ..writeByte(9)
      ..write(obj.containerId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
