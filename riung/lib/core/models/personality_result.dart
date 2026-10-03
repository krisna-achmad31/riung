import 'model_utils.dart';

/// Tiga tes profil kepribadian di fitur "Kenali dirimu".
enum PersonalityTest { jung, temperament, attachment }

/// Hasil satu tes — tersimpan lokal (`LocalPrefsStore.personalityResults`),
/// jawaban mentah TIDAK disimpan (hanya skor per dimensi) supaya tidak
/// ada data sensitif tambahan. Skor bisa dihitung ulang dari jawaban lewat
/// `PersonalityScoring` (config di `personality_config.dart`).
///
/// [code] = kode hasil: jung "INFP", temperamen "sanguinis", keterikatan
/// "aman". [scores] = persen per dimensi/kutub (0..100), kunci sesuai
/// tesnya (jung: E,I,S,N,T,F,J,P; temperamen: 4 kunci; keterikatan:
/// cemas, menghindar dalam skala 0..100).
class PersonalityResult {
  const PersonalityResult({
    required this.test,
    required this.code,
    required this.scores,
    required this.completedAt,
    this.secondary,
  });

  factory PersonalityResult.fromMap(PersonalityTest test, Map<String, dynamic> map) {
    return PersonalityResult(
      test: test,
      code: map[fCode] as String? ?? '',
      secondary: map[fSecondary] as String?,
      scores: parseIntMap(map[fScores]),
      completedAt: parseDate(map[fCompletedAt]) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static const fCode = 'code';
  static const fSecondary = 'secondary';
  static const fScores = 'scores';
  static const fCompletedAt = 'completedAt';

  final PersonalityTest test;
  final String code;

  /// Temperamen sekunder (hanya tes temperamen), atau null.
  final String? secondary;
  final Map<String, int> scores;
  final DateTime completedAt;

  Map<String, dynamic> toMap() => {
        fCode: code,
        fSecondary: secondary,
        fScores: scores,
        fCompletedAt: completedAt.toIso8601String(),
      };

  PersonalityResult copyWith({String? code, String? secondary, Map<String, int>? scores, DateTime? completedAt}) {
    return PersonalityResult(
      test: test,
      code: code ?? this.code,
      secondary: secondary ?? this.secondary,
      scores: scores ?? this.scores,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
