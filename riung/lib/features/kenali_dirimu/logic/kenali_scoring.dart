import '../../../core/models/kenali_result.dart';
import '../../../core/models/kenali_test.dart';

/// Skoring Kenali Dirimu — persis mengikuti `scoringLogic` di JSON tes,
/// jadi setiap angka bisa dihitung ulang dari jawaban (CLAUDE.md aturan #8).
///
/// Jawaban disimpan sebagai POSISI opsi (0 = paling kiri/jarang). Nilai
/// soal biasa = `options[pos].value`; soal `isReverse` = `reverseOptions[pos]`.
abstract final class KenaliScoring {
  static int valueOf(KenaliTest test, KenaliQuestion q, int position) {
    if (q.isReverse && test.scoring == KenaliScoringType.sumWithReverse && position < test.reverseValues.length) {
      return test.reverseValues[position];
    }
    return test.options[position].value;
  }

  static bool isComplete(KenaliTest test, Map<String, int> answers) =>
      test.questions.every((q) => answers[q.id] != null);

  static (int, int) _range(KenaliTest test, Iterable<KenaliQuestion> qs) {
    var lo = 0;
    var hi = 0;
    for (final q in qs) {
      final values = [for (var i = 0; i < test.options.length; i++) valueOf(test, q, i)];
      lo += values.reduce((a, b) => a < b ? a : b);
      hi += values.reduce((a, b) => a > b ? a : b);
    }
    return (lo, hi);
  }

  /// Persen 0..100 tiap trait = (jumlah − minimum) ÷ (maksimum − minimum).
  static Map<String, int> traitPercents(KenaliTest test, Map<String, int> answers) {
    final out = <String, int>{};
    for (final trait in test.traits) {
      final qs = test.questions.where((q) => q.trait == trait);
      var sum = 0;
      for (final q in qs) {
        final pos = answers[q.id];
        if (pos != null) sum += valueOf(test, q, pos);
      }
      final (lo, hi) = _range(test, qs);
      out[trait] = hi == lo ? 0 : ((sum - lo) * 100 / (hi - lo)).round().clamp(0, 100);
    }
    return out;
  }

  /// Trait terkuat; seri → yang muncul lebih dulu di soal.
  static String? dominantTrait(Map<String, int> percents) {
    String? best;
    for (final e in percents.entries) {
      if (best == null || e.value > percents[best]!) best = e.key;
    }
    return best;
  }

  static int totalScore(KenaliTest test, Map<String, int> answers) {
    var sum = 0;
    for (final q in test.questions) {
      final pos = answers[q.id];
      if (pos != null) sum += valueOf(test, q, pos);
    }
    return sum;
  }

  /// Rentang hasil yang memuat [score]; di luar semua rentang → terdekat.
  static KenaliOutcome outcomeForScore(KenaliTest test, int score) {
    KenaliOutcome? nearest;
    var gap = 1 << 30;
    for (final o in test.outcomes) {
      final lo = o.minScore ?? 0;
      final hi = o.maxScore ?? lo;
      if (score >= lo && score <= hi) return o;
      final d = score < lo ? lo - score : score - hi;
      if (d < gap) {
        gap = d;
        nearest = o;
      }
    }
    return nearest ?? test.outcomes.first;
  }

  /// Hasil yang tersimpan → outcome di [test] (bahasa apa pun): dicari dari
  /// trait dominan / skor, bukan dari teks kategori yang tersimpan.
  static KenaliOutcome? outcomeOf(KenaliTest test, KenaliResult result) {
    final trait = result.dominantTrait;
    if (trait != null) return test.outcomeForTrait(trait);
    final score = result.score;
    if (score != null && test.outcomes.isNotEmpty) return outcomeForScore(test, score);
    return null;
  }

  static KenaliResult score(KenaliTest test, Map<String, int> answers, {DateTime? now}) {
    final at = now ?? DateTime.now();
    if (test.scoring == KenaliScoringType.traitBased) {
      final percents = traitPercents(test, answers);
      final dominant = dominantTrait(percents);
      final outcome = dominant == null ? null : test.outcomeForTrait(dominant);
      return KenaliResult(
        testId: test.id,
        category: outcome?.category ?? '',
        dominantTrait: dominant,
        traitPercents: percents,
        completedAt: at,
      );
    }
    final total = totalScore(test, answers);
    final (lo, hi) = _range(test, test.questions);
    return KenaliResult(
      testId: test.id,
      category: outcomeForScore(test, total).category,
      score: total,
      minScore: lo,
      maxScore: hi,
      completedAt: at,
    );
  }
}
