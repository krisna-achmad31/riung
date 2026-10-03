/// Mirror `/content/affirmations/{id}` (bawaan) & entri buatan pengguna
/// tersimpan lokal di `LocalPrefsStore`. `targetSaboteur` kosong berarti
/// afirmasi umum / buatan sendiri tanpa target monster tertentu.
class Affirmation {
  const Affirmation({
    required this.id,
    required this.teks,
    required this.targetSaboteur,
    this.isCustom = false,
  });

  factory Affirmation.fromMap(Map<String, dynamic> map) {
    return Affirmation(
      id: map[fId] as String,
      teks: map[fTeks] as String,
      targetSaboteur: (map[fTargetSaboteur] as String?)?.isEmpty ?? true ? null : map[fTargetSaboteur] as String,
      isCustom: map[fIsCustom] as bool? ?? false,
    );
  }

  static const fId = 'id';
  static const fTeks = 'teks';
  static const fTargetSaboteur = 'target_saboteur';
  static const fIsCustom = 'is_custom';

  final String id;
  final String teks;
  final String? targetSaboteur;
  final bool isCustom;

  Map<String, dynamic> toMap() => {
        fId: id,
        fTeks: teks,
        fTargetSaboteur: targetSaboteur ?? '',
        fIsCustom: isCustom,
      };
}
