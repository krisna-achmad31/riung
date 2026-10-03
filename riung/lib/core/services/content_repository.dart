import '../models/affirmation.dart';
import '../models/saboteur.dart';
import 'dummy_data_loader.dart';

/// Interface konten publik. Implementasi asli membaca `/content/saboteurs`
/// & `/content/affirmations` di Firestore (disambungkan di M5). Sampai
/// saat itu, pakai [StubContentRepository].
abstract class ContentRepository {
  Future<List<Saboteur>> getSaboteurs();
  Future<List<Affirmation>> getAffirmations();
}

class StubContentRepository implements ContentRepository {
  StubContentRepository([DummyDataLoader? loader]) : _loader = loader ?? DummyDataLoader.instance;

  final DummyDataLoader _loader;
  List<Saboteur>? _cache;
  List<Affirmation>? _affirmationCache;

  @override
  Future<List<Saboteur>> getSaboteurs() async {
    final cached = _cache;
    if (cached != null) return cached;
    final data = await _loader.load();
    final raw = (data['saboteurs'] as List).cast<Map<String, dynamic>>();
    final saboteurs = raw.map(Saboteur.fromMap).toList();
    _cache = saboteurs;
    return saboteurs;
  }

  @override
  Future<List<Affirmation>> getAffirmations() async {
    final cached = _affirmationCache;
    if (cached != null) return cached;
    final data = await _loader.load();
    final raw = (data['affirmations'] as List).cast<Map<String, dynamic>>();
    final affirmations = raw.map(Affirmation.fromMap).toList();
    _affirmationCache = affirmations;
    return affirmations;
  }
}
