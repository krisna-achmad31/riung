import 'package:flutter_test/flutter_test.dart';

import 'package:riung/core/models/check_in.dart';
import 'package:riung/core/models/journal_entry.dart';
import 'package:riung/core/services/jurnal_pin_service.dart';
import 'package:riung/features/checkin/logic/checkin_draft.dart';
import 'package:riung/features/checkin/logic/checkin_options.dart';
import 'package:riung/features/jurnal/logic/journal_prompts.dart';

void main() {
  group('Check-in Draft & Options', () {
    test('5 opsi mood dan 10 opsi faktor tersedia', () {
      expect(checkInMoods.length, 5);
      final moodIds = checkInMoods.map((m) => m.id).toList();
      expect(moodIds, containsAll(['berat', 'agak_berat', 'datar', 'cukup_baik', 'senang']));

      expect(checkInFactors.length, 10);
      final factorIds = checkInFactors.map((f) => f.id).toList();
      expect(factorIds, containsAll(['kerjaan', 'kuliah', 'takut_gagal', 'keluarga', 'uang', 'hubungan', 'kurang_tidur', 'kesehatan', 'medsos', 'lainnya']));
    });

    test('CheckInDraft menyimpan state wizard sementara', () {
      final draft = CheckInDraft();
      expect(draft.moodId, isNull);
      expect(draft.factorIds, isEmpty);
      expect(draft.note, isEmpty);

      draft.moodId = 'senang';
      draft.factorIds.addAll(['keluarga', 'kesehatan']);
      draft.note = 'Hari yang produktif';

      expect(draft.moodId, 'senang');
      expect(draft.factorIds.length, 2);
      expect(draft.note, 'Hari yang produktif');
    });
  });

  group('CheckIn Model', () {
    test('fromMap dan toMap bolak-balik dengan benar', () {
      final date = DateTime(2026, 10, 12);
      final checkin = CheckIn(
        date: date,
        mood: 'cukup_baik',
        energy: 4,
        sleepQuality: 5,
        factors: const ['kerjaan', 'kesehatan'],
        intention: 'Fokus menyelesaikan tugas',
      );

      final map = checkin.toMap();
      expect(map[CheckIn.fDate], '2026-10-12');
      expect(map[CheckIn.fMood], 'cukup_baik');
      expect(map[CheckIn.fEnergy], 4);
      expect(map[CheckIn.fSleepQuality], 5);
      expect(map[CheckIn.fFactors], ['kerjaan', 'kesehatan']);
      expect(map[CheckIn.fIntention], 'Fokus menyelesaikan tugas');

      final parsed = CheckIn.fromMap(map);
      expect(parsed.mood, checkin.mood);
      expect(parsed.factors, checkin.factors);
      expect(parsed.intention, checkin.intention);
      expect(parsed.date.year, date.year);
      expect(parsed.date.month, date.month);
      expect(parsed.date.day, date.day);
    });

    test('copyWith memperbarui field yang diberikan', () {
      final c1 = CheckIn(date: DateTime(2026, 1, 1), mood: 'datar');
      final c2 = c1.copyWith(mood: 'senang', intention: 'Semangat baru');

      expect(c2.mood, 'senang');
      expect(c2.intention, 'Semangat baru');
      expect(c2.date, c1.date);
    });
  });

  group('JournalEntry Model & Prompts', () {
    test('JournalEntry fromMap dan toMap bolak-balik', () {
      final now = DateTime(2026, 10, 12, 14, 30);
      final entry = JournalEntry(
        entryId: 'j_001',
        promptId: 'p_hakim',
        mood: 'agak_berat',
        text: 'Aku merasa terlalu keras pada diriku sendiri.',
        tags: const ['hakim', 'kerjaan'],
        createdAt: now,
      );

      final map = entry.toMap();
      expect(map[JournalEntry.fPromptId], 'p_hakim');
      expect(map[JournalEntry.fMood], 'agak_berat');
      expect(map[JournalEntry.fText], 'Aku merasa terlalu keras pada diriku sendiri.');
      expect(map[JournalEntry.fTags], ['hakim', 'kerjaan']);
      expect(map[JournalEntry.fCreatedAt], now.toIso8601String());

      final parsed = JournalEntry.fromMap('j_001', map);
      expect(parsed.entryId, 'j_001');
      expect(parsed.promptId, entry.promptId);
      expect(parsed.mood, entry.mood);
      expect(parsed.text, entry.text);
      expect(parsed.tags, entry.tags);
      expect(parsed.createdAt, entry.createdAt);
    });

    test('journalPrompts memiliki daftar prompt monster yang valid', () {
      expect(journalPrompts.length, 5);
      final monsterIds = journalPrompts.map((p) => p.monsterId).toSet();
      expect(monsterIds, containsAll(['hakim', 'kabut', 'cermin', 'waswas', 'mengelak']));
    });
  });

  group('JurnalPinService Cryptography', () {
    test('generateSalt menghasilkan salt yang acak dan berbeda tiap pemanggilan', () {
      final service = JurnalPinService();
      final salt1 = service.generateSalt();
      final salt2 = service.generateSalt();

      expect(salt1, isNotEmpty);
      expect(salt2, isNotEmpty);
      expect(salt1, isNot(equals(salt2)));
    });

    test('hashPin deterministik dengan PIN & salt yang sama, berbeda untuk PIN/salt berbeda', () {
      final service = JurnalPinService();
      final salt = service.generateSalt();

      final hash1 = service.hashPin('123456', salt);
      final hash2 = service.hashPin('123456', salt);
      expect(hash1, equals(hash2));

      final hashDifferentPin = service.hashPin('654321', salt);
      expect(hashDifferentPin, isNot(equals(hash1)));

      final salt2 = service.generateSalt();
      final hashDifferentSalt = service.hashPin('123456', salt2);
      expect(hashDifferentSalt, isNot(equals(hash1)));
    });
  });
}
