import 'journal_crypto_service.dart';
import 'jurnal_pin_service.dart';
import 'local_database_service.dart';
import 'local_prefs_store.dart';

/// Migrasi sekali jalan ke data lokal per akun (audit C-01). Sebelumnya
/// jurnal, check-in, kunci enkripsi, PIN, dan prefs domain-user berlaku
/// untuk seluruh perangkat; sekarang semuanya diserahkan ke pemilik
/// terakhir (`riung_uid`, atau akun yang sedang login bila tidak tercatat)
/// supaya akun lain di HP yang sama mulai kosong.
class LegacyAccountMigration {
  const LegacyAccountMigration._();

  /// No-op bila sudah pernah jalan, atau bila pemiliknya belum diketahui
  /// (belum pernah login sama sekali) — dicoba lagi saat start berikutnya.
  static Future<void> run({
    required LocalPrefsStore prefs,
    required String? currentUid,
    LocalDatabaseService? db,
    JournalCryptoService? crypto,
    JurnalPinService? pin,
  }) async {
    if (prefs.legacyAccountDataAdopted) return;
    final owner = prefs.userId ?? currentUid;
    if (owner == null) return;
    await (db ?? LocalDatabaseService()).adoptOrphanRows(owner);
    await (crypto ?? JournalCryptoService()).adoptLegacyKey(owner);
    await (pin ?? JurnalPinService()).adoptLegacyPin(owner);
    // Terakhir: penanda selesai ditulis di sini, jadi kalau langkah di atas
    // gagal, migrasi diulang utuh saat start berikutnya.
    await prefs.adoptLegacyAccountData(owner);
  }
}
