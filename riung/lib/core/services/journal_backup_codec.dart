import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

import '../models/journal_entry.dart';

/// Format v1: magic, salt (16 bytes), nonce (12 bytes), AES-256-GCM payload.
/// The device key and journal PIN never leave secure storage.
abstract final class JournalBackupCodec {
  static const _magic = 'RIUNG-JOURNAL-1\n';
  static const maxBytes = 20 * 1024 * 1024;

  static Future<Uint8List> encode(
    List<JournalEntry> entries,
    String password,
  ) => compute(_encode, (entries, password));

  static Future<List<JournalEntry>> decode(Uint8List bytes, String password) =>
      compute(_decode, (bytes, password));

  static Uint8List _encode((List<JournalEntry>, String) input) {
    final payload = utf8.encode(
      jsonEncode([
        for (final entry in input.$1) {'id': entry.entryId, ...entry.toMap()},
      ]),
    );
    if (payload.length + _magic.length + 44 > maxBytes) {
      throw const FormatException('Backup too large');
    }
    final salt = enc.IV.fromSecureRandom(16).bytes;
    final nonce = enc.IV.fromSecureRandom(12).bytes;
    final cipher = _cipher(true, input.$2, salt, nonce);
    return Uint8List.fromList([
      ...ascii.encode(_magic),
      ...salt,
      ...nonce,
      ...cipher.process(payload),
    ]);
  }

  static List<JournalEntry> _decode((Uint8List, String) input) {
    final (bytes, password) = input;
    final start = _magic.length;
    if (bytes.length < start + 44 ||
        bytes.length > maxBytes ||
        !listEquals(bytes.sublist(0, start), ascii.encode(_magic))) {
      throw const FormatException('Invalid journal backup');
    }
    final salt = Uint8List.sublistView(bytes, start, start + 16);
    final nonce = Uint8List.sublistView(bytes, start + 16, start + 28);
    final cipher = _cipher(false, password, salt, nonce);
    final plaintext = cipher.process(Uint8List.sublistView(bytes, start + 28));
    final rows = jsonDecode(utf8.decode(plaintext)) as List<dynamic>;
    return [for (final raw in rows) _entry(raw as Map<String, dynamic>)];
  }

  static JournalEntry _entry(Map<String, dynamic> row) {
    final id = row['id'] as String;
    if (id.isEmpty) throw const FormatException('Missing journal entry ID');
    return JournalEntry(
      entryId: id,
      promptId: row[JournalEntry.fPromptId] as String,
      mood: row[JournalEntry.fMood] as String,
      text: row[JournalEntry.fText] as String,
      tags: (row[JournalEntry.fTags] as List<dynamic>).cast<String>().toList(),
      createdAt: DateTime.parse(row[JournalEntry.fCreatedAt] as String),
    );
  }

  static GCMBlockCipher _cipher(
    bool encrypt,
    String password,
    Uint8List salt,
    Uint8List nonce,
  ) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 600000, 32));
    final key = derivator.process(utf8.encode(password));
    return GCMBlockCipher(AESEngine())..init(
      encrypt,
      AEADParameters(KeyParameter(key), 128, nonce, ascii.encode(_magic)),
    );
  }
}
