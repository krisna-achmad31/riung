import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../auth_service.dart';

/// Implementasi [AuthService] sungguhan lewat Firebase Auth — anonim untuk
/// pra-signup (dipakai sepanjang onboarding), lalu di-link ke email+password
/// atau Google saat user resmi mendaftar di layar Daftar (uid & data yang
/// sudah terkumpul selama onboarding tetap sama, cuma "diklaim" jadi akun
/// permanen). Lihat `docs/setup-firebase.md` untuk cara mengaktifkan
/// provider Email/Password & Google di Firebase Console.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn, required String googleServerClientId})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _googleServerClientId = googleServerClientId;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final String _googleServerClientId;
  bool _googleInitialized = false;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  @override
  Stream<String?> get uidChanges => _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<String> signInAnonymously() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;
    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    if (_googleServerClientId.isEmpty) {
      throw const AuthServiceException(AuthError.googleUnavailable);
    }
    // google_sign_in v7+ butuh serverClientId eksplisit di Android (dulu
    // otomatis terbaca dari google-services.json, sekarang tidak lagi) —
    // ini ID OAuth "Web client" project ini dari Google Cloud Console,
    // BUKAN Android client id. Lihat docs/setup-firebase.md § Google.
    await _googleSignIn.initialize(serverClientId: _googleServerClientId);
    _googleInitialized = true;
  }

  Future<AuthCredential> _googleCredential() async {
    await _ensureGoogleInitialized();
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthServiceException(AuthError.googleNoToken);
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  /// Kalau user saat ini anonim, upgrade ("link") akunnya ke kredensial
  /// baru supaya uid & data yang sudah ada tetap sama. Kalau tidak ada user
  /// anonim aktif (mis. sesi lama kadaluarsa), fallback ke sign-in biasa.
  Future<String> _linkOrSignIn(AuthCredential credential) async {
    final user = _auth.currentUser;
    try {
      if (user != null && user.isAnonymous) {
        final result = await user.linkWithCredential(credential);
        return result.user!.uid;
      }
      final result = await _auth.signInWithCredential(credential);
      return result.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<String> linkEmailPassword({required String email, required String password}) {
    return _linkOrSignIn(EmailAuthProvider.credential(email: email, password: password));
  }

  @override
  Future<String> signInWithEmailPassword({required String email, required String password}) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<String> linkGoogle() async {
    final credential = await _googleCredential();
    return _linkOrSignIn(credential);
  }

  @override
  Future<String> signInWithGoogle() async {
    final credential = await _googleCredential();
    try {
      final result = await _auth.signInWithCredential(credential);
      return result.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthServiceException(AuthError.requiresRecentLogin);
      }
      throw _toException(e);
    }
  }

  AuthServiceException _toException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return const AuthServiceException(AuthError.emailInUse);
      case 'invalid-email':
        return const AuthServiceException(AuthError.invalidEmail);
      case 'weak-password':
        return const AuthServiceException(AuthError.weakPassword);
      case 'user-not-found':
        return const AuthServiceException(AuthError.userNotFound);
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthServiceException(AuthError.wrongCredential);
      case 'too-many-requests':
        return const AuthServiceException(AuthError.tooManyRequests);
      case 'network-request-failed':
        return const AuthServiceException(AuthError.network);
      case 'credential-already-in-use':
        return const AuthServiceException(AuthError.credentialInUse);
      default:
        return AuthServiceException(AuthError.unknown, code: e.code);
    }
  }
}
