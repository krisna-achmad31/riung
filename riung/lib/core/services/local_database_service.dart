import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Skema & akses sqflite mentah untuk `journal_entries` &
/// `checkin_history`. Query bertipe (via [JournalEntry]/[CheckIn]) ada di
/// [LocalUserRepository] — kelas ini murni lapisan tabel/SQL.
///
/// Database dibuka lazy (baru saat query pertama, bukan saat app start) —
/// startup tidak menunggu I/O yang tidak selalu dibutuhkan tiap sesi
/// (mis. kalau user tidak buka Jurnal/Check-in hari itu), dan supaya alur
/// yang tidak menyentuh Jurnal (mis. tes boot Splash→Onboarding) tidak
/// perlu platform channel sqflite sama sekali.
///
/// Sejak v3 setiap baris jurnal & check-in punya `user_id` dan semua query
/// difilter per uid — akun lain di HP yang sama tidak pernah membaca jurnal
/// atau mood akun sebelumnya (audit C-01). Baris lama (v2, `user_id` NULL)
/// diserahkan sekali ke pemilik terakhir lewat [adoptOrphanRows].
class LocalDatabaseService {
  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'riung.db');
    final db = await openDatabase(
      path,
      version: 3,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createOutbox(db);
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE journal_entries ADD COLUMN user_id TEXT');
          await db.execute('ALTER TABLE checkin_history ADD COLUMN user_id TEXT');
        }
      },
      onCreate: (db, version) async {
        await _createOutbox(db);
        await db.execute('''
          CREATE TABLE journal_entries (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            date TEXT NOT NULL,
            prompt_id TEXT,
            text_encrypted TEXT NOT NULL,
            mood TEXT,
            tags TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE checkin_history (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            date TEXT NOT NULL,
            mood TEXT,
            energy INTEGER,
            sleep_quality INTEGER,
            factors TEXT,
            intention TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  Future<void> insertJournalEntry(String uid, Map<String, Object?> row) async {
    final db = await _database;
    await db.insert('journal_entries', {...row, 'user_id': uid}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> allJournalEntries(String uid) async {
    final db = await _database;
    return db.query('journal_entries', where: 'user_id = ?', whereArgs: [uid], orderBy: 'created_at DESC');
  }

  Future<Map<String, Object?>?> journalEntryById(String uid, String id) async {
    final db = await _database;
    final rows = await db.query('journal_entries', where: 'user_id = ? AND id = ?', whereArgs: [uid, id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> journalEntryCountForDate(String uid, String isoDate) async {
    final db = await _database;
    final rows = await db.query('journal_entries', where: 'user_id = ? AND date = ?', whereArgs: [uid, isoDate]);
    return rows.length;
  }

  Future<void> insertCheckIn(String uid, Map<String, Object?> row) async {
    final db = await _database;
    await db.insert('checkin_history', {...row, 'user_id': uid}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Serahkan baris sebelum v3 (`user_id` NULL) ke [uid] — pemilik terakhir
  /// di HP ini. Dipanggil sekali oleh [LegacyAccountMigration].
  Future<void> adoptOrphanRows(String uid) async {
    final db = await _database;
    await db.update('journal_entries', {'user_id': uid}, where: 'user_id IS NULL');
    await db.update('checkin_history', {'user_id': uid}, where: 'user_id IS NULL');
  }

  /// Hapus semua jurnal & check-in (hapus akun).
  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete('journal_entries');
    await db.delete('checkin_history');
    await db.delete('outbox');
  }

  static Future<void> _createOutbox(Database db) => db.execute('''
    CREATE TABLE outbox (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL, body_json TEXT NOT NULL,
      created_at TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0
    )
  ''');

  Future<void> enqueueActivity(String id, String uid, String body, String createdAt) async {
    final db = await _database;
    await db.insert('outbox', {'id': id, 'user_id': uid, 'body_json': body, 'created_at': createdAt}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, Object?>>> pendingActivities(String uid) async =>
      (await _database).query('outbox', where: 'user_id = ?', whereArgs: [uid], orderBy: 'created_at ASC, id ASC', limit: 50);

  Future<void> removeActivity(String id) async => (await _database).delete('outbox', where: 'id = ?', whereArgs: [id]);
  Future<void> attemptActivity(String id) async => (await _database).rawUpdate('UPDATE outbox SET attempts = attempts + 1 WHERE id = ?', [id]);

  /// Buang aktivitas yang sudah dicoba [maxAttempts] kali tanpa diterima
  /// server (gagal permanen) supaya tidak menyumbat antrean selamanya.
  /// Mengembalikan jumlah baris yang dibuang.
  Future<int> dropExhaustedActivities(String uid, int maxAttempts) async =>
      (await _database).delete('outbox', where: 'user_id = ? AND attempts >= ?', whereArgs: [uid, maxAttempts]);

  Future<List<Map<String, Object?>>> allCheckIns(String uid) async {
    final db = await _database;
    return db.query('checkin_history', where: 'user_id = ?', whereArgs: [uid], orderBy: 'created_at DESC');
  }
}
