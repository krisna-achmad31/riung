import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/monster_progress.dart';
import '../models/user_profile.dart';
import '../models/wallet.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';

/// Notifier global status autentikasi + profil user saat ini — satu-satunya
/// sumber uid & [UserProfile] untuk seluruh app (lihat CLAUDE.md §State
/// management). Profil digabung di sini (bukan notifier terpisah) karena
/// "siapa yang login" dan "profilnya" adalah satu domain identitas yang
/// sama, bukan domain lintas layar baru.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._authService, {required UserRepository userRepository})
      : _userRepository = userRepository {
    _uid = _authService.currentUid;
    _subscription = _authService.uidChanges.listen((uid) {
      _uid = uid;
      _profile = null;
      notifyListeners();
    });
  }

  final AuthService _authService;
  final UserRepository _userRepository;
  late final StreamSubscription<String?> _subscription;
  String? _uid;
  UserProfile? _profile;
  Future<UserProfile>? _profileLoading;
  bool _migrationWarning = false;

  String? get uid => _uid;
  bool get isSignedIn => _uid != null;
  bool get isAnonymous => _authService.isAnonymous;
  String? get email => _authService.currentEmail;
  UserProfile? get profile => _profile;

  /// Poin 4d — true kalau linking sukses tapi penyalinan progres anonim
  /// ke cloud gagal (mis. network error) setelahnya. Layar pemanggil
  /// ([DaftarScreen]) baca ini sekali (lalu tampilkan pesan sesuai bahasa
  /// aktif) dan panggil [clearMigrationWarning] supaya tidak nyangkut kalau
  /// di-rebuild.
  bool get migrationWarning => _migrationWarning;

  void clearMigrationWarning() {
    _migrationWarning = false;
  }

  /// Memuat profil sekali & meng-cache-nya; aman dipanggil berkali-kali
  /// (mis. dari beberapa layar) — pemanggilan berikutnya memakai cache atau
  /// menumpang pada pemuatan yang sedang berjalan. Kalau belum ada sesi
  /// sama sekali (instal baru + Firebase Auth belum pernah sign-in), masuk
  /// anonim dulu di sini — splash screen jadi satu-satunya tempat yang
  /// perlu tahu soal ini.
  Future<UserProfile> ensureProfileLoaded() {
    final loaded = _profile;
    if (loaded != null) return Future.value(loaded);
    return _profileLoading ??= _loadProfile();
  }

  Future<UserProfile> _loadProfile() async {
    try {
      return await _doLoadProfile();
    } catch (_) {
      // Reset cache kegagalan supaya panggilan ensureProfileLoaded()
      // berikutnya (mis. tombol "Coba lagi" di splash) benar-benar
      // mengulang, bukan mengembalikan Future gagal yang sama terus.
      _profileLoading = null;
      rethrow;
    }
  }

  Future<UserProfile> _doLoadProfile() async {
    var uid = _uid;
    if (uid == null) {
      uid = await _authService.signInAnonymously();
      _uid = uid;
    }
    final p = await _userRepository.getUserProfile(uid);
    _profile = p;
    _profileLoading = null;
    notifyListeners();
    return p;
  }

  /// Muat ulang profil dari sumbernya, lewati cache — dipakai setelah
  /// mutasi yang tidak lewat [updateProfile] (mis. [BillingService]
  /// menulis `premium` langsung lewat [UserRepository.saveUserProfile]).
  Future<UserProfile> refreshProfile() async {
    final uid = _uid;
    if (uid == null) return ensureProfileLoaded();
    final p = await _userRepository.getUserProfile(uid);
    _profile = p;
    notifyListeners();
    return p;
  }

  Future<void> updateProfile(UserProfile Function(UserProfile current) update) async {
    final current = _profile ?? await ensureProfileLoaded();
    final updated = update(current);
    await _userRepository.saveUserProfile(updated);
    _profile = updated;
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    _uid = await _authService.signInAnonymously();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Daftar dengan email+password — upgrade sesi anonim saat ini (uid &
  /// progres onboarding tetap sama) jadi akun permanen, lalu salin
  /// progres yang terkumpul selama anonim ke Firestore (lihat
  /// [_linkAndMigrate]).
  Future<String> daftarEmailPassword({required String email, required String password}) {
    return _linkAndMigrate(() => _authService.linkEmailPassword(email: email, password: password));
  }

  /// Masuk ke akun email+password yang SUDAH ADA — uid berganti ke akun
  /// itu (bukan mempertahankan uid anonim), jadi TIDAK ada migrasi di
  /// sini: data lokal perangkat ini milik sesi anonim yang ditinggalkan,
  /// bukan milik akun yang baru saja di-masuki.
  Future<String> masukEmailPassword({required String email, required String password}) {
    return _authService.signInWithEmailPassword(email: email, password: password);
  }

  /// Daftar lewat Google — upgrade sesi anonim saat ini, lihat
  /// [_linkAndMigrate].
  Future<String> daftarGoogle() => _linkAndMigrate(() => _authService.linkGoogle());

  /// Masuk ke akun Google yang sudah ada.
  Future<String> masukGoogle() => _authService.signInWithGoogle();

  /// Poin 4d — urutan ini KRITIS, jangan diubah tanpa alasan kuat:
  /// 1. Baca wallet/profile/monsterProgress SAAT INI lewat
  ///    [_userRepository] SEBELUM [link] dipanggil — masih anonim, jadi
  ///    masih rute ke lokal (lihat FirestoreUserRepository.isAnonymous).
  /// 2. Panggil [link] (linkEmailPassword/linkGoogle) — uid tetap sama
  ///    persis (Firebase `linkWithCredential` mempertahankan uid).
  /// 3. Begitu sukses, [_authService.isAnonymous] SUDAH bernilai false —
  ///    [_userRepository] sekarang rute ke Firestore. Kalau snapshot dari
  ///    langkah 1 ditulis lewat [_userRepository] biasa di titik ini, itu
  ///    akan baca/tulis dokumen cloud yang masih kosong, BUKAN menyimpan
  ///    snapshot-nya. Makanya dipakai [UserRepository.migrateAnonymousSnapshot]
  ///    yang sengaja melewati routing itu.
  /// 4. Kalau langkah 3 gagal (mis. network error) SETELAH langkah 2
  ///    sudah sukses: akun tetap valid, cuma progresnya belum tersalin.
  ///    Set [_migrationWarning] alih-alih melempar exception —
  ///    user harus tetap bisa lanjut pakai app, bukan macet di sini.
  Future<String> _linkAndMigrate(Future<String> Function() link) async {
    final uid = _uid;
    Wallet? snapshotWallet;
    UserProfile? snapshotProfile;
    Map<String, MonsterProgress>? snapshotMonsters;
    if (uid != null && _authService.isAnonymous) {
      snapshotWallet = await _userRepository.getWallet(uid);
      snapshotProfile = await _userRepository.getUserProfile(uid);
      snapshotMonsters = await _userRepository.getMonsterProgress(uid);
    }

    final newUid = await link();
    _uid = newUid;

    _migrationWarning = false;
    if (snapshotWallet != null && snapshotProfile != null && snapshotMonsters != null) {
      try {
        await _userRepository.migrateAnonymousSnapshot(
          uid: newUid,
          wallet: snapshotWallet,
          profile: snapshotProfile,
          monsterProgress: snapshotMonsters,
        );
      } catch (_) {
        _migrationWarning = true;
      }
    }
    notifyListeners();
    return newUid;
  }

  Future<void> kirimResetKataSandi(String email) => _authService.sendPasswordResetEmail(email);

  Future<void> deleteAccount() => _authService.deleteAccount();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
