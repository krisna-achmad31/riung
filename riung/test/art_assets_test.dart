import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/models/monster_anchor.dart';
import 'package:riung/features/kepribadian/logic/character_accessory.dart';
import 'package:riung/features/kepribadian/logic/character_art.dart';
import 'package:riung/features/kepribadian/logic/character_spec.dart';

/// Art 3D: setiap file yang dirujuk anchors.json & CharacterArt harus ada,
/// dan setiap hasil tes harus punya art (CLAUDE.md aturan #7).
void main() {
  final data = MonsterAnchorData.fromMap(
    jsonDecode(File('assets/monsters/anchors.json').readAsStringSync()) as Map<String, dynamic>,
  );

  test('semua art monster & kosmetik di anchors.json ada', () {
    for (final m in data.monsters.values) {
      for (final f in [m.fileJinak, m.fileLiar]) {
        expect(File(data.assetPath(f)).existsSync(), isTrue, reason: f);
      }
      for (final slot in ['head', 'neck', 'base']) {
        expect(m.anchorFor(slot, jinak: true), isNotNull, reason: '${m.id}.$slot jinak');
        expect(m.anchorFor(slot, jinak: false), isNotNull, reason: '${m.id}.$slot liar');
      }
    }
    for (final c in data.cosmetics.values) {
      for (final f in {c.fileFor(jinak: true), c.fileFor(jinak: false)}) {
        expect(File(data.assetPath(f)).existsSync(), isTrue, reason: f);
      }
    }
  });

  test('Si Hakim tetap bos dengan bossScale 1.4 dari JSON', () {
    expect(data.monsters['hakim']!.isBoss, isTrue);
    expect(data.monsters['hakim']!.bossScale, 1.4);
  });

  test('setiap hasil tes punya art 3D yang filenya ada', () {
    const jung = ['INFP', 'INFJ', 'ENFP', 'ENFJ', 'INTP', 'INTJ', 'ENTP', 'ENTJ', 'ISFJ', 'ISTJ', 'ESFJ', 'ESTJ', 'ISFP', 'ISTP', 'ESFP', 'ESTP'];
    final specs = [
      for (final c in jung) CharacterSpec.jung(c),
      for (final k in ['sanguinis', 'koleris', 'melankolis', 'flegmatis']) CharacterSpec.temperament(k),
      for (final k in ['aman', 'cemas', 'menghindar', 'cemas_menghindar']) CharacterSpec.attachment(k),
    ];
    for (final s in specs) {
      final art = CharacterArt.of(s.artKey);
      expect(art, isNotNull, reason: s.artKey);
      expect(File(art!.asset).existsSync(), isTrue, reason: art.asset);
    }
  });

  test('aksesori ber-art 3D punya file', () {
    for (final a in CharacterAccessory.values) {
      final rule = AccessoryArt.of(a);
      if (rule == null) continue;
      expect(File(rule.asset(a)).existsSync(), isTrue, reason: a.name);
    }
  });
}
