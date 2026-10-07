import 'model_utils.dart';

/// Cara skor satu tes Kenali Dirimu (`scoringLogic.type` di JSON).
enum KenaliScoringType {
  /// Tiap soal menambah poin ke satu `trait`; hasil = trait terkuat.
  traitBased,

  /// Jumlah nilai opsi; hasil = rentang `minScore..maxScore`.
  sumStandard,

  /// Seperti [sumStandard], tapi soal `isReverse` memakai `reverseOptions`.
  sumWithReverse;

  static KenaliScoringType fromJson(String? raw) => switch (raw) {
        'trait_based' => traitBased,
        'sum_with_reverse' => sumWithReverse,
        _ => sumStandard,
      };

  bool get isSum => this != traitBased;
}

/// Satu pilihan jawaban (nilai + label tampil).
class KenaliOption {
  const KenaliOption({required this.value, required this.label});

  factory KenaliOption.fromMap(Map<String, dynamic> map) =>
      KenaliOption(value: parseInt(map[fValue]), label: map[fLabel] as String? ?? '');

  static const fValue = 'value';
  static const fLabel = 'label';

  final int value;
  final String label;
}

/// Satu soal. [trait] hanya untuk tes `trait_based`.
class KenaliQuestion {
  const KenaliQuestion({required this.id, required this.text, this.trait, this.isReverse = false});

  factory KenaliQuestion.fromMap(Map<String, dynamic> map) => KenaliQuestion(
        id: map[fId] as String,
        text: map[fText] as String? ?? '',
        trait: map[fTrait] as String?,
        isReverse: map[fIsReverse] as bool? ?? false,
      );

  static const fId = 'id';
  static const fText = 'text';
  static const fTrait = 'trait';
  static const fIsReverse = 'isReverse';

  final String id;
  final String text;
  final String? trait;
  final bool isReverse;
}

/// Satu kemungkinan hasil: rentang skor (tes jumlah) atau trait dominan.
class KenaliOutcome {
  const KenaliOutcome({required this.category, required this.description, this.minScore, this.maxScore, this.dominantTrait});

  factory KenaliOutcome.fromMap(Map<String, dynamic> map) => KenaliOutcome(
        category: map[fCategory] as String? ?? '',
        description: map[fDescription] as String? ?? '',
        minScore: map[fMinScore] == null ? null : parseInt(map[fMinScore]),
        maxScore: map[fMaxScore] == null ? null : parseInt(map[fMaxScore]),
        dominantTrait: map[fDominantTrait] as String?,
      );

  static const fCategory = 'category';
  static const fDescription = 'description';
  static const fMinScore = 'minScore';
  static const fMaxScore = 'maxScore';
  static const fDominantTrait = 'dominantTrait';

  /// Mis. "The Perfectionist (Si Takut Salah)" atau "Kecemasan Sedang".
  final String category;
  final String description;
  final int? minScore;
  final int? maxScore;
  final String? dominantTrait;

  /// Bagian sebelum kurung: "The Perfectionist".
  String get title {
    final i = category.indexOf('(');
    return (i < 0 ? category : category.substring(0, i)).trim();
  }

  /// Isi kurung bila ada: "Si Takut Salah".
  String? get alias {
    final open = category.indexOf('(');
    final close = category.lastIndexOf(')');
    if (open < 0 || close <= open) return null;
    return category.substring(open + 1, close).trim();
  }
}

/// Isi satu tes dari `assets/data/know_yourself/<file>.json` — konten
/// bundel (read-only), bukan data pengguna.
class KenaliTest {
  const KenaliTest({
    required this.id,
    required this.title,
    required this.description,
    required this.theoryReference,
    required this.scoring,
    required this.options,
    required this.reverseValues,
    required this.questions,
    required this.outcomes,
  });

