import 'package:flutter_test/flutter_test.dart';
import 'package:riung/features/onboarding/logic/scoring_engine.dart';

void main() {
  const engine = ScoringEngine();

  test('tanpa jawaban, semua skor 0', () {
    final result = engine.score(const {});
    for (final id in ScoringEngine.allSaboteurs) {
      expect(result.scoreOf(id), 0);
    }
  });

  test('Q9 opsi "aku nggak becus" (indeks 2) memberi hakim 3/13 = 23%', () {
    // Q9 single-select — hanya opsi indeks 2 yang menyumbang hakim (+3).
    // maxPossible hakim dijumlah dari semua Q yang menyinggung hakim:
    // Q3(+2) + Q6(+2) + Q7(+1) + Q9(+3) + Q12(+1) + Q13(+2) + Q14(+2) = 13.
    final result = engine.score({
      9: {2},
    });
    expect(result.hakimScore, 23);
  });

  test('Q3 multi-select hanya opsi "takut hasil" (indeks 0) → waswas 2/13 = 15%', () {
    final result = engine.score({
      3: {0},
    });
    expect(result.scoreOf('waswas'), 15);
  });

  test('Q3 multi-select 2 opsi waswas (indeks 0 & 5) menjumlah rawPoints', () {
    // idx0 "takut hasil" (+2) + idx5 "susah tidur" (+1) = 3/13 = 23%.
    final result = engine.score({
      3: {0, 5},
    });
    expect(result.scoreOf('waswas'), 23);
  });

  test('Q10 opsi terakhir (indeks 3) memberi mengelak DAN bonus kabut', () {
    // Q10 freq→mengelak 0/1/2/3; opsi indeks 3 juga memberi kabut+1 (spec:
    // "nggak pernah kumulai → Mengelak+3, Kabut+1").
    final result = engine.score({
      10: {3},
    });
    // mengelak: raw 3 / max(Q10:3 + Q11:4 + Q13:2 = 9) = 33%.
    expect(result.scoreOf('mengelak'), 33);
    // kabut: raw 1 / max(Q3:2 + Q5:3 + Q6:1 + Q7:2 + Q8:2 + Q10:1 + Q11:3 = 14) = 7%.
    expect(result.scoreOf('kabut'), 7);
  });

  test('pertanyaan konfigurasi (Q1, Q2, Q15–17) tidak memengaruhi skor', () {
    final withConfig = engine.score({
      1: {2},
      2: {1},
      9: {2},
      15: {0, 1, 2},
      16: {3},
      17: {0},
    });
    final withoutConfig = engine.score({
      9: {2},
    });
    expect(withConfig.scores, equals(withoutConfig.scores));
  });

  test('dominantSaboteurs diurutkan desc dan tidak menyertakan hakim', () {
    final result = engine.score({
      3: {0, 5}, // waswas tinggi
      9: {2}, // hakim tinggi (dipisah, bukan bagian anak buah)
    });
    expect(result.dominantSaboteurs, isNot(contains('hakim')));
    expect(result.dominantSaboteurs.length, 6);
    expect(result.dominantSaboteurs.first, 'waswas');
    expect(result.activeSaboteur, 'waswas');
    // Terurut menurun.
    for (var i = 0; i < result.dominantSaboteurs.length - 1; i++) {
      final a = result.scoreOf(result.dominantSaboteurs[i]);
      final b = result.scoreOf(result.dominantSaboteurs[i + 1]);
      expect(a, greaterThanOrEqualTo(b));
    }
  });

  test('opsi tak terpilih (mis. "langsung mengerjakan") tidak menyumbang skor', () {
    final result = engine.score({
      5: {0}, // "Langsung mengerjakan" — poin kosong
    });
    for (final id in ScoringEngine.allSaboteurs) {
      expect(result.scoreOf(id), 0);
    }
  });
}
