import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/affirmation.dart';
import '../../models/saboteur.dart';
import '../content_repository.dart';

/// Implementasi [ContentRepository] read-only lewat Firestore
/// (`/content/saboteurs`, `/content/affirmations` — satu dokumen per jenis
/// konten berisi field `items` array, supaya gampang diisi manual dari
/// Firebase Console, lihat `docs/setup-firebase.md`). Kalau dokumennya
/// belum diisi atau lagi offline tanpa cache, otomatis jatuh ke
/// [StubContentRepository] (dari `dummy-data-seed.json`) supaya layar tidak
/// pernah kosong.
class FirestoreContentRepository implements ContentRepository {
  FirestoreContentRepository({required FirebaseFirestore firestore, ContentRepository? fallback})
      : _firestore = firestore,
        _fallback = fallback ?? StubContentRepository();

  final FirebaseFirestore _firestore;
  final ContentRepository _fallback;
  List<Saboteur>? _saboteurCache;
  List<Affirmation>? _affirmationCache;

  @override
  Future<List<Saboteur>> getSaboteurs() async {
    final cached = _saboteurCache;
    if (cached != null) return cached;
    try {
      final snap = await _firestore.collection('content').doc('saboteurs').get();
      final items = (snap.data()?['items'] as List?)?.cast<Map<String, dynamic>>();
      if (items == null || items.isEmpty) return _fallback.getSaboteurs();
      final saboteurs = items.map(Saboteur.fromMap).toList();
      _saboteurCache = saboteurs;
      return saboteurs;
    } catch (_) {
      return _fallback.getSaboteurs();
    }
  }

  @override
  Future<List<Affirmation>> getAffirmations() async {
    final cached = _affirmationCache;
    if (cached != null) return cached;
    try {
      final snap = await _firestore.collection('content').doc('affirmations').get();
      final items = (snap.data()?['items'] as List?)?.cast<Map<String, dynamic>>();
      if (items == null || items.isEmpty) return _fallback.getAffirmations();
      // Gabung dengan seed bawaan per id, supaya kartu yang baru ditambah
      // di aplikasi tetap muncul walau dokumen Firestore belum diperbarui.
      final remote = items.map(Affirmation.fromMap).toList();
      final remoteIds = {for (final a in remote) a.id};
      final bundled = await _fallback.getAffirmations();
      final affirmations = [...remote, ...bundled.where((a) => !remoteIds.contains(a.id))];
      _affirmationCache = affirmations;
      return affirmations;
    } catch (_) {
      return _fallback.getAffirmations();
    }
  }
}
