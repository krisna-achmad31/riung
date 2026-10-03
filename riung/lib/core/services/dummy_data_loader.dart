import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Memuat & meng-cache `assets/data/dummy-data-seed.json` — sumber data
/// dummy bagi semua implementasi stub service sebelum Firebase disambungkan
/// di M5 (lihat CLAUDE.md catatan M0).
class DummyDataLoader {
  DummyDataLoader._();

  static final DummyDataLoader instance = DummyDataLoader._();

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/data/dummy-data-seed.json');
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    _cache = parsed;
    return parsed;
  }
}
