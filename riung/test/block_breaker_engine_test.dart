
import 'package:flutter_test/flutter_test.dart';

import 'package:riung/features/minigame/logic/block_breaker_engine.dart';
import 'package:riung/features/minigame/logic/minigame_config.dart';

void main() {
  test('bos di tengah dikelilingi balok, tidak ada balok di area bos', () {
    final e = BlockBreakerEngine();
    expect(e.blocks, isNotEmpty);
    for (final b in e.blocks) {
      expect(b.rect.overlaps(e.bossRect), isFalse);
    }
    // Bos kira-kira di tengah horizontal arena.
    expect((e.bossRect.center.dx - BlockBreakerEngine.width / 2).abs(), lessThan(1));
    // Ada balok di kiri, kanan, atas, dan bawah bos.
    expect(e.blocks.any((b) => b.rect.right <= e.bossRect.left), isTrue);
    expect(e.blocks.any((b) => b.rect.left >= e.bossRect.right), isTrue);
    expect(e.blocks.any((b) => b.rect.bottom <= e.bossRect.top), isTrue);
    expect(e.blocks.any((b) => b.rect.top >= e.bossRect.bottom), isTrue);
  });

  test('bola belum jalan sebelum diluncurkan dan ikut papan', () {
    final e = BlockBreakerEngine();
    e.step(0.05);
    expect(e.launched, isFalse);
    e.movePaddle(50);
    expect(e.ball.dx, 50);
    e.movePaddle(-999);
    expect(e.paddleX, BlockBreakerEngine.paddleWidth / 2);
  });

  test('bola memantul dari dinding dan papan, tidak jatuh selama papan mengikuti', () {
    final e = BlockBreakerEngine();
    e.launch();
    for (var i = 0; i < 600; i++) {
      e.movePaddle(e.ball.dx); // papan "sempurna"
      e.step(1 / 60);
      if (e.status != BlockBreakerStatus.playing) break;
    }
    expect(e.lives, MinigameConfig.lives);
    expect(e.ball.dx, inInclusiveRange(0, BlockBreakerEngine.width));
    expect(e.ball.dy, lessThan(e.height));
  });

  test('balok pecah menurunkan HP bos dan menambah poin', () {
    final e = BlockBreakerEngine();
    final target = e.blocks.firstWhere((b) => b.rect.top > e.bossRect.bottom);
    // Tempatkan bola tepat di bawah balok, meluncur ke atas.
    e.launch();
    e.ball = Offset(target.rect.center.dx, target.rect.bottom + 8);
    e.velocity = const Offset(0, -MinigameConfig.ballSpeedStart);
    for (var i = 0; i < 30 && target.alive; i++) {
      e.step(1 / 60);
    }
    expect(target.alive, isFalse);
    expect(e.blocksBroken, 1);
    expect(e.bossHp, 100 - MinigameConfig.hpPerBlockPercent);
    expect(e.score, MinigameConfig.pointsPerBlock);
    expect(e.velocity.dy, greaterThan(0), reason: 'memantul turun setelah kena balok dari bawah');
  });

  test('bola yang mengenai tubuh bos melukainya, dengan jeda antar-hit', () {
    final e = BlockBreakerEngine();
    // Hapus semua balok supaya bola langsung mencapai bos.
    for (final b in e.blocks) {
      b.alive = false;
    }
    e.launch();
    e.ball = Offset(e.bossRect.center.dx, e.bossRect.bottom + 10);
    e.velocity = const Offset(0, -MinigameConfig.ballSpeedStart);
    for (var i = 0; i < 20; i++) {
      e.step(1 / 60);
    }
    expect(e.bodyHits, 1);
    expect(e.bossHp, 100 - MinigameConfig.hpPerBodyHitPercent);
    expect(e.bossFlash, greaterThanOrEqualTo(0));
  });

  test('HP bos 0 sebelum waktu habis = menang', () {
    final e = BlockBreakerEngine();
    e.bossHp = MinigameConfig.hpPerBlockPercent;
    final target = e.blocks.firstWhere((b) => b.rect.top > e.bossRect.bottom);
    e.launch();
    e.ball = Offset(target.rect.center.dx, target.rect.bottom + 8);
    e.velocity = const Offset(0, -MinigameConfig.ballSpeedStart);
    for (var i = 0; i < 30 && e.status == BlockBreakerStatus.playing; i++) {
      e.step(1 / 60);
    }
    expect(e.status, BlockBreakerStatus.won);
  });

  test('bola jatuh mengurangi nyawa dan mereset bola; nyawa habis = kalah', () {
    final e = BlockBreakerEngine();
    for (var life = MinigameConfig.lives; life > 0; life--) {
      e.movePaddle(30);
      e.launch();
      e.ball = Offset(290, e.height - 5); // jauh dari papan
      e.velocity = const Offset(0, 250);
      for (var i = 0; i < 60 && e.launched; i++) {
        e.step(1 / 60);
      }
      if (life > 1) {
        expect(e.lives, life - 1);
        expect(e.launched, isFalse);
        expect(e.status, BlockBreakerStatus.playing);
      }
    }
    expect(e.lives, 0);
    expect(e.status, BlockBreakerStatus.lost);
  });

  test('waktu habis = kalah', () {
    final e = BlockBreakerEngine();
    for (var i = 0; i < 61 * 20 && e.status == BlockBreakerStatus.playing; i++) {
      e.step(1 / 20);
    }
    expect(e.status, BlockBreakerStatus.lost);
    expect(e.timeLeft, 0);
  });

  test('kecepatan bola naik pelan seiring balok pecah tapi dibatasi', () {
    final e = BlockBreakerEngine();
    expect(e.speed, MinigameConfig.ballSpeedStart);
    e.blocksBroken = 1000;
    expect(e.speed, MinigameConfig.ballSpeedMax);
  });
}
