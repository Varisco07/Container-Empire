import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account_model.dart';
import 'database_service.dart';

enum AuthResult {
  success,
  userNotFound,
  wrongPassword,
  usernameTaken,
  invalidInput,
  emailAlreadyInUse,
  networkError,
  error,
}

enum AccountDeletionResult { success, requiresRecentLogin, error }

class AuthService {
  static const _authStateBox  = 'auth_state';
  static const _currentUidKey = 'current_uid';
  static const _usernameKey   = 'current_username';

  final FirebaseAuth    _firebaseAuth = FirebaseAuth.instance;
  final DatabaseService _db           = DatabaseService();

  late Box<dynamic> _authState;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AccountModelAdapter());
    }
    _authState = await Hive.openBox(_authStateBox);

    // Sincronizza con Firebase
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser != null) {
      await _authState.put(_currentUidKey, fbUser.uid);
    } else {
      await _authState.delete(_currentUidKey);
      await _authState.delete(_usernameKey);
    }
  }

  // ─── Stato ────────────────────────────────────────────────────────────────

  bool    get isLoggedIn    => _firebaseAuth.currentUser != null;
  String? get currentUid    => _firebaseAuth.currentUser?.uid ?? _authState.get(_currentUidKey) as String?;
  String? get currentUsername => _authState.get(_usernameKey) as String?;

  AccountModel? get currentAccount {
    final uid      = currentUid;
    final username = currentUsername;
    if (uid == null || username == null) return null;
    return AccountModel(
      uid:          uid,
      username:     username,
      passwordHash: '',
      createdAt:    DateTime.now(),
      email:        _firebaseAuth.currentUser?.email ?? '',
    );
  }

  // ─── Registrazione ────────────────────────────────────────────────────────

  Future<AuthResult> register({
    required String username,
    required String password,
    String email = '',
  }) async {
    username = username.trim();
    if (username.length < 3 || password.length < 6) return AuthResult.invalidInput;

    try {
      // 1. Unicità username
      if (await _db.isUsernameTaken(username)) return AuthResult.usernameTaken;

      // 2. Email per Firebase Auth (fittizia se non fornita)
      final authEmail = email.trim().isNotEmpty
          ? email.trim()
          : '${username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@containerempire.game';

      // 3. Crea account Firebase
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: authEmail, password: password,
      );
      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(username);

      // 4. Salva su Firestore
      await _db.reserveUsername(username, uid);
      await _db.saveProfile(
        uid: uid, username: username,
        email: authEmail, createdAt: DateTime.now(),
      );

      // 5. Cache locale
      await _authState.put(_currentUidKey, uid);
      await _authState.put(_usernameKey, username);

      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (_) {
      return AuthResult.error;
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    username = username.trim();
    if (username.length < 3 || password.length < 6) return AuthResult.invalidInput;

    // Email fittizia che viene creata in fase di registrazione se non si fornisce email reale
    final constructedEmail =
        '${username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@containerempire.game';

    try {
      // ── Tentativo 1: login diretto con email costruita (nessun Firestore) ──
      try {
        final cred = await _firebaseAuth.signInWithEmailAndPassword(
          email: constructedEmail, password: password,
        );
        final uid = cred.user!.uid;
        // Recupera username reale dal profilo (fire & forget se fallisce)
        String finalUsername = username;
        try {
          final profile = await _db.loadProfile(uid);
          finalUsername = profile?['username'] as String? ?? username;
        } catch (_) {}
        await _authState.put(_currentUidKey, uid);
        await _authState.put(_usernameKey, finalUsername);
        return AuthResult.success;
      } on FirebaseAuthException catch (e) {
        // Se è wrong-password o user-not-found con email costruita, gestisci
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          return AuthResult.wrongPassword;
        }
        // Se user-not-found con email costruita, prova via Firestore lookup
        if (e.code != 'user-not-found') return _mapError(e);
      }

      // ── Tentativo 2: lookup UID da Firestore (per account con email reale) ──
      final uid = await _db.lookupUidByUsername(username);
      if (uid == null) return AuthResult.userNotFound;

      final profile   = await _db.loadProfile(uid);
      final authEmail = profile?['email'] as String? ?? constructedEmail;

      await _firebaseAuth.signInWithEmailAndPassword(
        email: authEmail, password: password,
      );

      await _authState.put(_currentUidKey, uid);
      await _authState.put(_usernameKey, username);
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (e) {
      // ignore: avoid_print
      print('[AuthService.login] errore generico: $e');
      return AuthResult.networkError;
    }
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  Future<AuthResult> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return AuthResult.error; // utente ha annullato

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCred = await _firebaseAuth.signInWithCredential(credential);
      final fbUser   = userCred.user!;
      final uid      = fbUser.uid;

      // Controlla se esiste già un profilo Firestore
      final profile = await _db.loadProfile(uid);
      String username;

      if (profile != null) {
        // Utente già registrato con Google
        username = profile['username'] as String? ??
            googleUser.displayName ??
            googleUser.email.split('@').first;
      } else {
        // Primo accesso — crea profilo
        String base = (googleUser.displayName ?? googleUser.email.split('@').first)
            .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
            .toLowerCase();
        if (base.length < 3) base = 'user${uid.substring(0, 6)}';
        if (base.length > 20) base = base.substring(0, 20);

        String finalName = base;
        int n = 1;
        while (await _db.isUsernameTaken(finalName)) {
          finalName = '$base$n';
          n++;
        }
        username = finalName;

        await _db.reserveUsername(username, uid);
        await _db.saveProfile(
          uid:       uid,
          username:  username,
          email:     googleUser.email,
          createdAt: DateTime.now(),
        );
      }

      await _authState.put(_currentUidKey, uid);
      await _authState.put(_usernameKey, username);

      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (_) {
      return AuthResult.error;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _authState.delete(_currentUidKey);
    await _authState.delete(_usernameKey);
  }

  // ─── Eliminazione account (GDPR / requisito store) ──────────────────────────

  /// Cancella i dati cloud, l'utente di autenticazione e lo stato locale.
  /// Ritorna [AccountDeletionResult.requiresRecentLogin] se Firebase richiede un
  /// login recente: in quel caso i dati cloud sono già stati rimossi, basta
  /// rifare login e riprovare per eliminare anche l'account di autenticazione.
  Future<AccountDeletionResult> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    final uid = currentUid;
    final username = currentUsername;
    try {
      if (uid != null) {
        await _db.deleteAllUserData(uid, username: username);
      }
      if (user != null) {
        await user.delete();
      }
      await _authState.delete(_currentUidKey);
      await _authState.delete(_usernameKey);
      return AccountDeletionResult.success;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return AccountDeletionResult.requiresRecentLogin;
      }
      return AccountDeletionResult.error;
    } catch (_) {
      return AccountDeletionResult.error;
    }
  }

  // ─── Reset Password ───────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  AuthResult _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':   return AuthResult.emailAlreadyInUse;
      case 'user-not-found':         return AuthResult.userNotFound;
      case 'wrong-password':
      case 'invalid-credential':     return AuthResult.wrongPassword;
      case 'network-request-failed': return AuthResult.networkError;
      default:                       return AuthResult.error;
    }
  }
}
