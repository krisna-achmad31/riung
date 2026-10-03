import 'model_utils.dart';

/// Mirror `/users/{uid}.journalPinBackup` — backup PIN Jurnal untuk user
/// yang SUDAH login (bukan anonim), supaya PIN yang sama bisa diverifikasi
/// lagi di device baru (lihat `JurnalPinRecoverScreen`). Cuma hash + salt
/// yang disimpan, TIDAK PERNAH PIN plain text — beda dari
/// [JurnalPinService] lokal yang menyimpan PIN apa adanya di
/// `flutter_secure_storage` (gerbang lokal murni, bukan data yang
/// meninggalkan perangkat).
class JournalPinBackup {
  const JournalPinBackup({
    required this.hash,
    required this.salt,
    required this.updatedAt,
  });

  factory JournalPinBackup.fromMap(Map<String, dynamic> map) {
    return JournalPinBackup(
      hash: map[fHash] as String? ?? '',
      salt: map[fSalt] as String? ?? '',
      updatedAt: parseDate(map[fUpdatedAt]) ?? DateTime.now(),
    );
  }

  static const fHash = 'hash';
  static const fSalt = 'salt';
  static const fUpdatedAt = 'updatedAt';

  final String hash;
  final String salt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        fHash: hash,
        fSalt: salt,
        fUpdatedAt: updatedAt.toIso8601String(),
      };
}
