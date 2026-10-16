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
class LocalDatabaseService {
  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'riung.db');
    final db = await openDatabase(
      path,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createOutbox(db);
      },
      onCreate: (db, version) async {
        await _createOutbox(db);
        await db.execute('''
          CREATE TABLE journal_entries (
            id TEXT PRIMARY KEY,
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

  Future<void> insertJournalEntry(Map<String, Object?> row) async {
    final db = await _database;
    await db.insert('journal_entries', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> allJournalEntries() async {
    final db = await _database;
    return db.query('journal_entries', orderBy: 'created_at DESC');
  }

  Future<Map<String, Object?>?> journalEntryById(String id) async {
    final db = await _database;
    final rows = await db.query('journal_entries', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> journalEntryCountForDate(String isoDate) async {
    final db = await _database;
    final rows = await db.query('journal_entries', where: 'date = ?', whereArgs: [isoDate]);
    return rows.length;
  }

  Future<void> insertCheckIn(Map<String, Object?> row) async {
    final db = await _database;
    await db.insert('checkin_history', row, conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<List<Map<String, Object?>>> allCheckIns() async {
    final db = await _database;
    return db.query('checkin_history', orderBy: 'created_at DESC');
  }
}
