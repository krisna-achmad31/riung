import 'dart:math' as math;
import 'dart:ui';

import 'minigame_config.dart';

enum BlockBreakerStatus { playing, won, lost }

/// Satu balok "vonis". [labelIndex] memilih teks vonis (lihat
/// `MinigameStrings.verdictLabels`).
class BreakerBlock {
  BreakerBlock({required this.rect, required this.labelIndex});

  final Rect rect;
  final int labelIndex;
  bool alive = true;
}

/// Mesin fisika mini-game pecahkan balok (murni Dart, tanpa Flutter widget —
/// bisa dites). Dunia berukuran tetap [width] × [height]; layar
/// menskalakannya ke ukuran sebenarnya.
///
/// Susunan: balok "vonis" mengelilingi bos di tengah. Balok pecah = HP bos
/// turun; bola yang mengenai tubuh bos langsung juga melukainya. HP 0 =
/// [BlockBreakerStatus.won]; waktu habis atau nyawa habis =
/// [BlockBreakerStatus.lost].
class BlockBreakerEngine {
  /// [height] = tinggi dunia (unit); layar menyesuaikannya dengan tinggi
  /// yang tersedia supaya arena mengisi layar (dibatasi [minHeight]..[maxHeight]).
  /// [startSpeedBonus] menaikkan kecepatan awal bola (dipakai untuk menala
  /// level kesulitan bos Si Waswas — lihat `WaswasBossType.speedBonus`).
  /// 0 = perilaku lama, tidak berubah untuk saboteur lain.
  BlockBreakerEngine({double height = defaultHeight, this.startSpeedBonus = 0}) : height = height.clamp(minHeight, maxHeight) {
    _buildBlocks();
    _resetBall();
  }

  final double startSpeedBonus;

  static const double width = 320;
  static const double defaultHeight = 480;
  static const double minHeight = 420;
  static const double maxHeight = 640;
  final double height;

  static const int cols = 7;
  static const int rows = 6;
  static const double _margin = 12;
  static const double _gap = 4;
  static const double _top = 18;
  static const double blockHeight = 20;
  static const double ballRadius = 6;

  static const double paddleWidth = 76;
  static const double paddleHeight = 12;
  double get paddleY => height - 34;

  /// Bos menempati kolom 2..4, baris 2..4 (di tengah blok-blok).
  static const int _bossColStart = 2;
  static const int _bossColEnd = 4;
  static const int _bossRowStart = 2;
  static const int _bossRowEnd = 4;

  static double get blockWidth => (width - 2 * _margin - (cols - 1) * _gap) / cols;

  final List<BreakerBlock> blocks = [];
  late final Rect bossRect;

  double paddleX = width / 2; // titik tengah papan
  late Offset ball;
  Offset velocity = Offset.zero;
  bool launched = false;

  int lives = MinigameConfig.lives;
  double bossHp = 100;
  int blocksBroken = 0;
  int bodyHits = 0;
  double timeLeft = MinigameConfig.sessionSeconds.toDouble();
  BlockBreakerStatus status = BlockBreakerStatus.playing;

  /// Bertambah tiap balok pecah; [lastBrokenLabel] = indeks vonis terakhir.
  int brokenSeq = 0;
  int lastBrokenLabel = 0;

  /// Detik sisa efek kilat tubuh bos (untuk animasi).
  double bossFlash = 0;
  double _bossCooldown = 0;

  int get score => blocksBroken * MinigameConfig.pointsPerBlock + bodyHits * MinigameConfig.pointsPerBodyHit;
  int get aliveBlocks => blocks.where((b) => b.alive).length;
  double get speed => math.min(MinigameConfig.ballSpeedMax, MinigameConfig.ballSpeedStart + startSpeedBonus + blocksBroken * MinigameConfig.ballSpeedPerBlock);