  factory KenaliTest.fromMap(Map<String, dynamic> map) {
    final logic = (map[fScoringLogic] as Map?)?.cast<String, dynamic>() ?? const {};
    List<Map<String, dynamic>> list(Object? raw) => [for (final e in (raw as List? ?? const [])) (e as Map).cast<String, dynamic>()];
    return KenaliTest(
      id: map[fId] as String,
      title: map[fTitle] as String? ?? '',
      description: map[fDescription] as String? ?? '',
      theoryReference: map[fTheoryReference] as String? ?? '',
      scoring: KenaliScoringType.fromJson(logic[fType] as String?),
      options: [for (final o in list(logic[fOptions])) KenaliOption.fromMap(o)],
      reverseValues: [for (final o in list(logic[fReverseOptions])) parseInt(o[KenaliOption.fValue])],
      questions: [for (final q in list(map[fQuestions])) KenaliQuestion.fromMap(q)],
      outcomes: [for (final r in list(map[fResults])) KenaliOutcome.fromMap(r)],
    );
  }

  static const fId = 'id';
  static const fTitle = 'title';
  static const fDescription = 'description';
  static const fTheoryReference = 'theoryReference';
  static const fScoringLogic = 'scoringLogic';
  static const fType = 'type';
  static const fOptions = 'options';
  static const fReverseOptions = 'reverseOptions';
  static const fQuestions = 'questions';
  static const fResults = 'results';

  final String id;
  final String title;
  final String description;
  final String theoryReference;
  final KenaliScoringType scoring;

  /// Opsi berurutan dari "paling jarang" ke "paling sering".
  final List<KenaliOption> options;

  /// Nilai pengganti per POSISI opsi untuk soal `isReverse`.
  final List<int> reverseValues;
  final List<KenaliQuestion> questions;
  final List<KenaliOutcome> outcomes;

  /// Urutan trait sesuai urutan kemunculan di soal.
  List<String> get traits => <String>{
        for (final q in questions)
          if (q.trait != null) q.trait!,
      }.toList();

  /// Salinan dengan teks dari terjemahan (`assets/data/know_yourself/<bahasa>/`).
  /// Terjemahan hanya berisi teks — id, nilai, rentang skor, dan trait
  /// selalu dari JSON utama, jadi skor identik di semua bahasa. Teks yang
  /// tidak ada di terjemahan tetap memakai aslinya.
  KenaliTest withTranslation(Map<String, dynamic> t) {
    final optionLabels = (t[fOptions] as List?)?.cast<String>() ?? const <String>[];
    final questionTexts = (t[fQuestions] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final results = [for (final e in (t[fResults] as List? ?? const [])) (e as Map).cast<String, dynamic>()];
    return KenaliTest(
      id: id,
      title: t[fTitle] as String? ?? title,
      description: t[fDescription] as String? ?? description,
      theoryReference: theoryReference,
      scoring: scoring,
      options: [
        for (var i = 0; i < options.length; i++)
          KenaliOption(value: options[i].value, label: i < optionLabels.length ? optionLabels[i] : options[i].label),
      ],
      reverseValues: reverseValues,
      questions: [
        for (final q in questions)
          KenaliQuestion(id: q.id, text: questionTexts[q.id] as String? ?? q.text, trait: q.trait, isReverse: q.isReverse),
      ],
      outcomes: [
        for (var i = 0; i < outcomes.length; i++)
          KenaliOutcome(
            category: i < results.length ? results[i][KenaliOutcome.fCategory] as String? ?? outcomes[i].category : outcomes[i].category,
            description: i < results.length ? results[i][KenaliOutcome.fDescription] as String? ?? outcomes[i].description : outcomes[i].description,
            minScore: outcomes[i].minScore,
            maxScore: outcomes[i].maxScore,
            dominantTrait: outcomes[i].dominantTrait,
          ),
      ],
    );
  }

  KenaliOutcome? outcomeForTrait(String trait) {
    for (final o in outcomes) {
      if (o.dominantTrait == trait) return o;
    }
    return null;
  }
}
