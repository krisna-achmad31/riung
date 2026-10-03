import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Enkripsi AES-256-CBC untuk teks jurnal. Key dibuat sekali secara acak &
/// disimpan di `flutter_secure_storage` (Android Keystore / Keychain) —
/// tidak pernah di sqflite bersama teksnya. IV acak per entri, disimpan
/// bersama ciphertext (`ivBase64:cipherBase64`) karena IV bukan rahasia.
class JournalCryptoService {
  JournalCryptoService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const _keyStorageKey = 'riung_jurnal_aes_key_v1';

  enc.Key? _cachedKey;

  /// Hapus kunci enkripsi jurnal (hapus akun) — sisa teks terenkripsi jadi tak terbaca.
  Future<void> deleteKey() async {
    _cachedKey = null;
    await _secureStorage.delete(key: _keyStorageKey);
  }

  Future<enc.Key> _getOrCreateKey() async {
    final cached = _cachedKey;
    if (cached != null) return cached;
    final existing = await _secureStorage.read(key: _keyStorageKey);
    if (existing != null) {
      final key = enc.Key.fromBase64(existing);
      _cachedKey = key;
      return key;
    }
    final key = enc.Key.fromSecureRandom(32);
    await _secureStorage.write(key: _keyStorageKey, value: key.base64);
    _cachedKey = key;
    return key;
  }

  Future<String> encryptText(String plainText) async {
    final key = await _getOrCreateKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  Future<String> decryptText(String stored) async {
    final key = await _getOrCreateKey();
    final separator = stored.indexOf(':');
    if (separator == -1) return '';
    final iv = enc.IV.fromBase64(stored.substring(0, separator));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(stored.substring(separator + 1), iv: iv);
  }
}
