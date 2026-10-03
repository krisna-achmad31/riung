import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// PIN 6 digit + biometrik untuk kunci Jurnal. PIN disimpan di
/// `flutter_secure_storage` (bukan sqflite) — gerbang lokal, bukan kredensial
/// server, jadi disimpan langsung (bukan hash) sudah memadai di penyimpanan
/// aman OS (Android Keystore / iOS Keychain).
class JurnalPinService {
  JurnalPinService({FlutterSecureStorage? secureStorage, LocalAuthentication? localAuth})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  static const _pinStorageKey = 'riung_jurnal_pin_v1';

  Future<bool> get hasPin async => (await _secureStorage.read(key: _pinStorageKey)) != null;

  Future<void> setPin(String pin) => _secureStorage.write(key: _pinStorageKey, value: pin);

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: _pinStorageKey);
    return stored != null && stored == pin;
  }

  Future<void> clearPin() => _secureStorage.delete(key: _pinStorageKey);

  /// Salt acak buat backup PIN ke cloud (lihat [JournalPinBackup]) — beda
  /// per user, supaya hash yang sama tidak bisa dicocokkan lintas akun.
  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Hash SHA-256 bergaram — dipakai HANYA untuk salinan cloud (Firestore),
  /// TIDAK PERNAH menggantikan penyimpanan lokal (yang tetap plain text di
  /// `flutter_secure_storage`, sudah aman lewat Android Keystore/Keychain —
  /// lihat catatan kelas di atas). PIN 6 digit numerik punya entropi
  /// rendah; salt di sini mencegah rainbow-table lintas user, bukan klaim
  /// tahan brute-force penuh — sepadan dengan threat model app ini (bukan
  /// kredensial finansial).
  String hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  Future<bool> get isBiometricAvailable async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
