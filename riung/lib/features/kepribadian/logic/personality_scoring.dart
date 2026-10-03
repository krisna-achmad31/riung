import '../../../core/models/personality_result.dart';
import 'personality_config.dart';

/// Mesin skor tiga tes kepribadian — murni Dart, deterministik. Input =
/// jawaban `{idButir: 1..5}`; setiap persen bisa dihitung ulang dari
/// jawaban (CLAUDE.md aturan #8). Semua butir wajib terjawab.
abstract final class PersonalityScoring {
  static bool isComplete(PersonalityTest test, Map<String, int> answers) {
    return PersonalityConfig.questionsFor(test).every((q) => answers[q.id] != null);
  }

  static PersonalityResult score(PersonalityTest test, Map<String, int> answers, {DateTime? now}) {
    assert(isComplete(test, answers), 'Semua butir harus terjawab');
    final at = now ?? DateTime.now();
    switch (test) {
      case PersonalityTest.jung:
        return _scoreJung(answers, at);
      case PersonalityTest.temperament:
        return _scoreTemperament(answers, at);
      case PersonalityTest.attachment:
        return _scoreAttachment(answers, at);
    }
  }

  // ── Jung: 4 dimensi, tiap dimensi 6 butir (3 per kutub) ──
  static PersonalityResult _scoreJung(Map<String, int> answers, DateTime at) {
    final scores = <String, int>{};
    final code = StringBuffer();
    for (final dim in PersonalityConfig.jungDimensions) {
      final first = dim[0];
      final second = dim[1];
      final items = PersonalityConfig.jung.where((q) => q.dimension == dim);
      // Setuju pada butir kutub pertama menambah; pada kutub kedua mengurangi.
      var balance = 0; // rentang -(n*2) .. +(n*2)
      var maxBalance = 0;
      for (final q in items) {
        final centered = answers[q.id]! - PersonalityConfig.scaleMid;
        balance += q.key == first ? centered : -centered;
        maxBalance += PersonalityConfig.scaleMax - PersonalityConfig.scaleMid;
      }
      // Persen kutub pertama: 50% = imbang, 100% = sangat condong ke pertama.
      final firstPct = (50 + 50 * balance / maxBalance).round().clamp(0, 100);
      scores[first] = firstPct;
      scores[second] = 100 - firstPct;
      code.write(balance >= 0 ? first : second); // seri → kutub pertama
    }
    return PersonalityResult(test: PersonalityTest.jung, code: code.toString(), scores: scores, completedAt: at);
  }

  // ── Temperamen: jumlah skor per temperamen → porsi persen ──
  static PersonalityResult _scoreTemperament(Map<String, int> answers, DateTime at) {
    final sums = {for (final t in PersonalityConfig.temperaments) t: 0};
    for (final q in PersonalityConfig.temperament) {
      sums[q.key] = sums[q.key]! + answers[q.id]!;
    }
    final total = sums.values.fold<int>(0, (a, b) => a + b);
    final scores = {for (final e in sums.entries) e.key: (100 * e.value / total).round()};
    final ranked = PersonalityConfig.temperaments.toList()
      ..sort((a, b) {
        final byScore = sums[b]!.compareTo(sums[a]!);
        // Seri: urutan di config (deterministik).
        return byScore != 0 ? byScore : PersonalityConfig.temperaments.indexOf(a).compareTo(PersonalityConfig.temperaments.indexOf(b));
      });
    final gap = scores[ranked[0]]! - scores[ranked[1]]!;
    final secondary = gap <= PersonalityConfig.temperamentBlendGapPercent ? ranked[1] : null;
    return PersonalityResult(
      test: PersonalityTest.temperament,
      code: ranked[0],
      secondary: secondary,
      scores: scores,
      completedAt: at,
    );
  }

  // ── Keterikatan: rata-rata kecemasan & penghindaran → 4 gaya ──
  static PersonalityResult _scoreAttachment(Map<String, int> answers, DateTime at) {
    double mean(String key) {
      final items = PersonalityConfig.attachment.where((q) => q.key == key).toList();
      var sum = 0;
      for (final q in items) {
        final raw = answers[q.id]!;
        sum += q.reversed ? (PersonalityConfig.scaleMax + PersonalityConfig.scaleMin - raw) : raw;
      }
      return sum / items.length;
    }

    final anxiety = mean('cemas');
    final avoidance = mean('menghindar');
    final highAnxiety = anxiety > PersonalityConfig.attachmentCutoff;
    final highAvoidance = avoidance > PersonalityConfig.attachmentCutoff;
    final style = switch ((highAnxiety, highAvoidance)) {
      (false, false) => 'aman',
      (true, false) => 'cemas',
      (false, true) => 'menghindar',
      (true, true) => 'cemas_menghindar',
    };
    int pct(double m) => (100 * (m - PersonalityConfig.scaleMin) / (PersonalityConfig.scaleMax - PersonalityConfig.scaleMin)).round();
    return PersonalityResult(
      test: PersonalityTest.attachment,
      code: style,
      scores: {'cemas': pct(anxiety), 'menghindar': pct(avoidance)},
      completedAt: at,
    );
  }
}
