import 'package:hive/hive.dart';
import 'rarity.dart';

part 'item_model.g.dart';

@HiveType(typeId: 0)
class ItemModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String rarityKey;

  @HiveField(4)
  final String mutationKey;

  @HiveField(5)
  final double baseValue;

  @HiveField(6)
  final String iconAsset;

  @HiveField(7)
  final DateTime obtainedAt;

  @HiveField(8)
  bool isLocked;

  @HiveField(9)
  final String containerId;

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.rarityKey,
    required this.mutationKey,
    required this.baseValue,
    required this.iconAsset,
    required this.obtainedAt,
    required this.containerId,
    this.isLocked = false,
  });

  Rarity get rarity => Rarity.values.firstWhere(
        (r) => r.name == rarityKey,
        orElse: () => Rarity.common,
      );

  Mutation get mutation => Mutation.values.firstWhere(
        (m) => m.name == mutationKey,
        orElse: () => Mutation.none,
      );

  double get finalValue =>
      baseValue * rarity.valueMultiplier * mutation.valueMultiplier;

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'category': category,
        'rarityKey': rarityKey,
        'mutationKey': mutationKey,
        'baseValue': baseValue,
        'iconAsset': iconAsset,
        'obtainedAt': obtainedAt.toIso8601String(),
        'containerId': containerId,
        'isLocked': isLocked,
        'finalValue': finalValue,
      };

  factory ItemModel.fromFirestore(Map<String, dynamic> data) => ItemModel(
        id: data['id'] as String,
        name: data['name'] as String,
        category: data['category'] as String,
        rarityKey: data['rarityKey'] as String,
        mutationKey: data['mutationKey'] as String,
        baseValue: (data['baseValue'] as num).toDouble(),
        iconAsset: data['iconAsset'] as String,
        obtainedAt: DateTime.parse(data['obtainedAt'] as String),
        containerId: data['containerId'] as String,
        isLocked: data['isLocked'] as bool? ?? false,
      );
}
