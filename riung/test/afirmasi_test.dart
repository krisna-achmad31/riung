import 'package:flutter_test/flutter_test.dart';

import 'package:riung/core/models/affirmation.dart';
import 'package:riung/features/afirmasi/logic/affirmation_deck.dart';

void main() {
  group('Affirmation Model', () {
    test('fromMap dan toMap bolak-balik dengan benar', () {
      final a = const Affirmation(
        id: 'aff_1',
        teks: 'Aku cukup apa adanya',
        targetSaboteur: 'hakim',
        isCustom: false,
      );

      final map = a.toMap();
      expect(map[Affirmation.fId], 'aff_1');
      expect(map[Affirmation.fTeks], 'Aku cukup apa adanya');
      expect(map[Affirmation.fTargetSaboteur], 'hakim');
      expect(map[Affirmation.fIsCustom], isFalse);

      final restored = Affirmation.fromMap(map);
      expect(restored.id, a.id);
      expect(restored.teks, a.teks);
      expect(restored.targetSaboteur, a.targetSaboteur);
      expect(restored.isCustom, a.isCustom);
    });

    test('targetSaboteur kosong dipetakan ke null', () {
      final a = Affirmation.fromMap({
        Affirmation.fId: 'aff_custom_1',
        Affirmation.fTeks: 'Tarik napas dan rileks',
        Affirmation.fTargetSaboteur: '',
        Affirmation.fIsCustom: true,
      });

      expect(a.targetSaboteur, isNull);
      expect(a.isCustom, isTrue);
    });
  });

  group('buildAffirmationDecks', () {
    test('Mengelompokkan kartu seeded berdasarkan monster target', () {
      final seeded = [
        const Affirmation(id: 's1', teks: 'Teks 1', targetSaboteur: 'waswas'),
        const Affirmation(id: 's2', teks: 'Teks 2', targetSaboteur: 'waswas'),
        const Affirmation(id: 's3', teks: 'Teks 3', targetSaboteur: 'hakim'),
      ];

      final decks = buildAffirmationDecks(seeded: seeded, custom: []);
      expect(decks.length, 2);

      final waswasDeck = decks.firstWhere((d) => d.monsterId == 'waswas');
      expect(waswasDeck.id, 'deck_waswas');
      expect(waswasDeck.cards.length, 2);

      final hakimDeck = decks.firstWhere((d) => d.monsterId == 'hakim');
      expect(hakimDeck.id, 'deck_hakim');
      expect(hakimDeck.cards.length, 1);
    });

    test('Kartu custom muncul di deck_custom dan ikut ke deck monster jika ditag', () {
      final seeded = [
        const Affirmation(id: 's1', teks: 'Teks 1', targetSaboteur: 'waswas'),
      ];
      final custom = [
        const Affirmation(id: 'c1', teks: 'Custom 1', targetSaboteur: 'waswas', isCustom: true),
        const Affirmation(id: 'c2', teks: 'Custom Bebas', targetSaboteur: null, isCustom: true),
      ];

      final decks = buildAffirmationDecks(seeded: seeded, custom: custom);
      // Ada deck_waswas dan deck_custom
      expect(decks.any((d) => d.id == 'deck_waswas'), isTrue);
      expect(decks.any((d) => d.id == 'deck_custom'), isTrue);

      final waswasDeck = decks.firstWhere((d) => d.monsterId == 'waswas');
      expect(waswasDeck.cards.length, 2); // s1 + c1

      final customDeck = decks.firstWhere((d) => d.id == 'deck_custom');
      expect(customDeck.monsterId, isNull);
      expect(customDeck.cards.length, 2); // c1 + c2
    });

    test('Tanpa kartu custom tidak membuat deck_custom', () {
      final seeded = [
        const Affirmation(id: 's1', teks: 'Teks 1', targetSaboteur: 'kabut'),
      ];
      final decks = buildAffirmationDecks(seeded: seeded, custom: []);
      expect(decks.length, 1);
      expect(decks.any((d) => d.id == 'deck_custom'), isFalse);
    });
  });
}
