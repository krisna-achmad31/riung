import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/config/kenali_dirimu_config.dart';
import 'package:riung/core/models/kenali_test.dart';
import 'package:riung/features/kenali_dirimu/logic/kenali_scoring.dart';

KenaliTest _load(KenaliEntry entry) =>
    KenaliTest.fromMap(jsonDecode(File(entry.asset).readAsStringSync()) as Map<String, dynamic>);

void main() {
  test('setiap entri katalog punya JSON dengan id yang sama & bisa diskor', () {
    for (final entry in KenaliDirimuConfig.entries) {
      final test = _load(entry);
      expect(test.id, entry.id, reason: entry.file);
      expect(test.questions, isNotEmpty, reason: entry.file);
      // Semua jawaban di opsi pertama → harus selalu menghasilkan hasil.
      final answers = {for (final q in test.questions) q.id: 0};
      expect(KenaliScoring.isComplete(test, answers), isTrue, reason: entry.file);
      final result = KenaliScoring.score(test, answers);
      expect(result.category, isNotEmpty, reason: entry.file);
    }
  });

  test('terjemahan EN lengkap untuk setiap tes & tidak mengubah skor', () {
    for (final entry in KenaliDirimuConfig.entries) {
      final base = _load(entry);
      final file = File(entry.translationAsset('en'));
      expect(file.existsSync(), isTrue, reason: file.path);
      final t = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect((t['options'] as List).length, base.options.length, reason: entry.file);
      expect((t['results'] as List).length, base.outcomes.length, reason: entry.file);
      final texts = (t['questions'] as Map).cast<String, dynamic>();
      expect(texts.keys.toSet(), base.questions.map((q) => q.id).toSet(), reason: entry.file);
      final en = base.withTranslation(t);
      final answers = {for (final q in base.questions) q.id: base.options.length - 1};
      final a = KenaliScoring.score(base, answers);
      final b = KenaliScoring.score(en, answers);
      expect(b.score, a.score, reason: entry.file);
      expect(b.dominantTrait, a.dominantTrait, reason: entry.file);
      expect(KenaliScoring.outcomeOf(en, a)?.description, isNot(KenaliScoring.outcomeOf(base, a)?.description), reason: entry.file);
    }
  });

  test('tes kesehatan: skor bisa dihitung ulang dari jawaban & masuk rentang', () {
    final test = _load(KenaliDirimuConfig.byId('anxiety_test')!);
    final answers = {for (final q in test.questions) q.id: 2};
    final expected = test.questions.fold<int>(0, (sum, q) => sum + KenaliScoring.valueOf(test, q, 2));
    final result = KenaliScoring.score(test, answers);
    expect(result.score, expected);
    expect(result.score, inInclusiveRange(result.minScore!, result.maxScore!));
  });

  test('kuis besar: persen per trait 0–100 dan trait dominan = tertinggi', () {
    final test = _load(KenaliDirimuConfig.byId('procrastination_profile')!);
    final last = test.options.length - 1;
    final target = test.traits.first;
    final answers = {for (final q in test.questions) q.id: q.trait == target ? last : 0};
    final result = KenaliScoring.score(test, answers);
    for (final p in result.traitPercents.values) {
      expect(p, inInclusiveRange(0, 100));
    }
    expect(result.dominantTrait, target);
    expect(result.traitPercents[target], 100);
  });
}
