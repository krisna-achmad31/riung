import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/models/monster_anchor.dart';
import 'package:riung/core/services/monster_anchor_registry.dart';
import 'package:riung/core/widgets/riung_monster.dart';

/// Setiap cabang render [RiungMonster] (CLAUDE.md aturan #7): bossScale,
/// slot `none` (overlay kanvas penuh), `anchorsLiar`, rotasi Si Mengelak,
/// zIndex, dan id tak dikenal / art hilang tidak boleh crash.
void main() {
  late MonsterAnchorData data;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    data = await MonsterAnchorRegistry.instance.load();
  });

  Future<void> pump(WidgetTester tester, Widget monster) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: monster))),
      );

  String assetOf(Image image) {
    var provider = image.image;
    if (provider is ResizeImage) provider = provider.imageProvider;
    return (provider as AssetImage).assetName;
  }

  List<String> assetsIn(WidgetTester tester) =>
      tester.widgetList<Image>(find.byType(Image)).map(assetOf).toList();

  testWidgets('Si Hakim dirender bossScale× lebih lebar, bisa dimatikan', (tester) async {
    await pump(tester, const RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 100));
    final boss = tester.getSize(find.byType(RiungMonster));
    expect(boss.width, closeTo(100 * data.monsters['hakim']!.bossScale, 0.01));

    await pump(tester, const RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 100, applyBossScale: false));
    expect(tester.getSize(find.byType(RiungMonster)).width, closeTo(100, 0.01));
  });

  testWidgets('slot none (bingkai_emas) = overlay kanvas penuh per wujud', (tester) async {
    for (final state in MonsterVisualState.values) {
      await pump(tester, RiungMonster(monsterId: 'cermin', state: state, size: 120, cosmetics: const ['bingkai_emas']));
      final cosmetic = data.cosmetics['bingkai_emas']!;
      final file = data.assetPath(cosmetic.fileFor(jinak: state == MonsterVisualState.jinak));
      expect(assetsIn(tester), contains(file));
      // Overlay mengisi kanvas penuh, bukan Positioned ber-anchor.
      final overlay = find.byWidgetPredicate((w) => w is Image && assetOf(w) == file);
      expect(tester.getSize(overlay), tester.getSize(find.byType(RiungMonster)));
    }
  });

  testWidgets('wujud liar memakai anchorsLiar, bukan anchors jinak', (tester) async {
    final m = data.monsters['waswas']!;
    final topi = data.cosmetics['topi_rajut']!;
    final topiFile = data.assetPath(topi.fileFor(jinak: true));
    for (final state in MonsterVisualState.values) {
      final jinak = state == MonsterVisualState.jinak;
      await pump(tester, RiungMonster(monsterId: 'waswas', state: state, size: 200, cosmetics: const ['topi_rajut']));
      final positioned = tester.widget<Positioned>(find.ancestor(
        of: find.byWidgetPredicate((w) => w is Image && assetOf(w) == topiFile),
        matching: find.byType(Positioned),
      ).first);
      final anchor = m.anchorFor('head', jinak: jinak)!;
      final canvas = tester.getSize(find.byType(RiungMonster));
      final w = canvas.width * topi.width * anchor.scale;
      final h = w / topi.aspect;
      expect(positioned.left, closeTo(anchor.x * canvas.width - topi.pivotX * w, 0.01), reason: state.name);
      expect(positioned.top, closeTo(anchor.y * canvas.height - topi.pivotY * h, 0.01), reason: state.name);
    }
  });

  testWidgets('rotasi anchor Si Mengelak diterapkan di sekitar pivot', (tester) async {
    final anchor = data.monsters['mengelak']!.anchorFor('head', jinak: true)!;
    expect(anchor.rotationDeg, isNot(0));
    await pump(tester, const RiungMonster(monsterId: 'mengelak', state: MonsterVisualState.jinak, size: 200, cosmetics: ['topi_rajut']));
    final rotate = tester.widget<Transform>(find.descendant(of: find.byType(RiungMonster), matching: find.byType(Transform)).first);
    final expected = Matrix4.rotationZ(anchor.rotationDeg * math.pi / 180);
    for (var i = 0; i < 16; i++) {
      expect(rotate.transform.storage[i], closeTo(expected.storage[i], 1e-6));
    }
  });

  testWidgets('zIndex 0 di bawah badan, zIndex 2 di atas', (tester) async {
    await pump(tester, const RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 200, cosmetics: ['bantal_mini', 'topi_rajut']));
    final assets = assetsIn(tester);
    final body = data.assetPath(data.monsters['kabut']!.fileFor(jinak: true));
    expect(assets.indexOf(data.assetPath('bantal_mini.webp')), lessThan(assets.indexOf(body)));
    expect(assets.indexOf(data.assetPath('topi_rajut.webp')), greaterThan(assets.indexOf(body)));
  });

  testWidgets('semua monster × wujud × kosmetik dirender tanpa exception', (tester) async {
    for (final id in data.monsters.keys) {
      for (final state in MonsterVisualState.values) {
        final cosmetics = data.cosmetics.keys.where((c) => c != 'bingkai_emas' || id == 'cermin').toList();
        await pump(tester, RiungMonster(monsterId: id, state: state, size: 160, cosmetics: cosmetics));
        expect(tester.takeException(), isNull, reason: '$id ${state.name}');
      }
    }
  });
}
