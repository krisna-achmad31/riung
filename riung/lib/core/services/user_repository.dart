import '../models/affirmation.dart';
import '../models/check_in.dart';
import '../models/journal_entry.dart';
import '../models/journal_pin_backup.dart';
import '../models/monster_progress.dart';
import '../models/user_profile.dart';
import '../models/wallet.dart';

/// Interface data pengguna. Implementasi asli membaca Firestore
/// (`/users/{uid}`, subcollections) — disambungkan di M5. Sejak M3, data
/// pribadi (profil, jurnal, check-in, progres monster) sudah persisten
/// SUNGGUHAN di perangkat lewat [LocalUserRepository]
/// (shared_preferences + sqflite terenkripsi), bukan lagi dummy in-memory.
abstract class UserRepository {
  Future<UserProfile> getUserProfile(String uid);
  Future<Wallet> getWallet(String uid);
  Future<Map<String, MonsterProgress>> getMonsterProgress(String uid);
  Future<List<CheckIn>> getCheckIns(String uid);
  Future<List<JournalEntry>> getJournalEntries(String uid);

  /// Menyimpan sub-map profile/premium/streak/assessment (bukan wallet —
  /// itu hanya lewat [WalletFunctionsService], lihat CLAUDE.md aturan #5).
  Future<void> saveUserProfile(UserProfile profile);

  Future<void> saveMonsterProgress(String uid, Map<String, MonsterProgress> progress);

  /// Menyimpan satu entri check-in ke `checkin_history` (sqflite).
  Future<CheckIn> saveCheckIn(String uid, CheckIn checkIn);

  /// true kalau sudah ada entri check-in untuk tanggal hari ini.
  Future<bool> hasCheckedInToday(String uid);

  /// Menyimpan satu entri jurnal (teks sudah dienkripsi pemanggil) ke
  /// `journal_entries` (sqflite).
  Future<JournalEntry> saveJournalEntry(String uid, JournalEntry entry);

  /// Jumlah entri jurnal pada tanggal tertentu — dipakai gerbang free-tier
  /// 1 entri/hari (CLAUDE.md §3).
  Future<int> journalEntryCountForDate(String uid, DateTime date);

  /// Id afirmasi (bawaan maupun buatan sendiri) yang ditandai favorit.
  Future<Set<String>> getFavoriteAffirmationIds(String uid);
  Future<void> setFavoriteAffirmationIds(String uid, Set<String> ids);

  /// Afirmasi yang ditulis sendiri oleh pengguna, tersimpan lokal.
  Future<List<Affirmation>> getCustomAffirmations(String uid);
  Future<Affirmation> saveCustomAffirmation(String uid, Affirmation affirmation);

  /// Backup hash+salt PIN Jurnal ke cloud (Fix: PIN fallback lintas
  /// device) — HANYA dipanggil untuk user yang sudah login (bukan
  /// anonim), lihat [JurnalPinSetupScreen]. Implementasi lokal murni
  /// (dipakai saat anonim) sengaja no-op/null — backup lintas device
  /// tidak relevan sebelum ada akun permanen.
  Future<void> saveJournalPinBackup(String uid, JournalPinBackup backup);

  /// Hapus SEMUA data pribadi di perangkat (jurnal, check-in, kunci
  /// enkripsi, preferensi & progres) — dipanggil setelah akun berhasil dihapus.
  Future<void> deleteAllLocalData();

  /// Hapus salinan cloud (dokumen pengguna + catatan koin) — dipanggil SEBELUM
  /// akun dihapus karena butuh sesi masuk. Implementasi lokal: tidak ada yang dihapus.
  Future<void> deleteCloudData(String uid);
  Future<JournalPinBackup?> getJournalPinBackup(String uid);

  /// Poin 4d — tulis snapshot wallet/profil/progres monster yang
  /// terkumpul SELAMA ANONIM ke Firestore, PERSIS SEKALI, tepat setelah
  /// anon→akun permanen sukses (lihat `AuthNotifier._linkAndMigrate`).
  /// SENGAJA tidak lewat jalur isAnonymous()-routing method lain di
  /// kelas ini (getWallet/saveUserProfile/dst) — begitu link sukses,
  /// isAnonymous() sudah bernilai false, jadi method lain akan salah
  /// baca/tulis dokumen cloud yang masih kosong alih-alih menyimpan
  /// snapshot ini. Full overwrite (bukan merge parsial) supaya tidak ada
  /// race dengan data lama yang mungkin sudah ada.
  Future<void> migrateAnonymousSnapshot({
    required String uid,
    required Wallet wallet,
    required UserProfile profile,
    required Map<String, MonsterProgress> monsterProgress,
  });
}
