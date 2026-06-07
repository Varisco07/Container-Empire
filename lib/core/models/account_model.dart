import 'package:hive/hive.dart';

part 'account_model.g.dart';

@HiveType(typeId: 2)
class AccountModel extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String username;

  @HiveField(2)
  String passwordHash;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String email;

  AccountModel({
    required this.uid,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
    this.email = '',
  });
}
