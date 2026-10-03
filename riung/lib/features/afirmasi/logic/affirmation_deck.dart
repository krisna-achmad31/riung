import '../../../core/models/affirmation.dart';

/// Kumpulan kartu afirmasi per target monster (atau buatan sendiri).
/// Dibangun dinamis dari [ContentRepository.getAffirmations] + afirmasi
/// buatan pengguna — bukan daftar statis seperti di
/// `design/Afirmasi.dc.html` (yang mengasumsikan konten jauh lebih banyak
/// per deck daripada yang tersedia di `dummy-data-seed.json`).
class AffirmationDeck {
  const AffirmationDeck({required this.id, required this.monsterId, required this.cards});

  /// `monsterId` null = deck "Buatanku sendiri". Judul deck TIDAK disimpan
  /// di sini — dihitung di UI dari bahasa aktif.
  final String id;
  final String? monsterId;
  final List<Affirmation> cards;
}

List<AffirmationDeck> buildAffirmationDecks({
  required List<Affirmation> seeded,
  required List<Affirmation> custom,
}) {
  // Custom yang ditag ke monster tertentu ikut gabung ke deck monster itu
  // (bareng seeded) SEKALIGUS tetap muncul di 'deck_custom' di bawah —
  // sengaja tampil di 2 deck, bukan duplikat data.
  final bySaboteur = <String, List<Affirmation>>{};
  for (final affirmation in [...seeded, ...custom]) {
    final key = affirmation.targetSaboteur;
    if (key == null) continue;
    bySaboteur.putIfAbsent(key, () => []).add(affirmation);
  }

  final decks = <AffirmationDeck>[
    for (final entry in bySaboteur.entries)
      AffirmationDeck(
        id: 'deck_${entry.key}',
        monsterId: entry.key,
        cards: entry.value,
      ),
  ];

  if (custom.isNotEmpty) {
    decks.add(AffirmationDeck(id: 'deck_custom', monsterId: null, cards: custom));
  }

  return decks;
}