  void _buildBlocks() {
    final w = blockWidth;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final inBoss = c >= _bossColStart && c <= _bossColEnd && r >= _bossRowStart && r <= _bossRowEnd;
        if (inBoss) continue;
        // Baris paling bawah di bawah bos memang tetap ada supaya bos
        // "tertutup" dan harus digali dulu.
        blocks.add(BreakerBlock(
          rect: Rect.fromLTWH(_margin + c * (w + _gap), _top + r * (blockHeight + _gap), w, blockHeight),
          labelIndex: r * cols + c,
        ));
      }
    }
    final left = _margin + _bossColStart * (w + _gap);
    final right = _margin + (_bossColEnd + 1) * (w + _gap) - _gap;
    final top = _top + _bossRowStart * (blockHeight + _gap);
    final bottom = _top + (_bossRowEnd + 1) * (blockHeight + _gap) - _gap;
    bossRect = Rect.fromLTRB(left, top, right, bottom);
  }

  void _resetBall() {
    launched = false;
    velocity = Offset.zero;
    ball = Offset(paddleX, paddleY - ballRadius - 1);
  }

  /// Geser papan ke [x] (koordinat dunia); bola yang belum diluncurkan ikut.
  void movePaddle(double x) {
    paddleX = x.clamp(paddleWidth / 2, width - paddleWidth / 2);
    if (!launched) ball = Offset(paddleX, paddleY - ballRadius - 1);
  }

  void launch() {
    if (launched || status != BlockBreakerStatus.playing) return;
    launched = true;
    // Sedikit miring supaya tidak lurus vertikal terus.
    final angle = -math.pi / 2 + 0.35 * (paddleX < width / 2 ? 1 : -1);
    velocity = Offset(math.cos(angle), math.sin(angle)) * speed;
  }

  /// Majukan simulasi [dt] detik.
  void step(double dt) {
    if (status != BlockBreakerStatus.playing) return;
    dt = math.min(dt, 1 / 20);
    timeLeft -= dt;
    if (bossFlash > 0) bossFlash = math.max(0, bossFlash - dt);
    if (_bossCooldown > 0) _bossCooldown -= dt;
    if (timeLeft <= 0) {
      timeLeft = 0;
      status = BlockBreakerStatus.lost;
      return;
    }
    if (!launched) return;

    // Substep supaya bola cepat tidak menembus balok.
    final distance = velocity.distance * dt;
    final steps = math.max(1, (distance / 3).ceil());
    final sub = dt / steps;
    for (var i = 0; i < steps; i++) {
      ball += velocity * sub;
      _collideWalls();
      _collidePaddle();
      _collideBlocks();
      _collideBoss();
      if (status != BlockBreakerStatus.playing) return;
      if (ball.dy - ballRadius > height) {
        _loseLife();
        return;
      }
    }
  }

  void _collideWalls() {
    if (ball.dx - ballRadius < 0) {
      ball = Offset(ballRadius, ball.dy);
      velocity = Offset(velocity.dx.abs(), velocity.dy);
    } else if (ball.dx + ballRadius > width) {
      ball = Offset(width - ballRadius, ball.dy);
      velocity = Offset(-velocity.dx.abs(), velocity.dy);
    }
    if (ball.dy - ballRadius < 0) {
      ball = Offset(ball.dx, ballRadius);
      velocity = Offset(velocity.dx, velocity.dy.abs());
    }
  }

  void _collidePaddle() {
    if (velocity.dy <= 0) return;
    final top = paddleY;
    if (ball.dy + ballRadius < top || ball.dy - ballRadius > top + paddleHeight) return;
    if (ball.dx < paddleX - paddleWidth / 2 - ballRadius || ball.dx > paddleX + paddleWidth / 2 + ballRadius) return;
    final offset = ((ball.dx - paddleX) / (paddleWidth / 2)).clamp(-1.0, 1.0);
    final angle = -math.pi / 2 + offset * 1.0; // maks ±~57°
    velocity = Offset(math.cos(angle), math.sin(angle)) * speed;
    ball = Offset(ball.dx, top - ballRadius - 0.5);
  }

  void _collideBlocks() {
    for (final block in blocks) {
      if (!block.alive) continue;
      final normal = _hit(block.rect);
      if (normal == null) continue;
      block.alive = false;
      blocksBroken++;
      brokenSeq++;
      lastBrokenLabel = block.labelIndex;
      bossHp = math.max(0, bossHp - MinigameConfig.hpPerBlockPercent);
      _reflect(normal);
      _checkWin();
      return; // satu balok per substep
    }
  }

  void _collideBoss() {
    final normal = _hit(bossRect);
    if (normal == null) return;
    _reflect(normal);
    if (_bossCooldown <= 0) {
      _bossCooldown = 0.35;
      bossFlash = 0.25;
      bodyHits++;
      bossHp = math.max(0, bossHp - MinigameConfig.hpPerBodyHitPercent);
      _checkWin();
    }
  }

  void _checkWin() {
    if (bossHp <= 0) status = BlockBreakerStatus.won;
  }

  void _loseLife() {
    lives--;
    if (lives <= 0) {
      status = BlockBreakerStatus.lost;
      return;
    }
    _resetBall();
  }

  /// Normal tabrakan bola–[r] (menuju bola), atau null kalau tidak bertabrakan.
  /// Disederhanakan ke sumbu (kiri/kanan/atas/bawah) supaya pantulannya terasa
  /// seperti Arkanoid klasik.
  Offset? _hit(Rect r) {
    final cx = ball.dx.clamp(r.left, r.right);
    final cy = ball.dy.clamp(r.top, r.bottom);
    final dx = ball.dx - cx;
    final dy = ball.dy - cy;
    if (dx * dx + dy * dy > ballRadius * ballRadius) return null;
    if (dx == 0 && dy == 0) {
      // Pusat bola di dalam persegi: dorong keluar lewat sisi terdekat.
      final l = ball.dx - r.left, rt = r.right - ball.dx, t = ball.dy - r.top, b = r.bottom - ball.dy;
      final m = math.min(math.min(l, rt), math.min(t, b));
      if (m == l) return const Offset(-1, 0);
      if (m == rt) return const Offset(1, 0);
      if (m == t) return const Offset(0, -1);
      return const Offset(0, 1);
    }
    return dx.abs() > dy.abs() ? Offset(dx.sign, 0) : Offset(0, dy.sign);
  }

  void _reflect(Offset normal) {
    final dot = velocity.dx * normal.dx + velocity.dy * normal.dy;
    if (dot < 0) {
      velocity = Offset(velocity.dx - 2 * dot * normal.dx, velocity.dy - 2 * dot * normal.dy);
    }
    // Skala ulang ke kecepatan sekarang (naik pelan tiap balok pecah).
    velocity = velocity / velocity.distance * speed;
    // Keluarkan bola dari rintangan.
    ball += normal * 1.5;
  }
}
