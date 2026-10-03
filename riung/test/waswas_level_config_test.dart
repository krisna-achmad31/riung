import 'package:flutter_test/flutter_test.dart';
import 'package:riung/features/minigame/logic/block_breaker_engine.dart';
import 'package:riung/features/monster/logic/waswas_level_config.dart';

void main() {
  group('waswasLevelForProgress', () {
    test('progres 0-19% adalah level 1, bos Block Breaker gampang', () {
      final level = waswasLevelForProgress(0);
      expect(level.level, 1);
      expect(level.boss, WaswasBossType.blockBreakerEasy);
      final level2 = waswasLevelForProgress(19);
      expect(level2.level, 1);
    });

    test('progres naik → level naik, sampai level 5 memakai bos reaction', () {
      expect(waswasLevelForProgress(20).level, 2);
      expect(waswasLevelForProgress(40).level, 3);
      expect(waswasLevelForProgress(60).level, 4);
      expect(waswasLevelForProgress(80).level, 5);
      expect(waswasLevelForProgress(100).level, 5);
      expect(waswasLevelForProgress(80).boss, WaswasBossType.reaction);
      expect(waswasLevelForProgress(99).boss, WaswasBossType.reaction);
    });

    test('bos Block Breaker makin susah di level lebih tinggi (speedBonus naik)', () {
      final l1 = waswasLevelForProgress(0).boss.speedBonus;
      final l3 = waswasLevelForProgress(40).boss.speedBonus;
      final l4 = waswasLevelForProgress(60).boss.speedBonus;
      expect(l3, greaterThan(l1));
      expect(l4, greaterThan(l3));
    });

    test('tiap level punya persis 2 step latihan', () {
      for (final level in waswasLevels) {
        expect(level.steps.length, 2, reason: 'level ${level.level} harus 2 step');
      }
    });
  });

  group('BlockBreakerEngine startSpeedBonus', () {
    test('default 0 tidak mengubah kecepatan awal', () {
      final engine = BlockBreakerEngine();
      expect(engine.speed, 230);
    });

    test('startSpeedBonus menaikkan kecepatan awal', () {
      final engine = BlockBreakerEngine(startSpeedBonus: 60);
      expect(engine.speed, 290);
    });
  });
}
