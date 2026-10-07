import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/kenali_dirimu_config.dart';
import '../models/kenali_result.dart';
import 'journal_crypto_service.dart';
import 'local_prefs_store.dart';

/// Hasil Kenali Dirimu yang tersimpan di perangkat. Isinya bisa sensitif
/// (tes depresi, trauma, …), jadi disimpan TERENKRIPSI dengan kunci yang
/// sama dengan jurnal (CLAUDE.md aturan #5) dan tidak pernah dikirim ke
/// server. Didekripsi sekali saat start (`main.dart`) lalu di-cache supaya
/// layar bisa membacanya sinkron; [revision] naik tiap ada hasil baru.
class KenaliResultRepository {
  KenaliResultRepository._();

  static final KenaliResultRepository instance = KenaliResultRepository._();

  final JournalCryptoService _crypto = JournalCryptoService();
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Semua percobaan, terlama → terbaru.
  List<KenaliResult> _history = const [];
  Map<String, KenaliResult> _cache = const {};
  Future<void>? _loading;

  static const _fVersion = 'v';
  static const _fHistory = 'history';
  static const _fTestId = 'testId';

  /// Hasil TERBARU per tes, kunci = `KenaliTest.id`.
  Map<String, KenaliResult> get results => _cache;

  KenaliResult? resultOf(String testId) => _cache[testId];

  /// Semua percobaan, terbaru dulu (layar Riwayat).
  List<KenaliResult> get history => _history.reversed.toList(growable: false);

  /// Lupakan hasil di memori (setelah "Hapus semua data"), supaya hasil
  /// sensitif tidak tetap tampil sampai app dibuka ulang.
  void clearCache() {
    _history = const [];
    _cache = const {};
    _loading = null;
    revision.value++;
  }

  Future<void> load(LocalPrefsStore prefs) => _loading ??= _doLoad(prefs);

  void _setHistory(List<KenaliResult> all) {
    all.sort((a, b) => a.completedAt.compareTo(b.completedAt));
    // Simpan paling banyak [KenaliDirimuConfig.riwayatPerTes] percobaan per tes.
    final perTest = <String, int>{};
    final kept = <KenaliResult>[];
    for (final r in all.reversed) {
      final n = perTest[r.testId] = (perTest[r.testId] ?? 0) + 1;
      if (n <= KenaliDirimuConfig.riwayatPerTes) kept.add(r);
    }
    _history = kept.reversed.toList(growable: false);
    _cache = {for (final r in _history) r.testId: r};
  }

  Future<void> _doLoad(LocalPrefsStore prefs) async {
    final cipher = prefs.kenaliResultsCipher;
    if (cipher == null) return;
    try {
      final map = jsonDecode(await _crypto.decryptText(cipher)) as Map<String, dynamic>;
      final raw = map[_fHistory];
      _setHistory(raw is List
          ? [
              for (final e in raw)
                if (e is Map && e[_fTestId] is String) KenaliResult.fromMap(e[_fTestId] as String, e.cast<String, dynamic>()),
            ]
          // Format lama: { testId: hasil } — satu hasil per tes, tanpa riwayat.
          : [
              for (final e in map.entries)
                if (e.value is Map) KenaliResult.fromMap(e.key, (e.value as Map).cast<String, dynamic>()),
            ]);
      revision.value++;
    } catch (e) {
      // Kunci hilang (mis. setelah hapus akun) atau data rusak: mulai kosong.
      debugPrint('KenaliResultRepository: gagal membaca hasil ($e)');
    }
  }

  Future<void> save(LocalPrefsStore prefs, KenaliResult result) async {
    _setHistory([..._history, result]);
    revision.value++;
    try {
      final plain = jsonEncode({
        _fVersion: 2,
        _fHistory: [for (final r in _history) {_fTestId: r.testId, ...r.toMap()}],
      });
      await prefs.setKenaliResultsCipher(await _crypto.encryptText(plain));
    } catch (e) {
      // Secure storage tak tersedia: hasil tetap ada di sesi ini saja.
      debugPrint('KenaliResultRepository: gagal menyimpan hasil ($e)');
    }
  }
}
