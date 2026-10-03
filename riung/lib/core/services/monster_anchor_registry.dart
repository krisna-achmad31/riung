import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/monster_anchor.dart';

const String monsterAnchorsAsset = 'assets/monsters/anchors.json';

/// Memuat & meng-cache `assets/monsters/anchors.json`. Satu-satunya sumber
/// data untuk [RiungMonster] (CLAUDE.md aturan #7): ukuran, pivot & aspek
/// kosmetik ada di JSON, jadi tidak perlu membaca file gambar saat start.
class MonsterAnchorRegistry {
  MonsterAnchorRegistry._();

  static final MonsterAnchorRegistry instance = MonsterAnchorRegistry._();

  MonsterAnchorData? _cache;
  Future<MonsterAnchorData>? _loading;

  /// Data ter-cache bila sudah pernah dimuat (mis. di-pre-warm di `main()`).
  MonsterAnchorData? get dataOrNull => _cache;

  Future<MonsterAnchorData> load() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return _loading ??= _doLoad();
  }

  Future<MonsterAnchorData> _doLoad() async {
    final raw = await rootBundle.loadString(monsterAnchorsAsset);
    final data = MonsterAnchorData.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    _cache = data;
    return data;
  }
}
