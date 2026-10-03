import 'dart:async';

/// Interface autentikasi. Implementasi asli (`FirebaseAuthService`: anonim →
/// link ke akun) tersambung sejak M5 — lihat
/// `lib/core/services/firebase/firebase_auth_service.dart`. [StubAuthService]
/// dipakai untuk pengembangan/testing tanpa koneksi Firebase.
abstract class AuthService {
  String? get currentUid;

  /// Email akun yang sedang login — null kalau masih anonim/belum
  /// ditautkan ke email atau Google (lihat [PengaturanScreen] § Akun).
  String? get currentEmail;

  bool get isAnonymous;

  /// Emit uid saat ini setiap kali status auth berubah (termasuk `null`
  /// saat sign-out).
  Stream<String?> get uidChanges;

  Future<String> signInAnonymously();

  Future<void> signOut();

  /// Upgrade akun anonim saat ini (dari onboarding) jadi akun permanen
  /// email+password — uid & data yang sudah ada tetap sama. Kalau sesi
  /// saat ini bukan anonim (mis. sudah login sebelumnya), berlaku seperti
  /// sign-in biasa.
  Future<String> linkEmailPassword({required String email, required String password});

  /// Masuk ke akun email+password yang sudah ada — uid akan berganti ke
  /// uid akun tersebut (bukan mempertahankan uid anonim saat ini).
  Future<String> signInWithEmailPassword({required String email, required String password});

  /// Sama seperti [linkEmailPassword] tapi lewat Google Sign-In.
  Future<String> linkGoogle();

  /// Sama seperti [signInWithEmailPassword] tapi lewat Google Sign-In.
  Future<String> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  /// Hapus akun Firebase Auth secara permanen. Data Firestore/lokal
  /// pengguna dibersihkan terpisah oleh pemanggil (lihat
  /// `HapusAkunScreen`) SEBELUM ini dipanggil — begitu akun terhapus,
  /// tidak ada lagi uid buat menulis apa pun.
  Future<void> deleteAccount();
}

/// Jenis error auth yang dikenali app. UI menerjemahkannya ke teks
/// berbahasa aktif lewat `LaunchStrings.authError` — layer service sengaja
/// TIDAK membuat kalimat (tidak punya konteks bahasa).
enum AuthError {
  emailInUse,
  invalidEmail,
  weakPassword,
  userNotFound,
  wrongCredential,
  tooManyRequests,
  network,
  credentialInUse,
  requiresRecentLogin,
  googleNoToken,
  googleUnavailable,
  unknown,
}

/// Error auth yang bisa ditampilkan ke user: bawa [error] (jenis) dan
/// [code] (kode mentah Firebase, hanya untuk jenis [AuthError.unknown]).
class AuthServiceException implements Exception {
  const AuthServiceException(this.error, {this.code});
  final AuthError error;
  final String? code;

  @override
  String toString() => 'AuthServiceException(${error.name}${code == null ? '' : ', $code'})';
}

/// Implementasi stub — "masuk" otomatis sebagai user dummy `u_001` dari
/// `docs/dummy-data-seed.json` supaya seluruh layar bisa dites tanpa koneksi
/// Firebase sama sekali.
class StubAuthService implements AuthService {
  StubAuthService({this.dummyUid = 'u_001'}) {
    _uid = dummyUid;
    _controller.add(_uid);
  }

  final String dummyUid;
  String? _uid;
  final StreamController<String?> _controller = StreamController<String?>.broadcast();

  @override
  String? get currentUid => _uid;

  @override
  String? get currentEmail => null;

  @override
  bool get isAnonymous => true;

  @override
  Stream<String?> get uidChanges => _controller.stream;

  @override
  Future<String> signInAnonymously() async {
    _uid = dummyUid;
    _controller.add(_uid);
    return _uid!;
  }

  @override
  Future<void> signOut() async {
    _uid = null;
    _controller.add(null);
  }

  @override
  Future<String> linkEmailPassword({required String email, required String password}) => signInAnonymously();

  @override
  Future<String> signInWithEmailPassword({required String email, required String password}) => signInAnonymously();

  @override
  Future<String> linkGoogle() => signInAnonymously();

  @override
  Future<String> signInWithGoogle() => signInAnonymously();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> deleteAccount() async {
    _uid = null;
    _controller.add(null);
  }
}
