import 'package:flutter_test/flutter_test.dart';

import 'package:riung/core/models/personality_result.dart';
import 'package:riung/features/kepribadian/logic/personality_config.dart';
import 'package:riung/features/kepribadian/logic/personality_scoring.dart';

Map<String, int> _all(PersonalityTest test, int Function(PersonalityQuestion q) pick) {
  return {for (final q in PersonalityConfig.questionsFor(test)) q.id: pick(q)};
}

void main() {
  group('jung', () {
    test('jumlah butir & tiap dimensi seimbang (3 per kutub)', () {
      expect(PersonalityConfig.jung.length, 24);
      for (final dim in PersonalityConfig.jungDimensions) {
        final items = PersonalityConfig.jung.where((q) => q.dimension == dim);
        expect(items.where((q) => q.key == dim[0]).length, 3, reason: dim);
        expect(items.where((q) => q.key == dim[1]).length, 3, reason: dim);
      }
    });

    test('setuju hanya pada kutub pertama → ESTJ dengan 100%', () {
      final answers = _all(PersonalityTest.jung, (q) => 'ESTJ'.contains(q.key) ? 5 : 1);
      final r = PersonalityScoring.score(PersonalityTest.jung, answers);
      expect(r.code, 'ESTJ');
      expect(r.scores['E'], 100);
      expect(r.scores['I'], 0);
    });

    test('setuju hanya pada kutub kedua → INFP', () {
      final answers = _all(PersonalityTest.jung, (q) => 'INFP'.contains(q.key) ? 5 : 1);
      final r = PersonalityScoring.score(PersonalityTest.jung, answers);
      expect(r.code, 'INFP');
      expect(r.scores['I'], 100);
      expect(r.scores['P'], 100);
    });

    test('semua netral (3) → seri jatuh ke kutub pertama, 50/50', () {
      final r = PersonalityScoring.score(PersonalityTest.jung, _all(PersonalityTest.jung, (_) => 3));
      expect(r.code, 'ESTJ');
      expect(r.scores['E'], 50);
      expect(r.scores['I'], 50);
    });

    test('persen bisa dihitung ulang: 2 dari 3 butir E setuju penuh', () {
      final answers = _all(PersonalityTest.jung, (q) => 3);
      // EI: butir E (1,3,5) → 5,5,3 ; butir I (2,4,6) → 3,3,3.  balance = 2+2+0 = 4, max = 12.
      answers['j_ei_1'] = 5;
      answers['j_ei_3'] = 5;
      final r = PersonalityScoring.score(PersonalityTest.jung, answers);
      expect(r.scores['E'], (50 + 50 * 4 / 12).round()); // 67
      expect(r.scores['I'], 100 - 67);
    });
  });

  group('temperamen', () {
    test('20 butir, 5 per temperamen', () {
      expect(PersonalityConfig.temperament.length, 20);
      for (final t in PersonalityConfig.temperaments) {
        expect(PersonalityConfig.temperament.where((q) => q.key == t).length, 5);
      }
    });

    test('dominan jelas tanpa campuran', () {
      final answers = _all(PersonalityTest.temperament, (q) => q.key == 'koleris' ? 5 : 2);
      final r = PersonalityScoring.score(PersonalityTest.temperament, answers);
      expect(r.code, 'koleris');
      expect(r.secondary, isNull);
      expect(r.scores.values.reduce((a, b) => a + b), inInclusiveRange(99, 101));
    });

    test('selisih tipis → campuran dengan temperamen kedua', () {
      final answers = _all(PersonalityTest.temperament, (q) => q.key == 'melankolis' ? 5 : (q.key == 'flegmatis' ? 5 : 2));
      answers['t_fle_1'] = 4; // flegmatis sedikit di bawah
      final r = PersonalityScoring.score(PersonalityTest.temperament, answers);
      expect(r.code, 'melankolis');
      expect(r.secondary, 'flegmatis');
    });
  });

  group('keterikatan', () {
    test('12 butir, 6 per dimensi, ada butir yang dibalik', () {
      expect(PersonalityConfig.attachment.length, 12);
      expect(PersonalityConfig.attachment.where((q) => q.key == 'cemas').length, 6);
      expect(PersonalityConfig.attachment.where((q) => q.reversed).isNotEmpty, isTrue);
    });

    test('rendah-rendah = aman', () {
      // setuju penuh pada butir dibalik, tidak setuju pada yang lain
      final answers = _all(PersonalityTest.attachment, (q) => q.reversed ? 5 : 1);
      final r = PersonalityScoring.score(PersonalityTest.attachment, answers);
      expect(r.code, 'aman');
      expect(r.scores['cemas'], 0);
      expect(r.scores['menghindar'], 0);
    });

    test('tinggi-tinggi = cemas_menghindar; tinggi-rendah = cemas; rendah-tinggi = menghindar', () {
      final both = _all(PersonalityTest.attachment, (q) => q.reversed ? 1 : 5);
      expect(PersonalityScoring.score(PersonalityTest.attachment, both).code, 'cemas_menghindar');
      final anx = _all(PersonalityTest.attachment, (q) => q.key == 'cemas' ? (q.reversed ? 1 : 5) : (q.reversed ? 5 : 1));
      expect(PersonalityScoring.score(PersonalityTest.attachment, anx).code, 'cemas');
      final avo = _all(PersonalityTest.attachment, (q) => q.key == 'menghindar' ? (q.reversed ? 1 : 5) : (q.reversed ? 5 : 1));
      expect(PersonalityScoring.score(PersonalityTest.attachment, avo).code, 'menghindar');
    });

    test('tepat di batas (3.0) dihitung rendah', () {
      final r = PersonalityScoring.score(PersonalityTest.attachment, _all(PersonalityTest.attachment, (_) => 3));
      expect(r.code, 'aman');
    });
  });

  test('isComplete menolak jawaban kurang', () {
    expect(PersonalityScoring.isComplete(PersonalityTest.jung, {'j_ei_1': 3}), isFalse);
    expect(PersonalityScoring.isComplete(PersonalityTest.jung, _all(PersonalityTest.jung, (_) => 3)), isTrue);
  });
}
