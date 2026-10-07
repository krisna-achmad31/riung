import 'model_utils.dart';

/// Hasil satu tes/kuis Kenali Dirimu — tersimpan HANYA di perangkat
/// (`LocalPrefsStore.kenaliResults`). Jawaban mentah tidak disimpan; skor &
/// persen bisa dihitung ulang dari jawaban lewat `KenaliScoring`.
class KenaliResult {
  const KenaliResult({
    required this.testId,
    required this.category,
    required this.completedAt,
    this.score,
    this.minScore,
    this.maxScore,
    this.dominantTrait,
    this.traitPercents = const {},
  });

  factory KenaliResult.fromMap(String testId, Map<String, dynamic> map) {
    return KenaliResult(
      testId: testId,
      category: map[fCategory] as String? ?? '',
      score: map[fScore] == null ? null : parseInt(map[fScore]),
      minScore: map[fMinScore] == null ? null : parseInt(map[fMinScore]),
      maxScore: map[fMaxScore] == null ? null : parseInt(map[fMaxScore]),
      dominantTrait: map[fDominantTrait] as String?,
      traitPercents: parseIntMap(map[fTraitPercents]),
      completedAt: parseDate(map[fCompletedAt]) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static const fCategory = 'category';
  static const fScore = 'score';
  static const fMinScore = 'minScore';
  static const fMaxScore = 'maxScore';
  static const fDominantTrait = 'dominantTrait';
  static const fTraitPercents = 'traitPercents';
  static const fCompletedAt = 'completedAt';

  /// Id tes (`KenaliTest.id`), jadi kunci penyimpanan.
  final String testId;

  /// Kategori hasil persis dari konten tes.
  final String category;

  /// Skor total (tes jumlah) beserta rentang mungkinnya.
  final int? score;
  final int? minScore;
  final int? maxScore;

  /// Trait terkuat (tes `trait_based`) — menentukan wujud monster.
  final String? dominantTrait;

  /// Persen per trait (0..100), urutan sesuai tes.
  final Map<String, int> traitPercents;
  final DateTime completedAt;

  Map<String, dynamic> toMap() => {
        fCategory: category,
        fScore: score,
        fMinScore: minScore,
        fMaxScore: maxScore,
        fDominantTrait: dominantTrait,
        fTraitPercents: traitPercents,
        fCompletedAt: completedAt.toIso8601String(),
      };

  KenaliResult copyWith({String? category, int? score, String? dominantTrait, Map<String, int>? traitPercents, DateTime? completedAt}) {
    return KenaliResult(
      testId: testId,
      category: category ?? this.category,
      score: score ?? this.score,
      minScore: minScore,
      maxScore: maxScore,
      dominantTrait: dominantTrait ?? this.dominantTrait,
      traitPercents: traitPercents ?? this.traitPercents,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
