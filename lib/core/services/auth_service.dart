import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/account_model.dart';
import '../models/player_model.dart';

enum AuthResult {
  success,
  userNotFound,
  wrongPassword,
  usernameTaken,
  invalidInput,
  error,
}

class AuthService {
  static const _accountsBox = 'accounts_box';
  static const _authStateBox = 'auth_state';
  static const _currentUidKey = 'current_uid';

  late Box<AccountModel> _accounts;
  late Box<dynamic> _authState;

  final Uuid _uuid = const Uuid();

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AccountModelAdapter());
    }
    _accounts = await Hive.openBox<AccountModel>(_accountsBox);
    _authState = await Hive.openBox(_authStateBox);
  }

  // ─── State ────────────────────────────────────────────────────────────────

  bool get isLoggedIn => _authState.get(_currentUidKey) != null;
  String? get currentUid => _authState.get(_currentUidKey) as String?;
  AccountModel? get currentAccount {
    final uid = currentUid;
    if (uid == null) return null;
    try {
      return _accounts.values.firstWhere((a) => a.uid == uid);
    } catch (_) {
      return null;
    }
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<AuthResult> register({
    required String username,
    required String password,
    String email = '',
  }) async {
    username = username.trim();
    if (username.length < 3 || password.length < 6) return AuthResult.invalidInput;

    // Check if username taken (case-insensitive)
    final taken = _accounts.values.any(
      (a) => a.username.toLowerCase() == username.toLowerCase(),
    );
    if (taken) return AuthResult.usernameTaken;

    final uid = _uuid.v4();
    final hash = _hashPassword(password);
    final account = AccountModel(
      uid: uid,
      username: username,
      passwordHash: hash,
      createdAt: DateTime.now(),
      email: email,
    );
    await _accounts.put(uid, account);
    await _authState.put(_currentUidKey, uid);
    return AuthResult.success;
  }

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    username = username.trim();
    AccountModel? account;
    try {
      account = _accounts.values.firstWhere(
        (a) => a.username.toLowerCase() == username.toLowerCase(),
      );
    } catch (_) {
      return AuthResult.userNotFound;
    }
    if (account.passwordHash != _hashPassword(password)) {
      return AuthResult.wrongPassword;
    }
    await _authState.put(_currentUidKey, account.uid);
    return AuthResult.success;
  }

  Future<void> logout() async {
    await _authState.delete(_currentUidKey);
  }

  // ─── Player save/load per account ─────────────────────────────────────────

  /// Nome della box Hive specifica per questo account
  String playerBoxName(String uid) => 'player_$uid';

  Future<Box<PlayerModel>> openPlayerBox(String uid) async {
    return Hive.openBox<PlayerModel>(playerBoxName(uid));
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'ce_salt_2024');
    return sha256.convert(bytes).toString();
  }
}
