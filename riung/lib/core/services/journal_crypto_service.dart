import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Enkripsi AES-256-CBC untuk teks jurnal. Key dibuat sekali secara acak &
/// disimpan di `flutter_secure_storage` (Android Keystore / Keychain) —
/// tidak pernah di sqflite bersama teksnya. IV acak per entri, disimpan
/// bersama ciphertext (`ivBase64:cipherBase64`) karena IV bukan rahasia.
///
/// Kunci dibuat PER uid (`riung_jurnal_aes_key_v1_<uid>`): akun lain di HP
/// yang sama tidak bisa mendekripsi jurnal akun sebelumnya (audit C-01).
class JournalCryptoService {
  JournalCryptoService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  /// Kunci lama sebelum per-uid (satu kunci untuk seluruh perangkat) —
  /// hanya dibaca oleh [adoptLegacyKey].
  static const _legacyKeyStorageKey = 'riung_jurnal_aes_key_v1';
  static String _keyStorageKey(String uid) => '${_legacyKeyStorageKey}_$uid';

  final Map<String, enc.Key> _cachedKeys = {};

  /// Serahkan kunci lama (seluruh perangkat) ke [uid] — pemilik terakhir —
  /// supaya jurnal yang sudah ada tetap terbaca. Dipanggil sekali oleh
  /// [LegacyAccountMigration].
  Future<void> adoptLegacyKey(String uid) async {
    final legacy = await _secureStorage.read(key: _legacyKeyStorageKey);
    if (legacy == null) return;
    if (await _secureStorage.read(key: _keyStorageKey(uid)) == null) {
      await _secureStorage.write(key: _keyStorageKey(uid), value: legacy);
    }
    await _secureStorage.delete(key: _legacyKeyStorageKey);
    _cachedKeys.remove(uid);
  }

  /// Hapus semua kunci enkripsi jurnal di HP ini (hapus semua data) — sisa
  /// teks terenkripsi jadi tak terbaca.
  Future<void> deleteAllKeys() async {
    _cachedKeys.clear();
    final all = await _secureStorage.readAll();
    for (final key in all.keys.toList()) {
      if (key.startsWith(_legacyKeyStorageKey)) await _secureStorage.delete(key: key);
    }
  }

  Future<enc.Key> _getOrCreateKey(String uid) async {
    final cached = _cachedKeys[uid];
    if (cached != null) return cached;
    final existing = await _secureStorage.read(key: _keyStorageKey(uid));
    if (existing != null) {
      final key = enc.Key.fromBase64(existing);
      _cachedKeys[uid] = key;
      return key;
    }
    final key = enc.Key.fromSecureRandom(32);
    await _secureStorage.write(key: _keyStorageKey(uid), value: key.base64);
    _cachedKeys[uid] = key;
    return key;
  }

  Future<String> encryptText(String uid, String plainText) async {
    // `encrypt` 5.x melempar RangeError untuk input kosong; '' tetap
    // terbaca balik sebagai '' oleh [decryptText] (tanpa pemisah).
    if (plainText.isEmpty) return '';
    final key = await _getOrCreateKey(uid);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  Future<String> decryptText(String uid, String stored) async {
    final key = await _getOrCreateKey(uid);
    final separator = stored.indexOf(':');
    if (separator == -1) return '';
    final iv = enc.IV.fromBase64(stored.substring(0, separator));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(stored.substring(separator + 1), iv: iv);
  }
}
