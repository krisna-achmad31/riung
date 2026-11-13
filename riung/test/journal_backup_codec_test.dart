import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/models/journal_entry.dart';
import 'package:riung/core/services/journal_backup_codec.dart';

void main() {
  const password = 'a separate backup passphrase';
  final entry = JournalEntry(
    entryId: 'existing-entry',
    promptId: 'free',
    mood: 'okay',
    text: 'Isi pribadi 🌙',
    tags: ['tidur'],
    createdAt: DateTime.parse('2026-11-11T20:00:00.000'),
  );
  late Uint8List backup;

  setUpAll(() async {
    backup = await JournalBackupCodec.encode([entry], password);
  });

  test(
    'portable backup preserves IDs and content with randomized encryption',
    () async {
      expect(latin1.decode(backup), isNot(contains('existing-entry')));
      expect(latin1.decode(backup), isNot(contains('Isi pribadi')));
      final restored = (await JournalBackupCodec.decode(
        backup,
        password,
      )).single;
      expect(restored.entryId, entry.entryId);
      expect(restored.toMap(), entry.toMap());
      final second = await JournalBackupCodec.encode([entry], password);
      expect(second, isNot(orderedEquals(backup)));
    },
  );

  test('wrong password and changed ciphertext fail authentication', () async {
    await expectLater(
      JournalBackupCodec.decode(backup, 'a different passphrase'),
      throwsA(anything),
    );
    final corrupted = Uint8List.fromList(backup);
    corrupted[corrupted.length - 1] ^= 1;
    await expectLater(
      JournalBackupCodec.decode(corrupted, password),
      throwsA(anything),
    );
  });
}
