import 'onboarding_questions.dart';

/// Hasil skoring — persis `docs/assessment-scoring-spec.md`: skor 0–100
/// per saboteur (termasuk Hakim), anak buah (non-Hakim) diurutkan desc.
class AssessmentResult {
  const AssessmentResult({required this.scores, required this.dominantSaboteurs});

  final Map<String, int> scores;

  /// 6 anak buah (bukan Hakim), diurutkan dari skor tertinggi.
  final List<String> dominantSaboteurs;

  int scoreOf(String saboteurId) => scores[saboteurId] ?? 0;
  int get hakimScore => scoreOf('hakim');

  /// Saboteur paling aktif di antara ke-6 anak buah — target latihan awal.
  String get activeSaboteur => dominantSaboteurs.first;
}

/// Mesin skoring asesmen — implementasi persis
/// `docs/assessment-scoring-spec.md`:
/// score(m) = round( rawPoints(m) / maxPossiblePoints(m) × 100 ).
/// `rawPoints` = jumlah poin opsi terpilih; `maxPossiblePoints` = jumlah
/// semua opsi relevan (multi-select) atau opsi bernilai tertinggi
/// (single-select), dihitung dari mapping di [onboardingQuestions] —
/// bukan angka hardcode per layar.
class ScoringEngine {
  const ScoringEngine();

  static const List<String> allSaboteurs = [
    'meronta',
    'waswas',
    'kabut',
    'cermin',
    'sempurna',
    'mengelak',
    'hakim',
  ];

  /// [answers]: nomor pertanyaan (1–17) → indeks opsi yang dipilih.
  /// Single-select cukup berisi satu indeks per set.
  AssessmentResult score(Map<int, Set<int>> answers) {
    final raw = <String, int>{for (final id in allSaboteurs) id: 0};
    final maxPossible = <String, int>{for (final id in allSaboteurs) id: 0};

    for (final question in onboardingQuestions) {
      if (!question.isScored) continue;

      final selected = answers[question.number] ?? const <int>{};
      for (final index in selected) {
        if (index < 0 || index >= question.options.length) continue;
        question.options[index].points.forEach((id, points) {
          raw[id] = (raw[id] ?? 0) + points;
        });
      }

      if (question.isMulti) {
        // Multi-select: semua opsi relevan bisa dicentang sekaligus.
        for (final option in question.options) {
          option.points.forEach((id, points) {
            maxPossible[id] = (maxPossible[id] ?? 0) + points;
          });
        }
      } else {
        // Single-select: hanya satu opsi bisa dipilih — ambil yang tertinggi.
        final highestPerSaboteur = <String, int>{};
        for (final option in question.options) {
          option.points.forEach((id, points) {
            if (points > (highestPerSaboteur[id] ?? 0)) {
              highestPerSaboteur[id] = points;
            }
          });
        }
        highestPerSaboteur.forEach((id, points) {
          maxPossible[id] = (maxPossible[id] ?? 0) + points;
        });
      }
    }

    final scores = <String, int>{
      for (final id in allSaboteurs)
        id: (maxPossible[id] ?? 0) == 0
            ? 0
            : ((raw[id]! / maxPossible[id]!) * 100).round().clamp(0, 100),
    };

    final dominantSaboteurs = allSaboteurs.where((id) => id != 'hakim').toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    return AssessmentResult(scores: scores, dominantSaboteurs: dominantSaboteurs);
  }
}
