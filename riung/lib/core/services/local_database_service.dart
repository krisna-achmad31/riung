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
      version: 1,
      onCreate: (db, version) async {
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
  }

  Future<List<Map<String, Object?>>> allCheckIns() async {
    final db = await _database;
    return db.query('checkin_history', orderBy: 'created_at DESC');
  }
}
