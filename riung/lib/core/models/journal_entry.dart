import 'model_utils.dart';

/// Mirror `/users/{uid}/journal/{entryId}` — tersimpan lokal terenkripsi,
/// terkunci PIN (lihat CLAUDE.md aturan #5).
class JournalEntry {
  const JournalEntry({
    required this.entryId,
    required this.promptId,
    required this.mood,
    required this.text,
    required this.tags,
    required this.createdAt,
  });

  factory JournalEntry.fromMap(String entryId, Map<String, dynamic> map) {
    return JournalEntry(
      entryId: entryId,
      promptId: map[fPromptId] as String? ?? '',
      mood: map[fMood] as String? ?? '',
      text: map[fText] as String? ?? '',
      tags: parseStringList(map[fTags]),
      createdAt: parseDate(map[fCreatedAt]) ?? DateTime.now(),
    );
  }

  static const fPromptId = 'promptId';
  static const fMood = 'mood';
  static const fText = 'text';
  static const fTags = 'tags';
  static const fCreatedAt = 'createdAt';

  final String entryId;
  final String promptId;
  final String mood;
  final String text;
  final List<String> tags;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        fPromptId: promptId,
        fMood: mood,
        fText: text,
        fTags: tags,
        fCreatedAt: createdAt.toIso8601String(),
      };

  JournalEntry copyWith({
    String? promptId,
    String? mood,
    String? text,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return JournalEntry(
      entryId: entryId,
      promptId: promptId ?? this.promptId,
      mood: mood ?? this.mood,
      text: text ?? this.text,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
