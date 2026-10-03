import 'dart:math' as math;

import 'minigame_config.dart';
import 'waswas_reaction_config.dart';

enum WaswasReactionStatus { playing, won, lost }

/// Satu gelembung "pikiran terburuk" yang naik dari bawah layar.
class WorryBubble {
  WorryBubble({required this.x, required this.y, required this.labelIndex});

  double x;
  double y;
  final int labelIndex;
  bool alive = true;
}

/// Mesin mini-game "Lepaskan Pikiran" (murni Dart, tanpa Flutter — bisa
/// dites): gelembung pikiran cemas naik dari bawah, disentuh sebelum
/// menyentuh garis atas untuk "dilepaskan". Berbeda dari
/// [BlockBreakerEngine] (menghancurkan), di sini goalnya bertahan tanpa
/// kewalahan — cocok dengan inti Si Waswas: membayangkan skenario
/// terburuk yang belum tentu terjadi.
///
/// Menang = bertahan sampai waktu habis dengan nyawa tersisa. Kalah =
/// nyawa habis (tiga gelembung lolos ke atas tak tersentuh).
class WaswasReactionEngine {
  /// [intensity] 0..1 — 0 = Si Waswas paling jinak (paling mudah), 1 =
  /// paling liar (paling sulit). Hitung dari `100 - MonsterProgress.progress`.
  WaswasReactionEngine({double intensity = 0.5, math.Random? random})
      : intensity = intensity.clamp(0, 1),
        _random = random ?? math.Random() {
    _scheduleNextSpawn();
  }

  static const double width = 320;
  static const double height = 480;
  static const double topLine = 60;

  final double intensity;
  final math.Random _random;

  final List<WorryBubble> bubbles = [];
  WaswasReactionStatus status = WaswasReactionStatus.playing;

  int lives = MinigameConfig.lives;
  int hits = 0;
  int score = 0;
  double timeLeft = MinigameConfig.sessionSeconds.toDouble();

  double _spawnCountdown = 0;

  double get spawnInterval => _lerp(WaswasReactionConfig.spawnIntervalEasy, WaswasReactionConfig.spawnIntervalHard, intensity);
  double get riseSpeed => _lerp(WaswasReactionConfig.riseSpeedEasy, WaswasReactionConfig.riseSpeedHard, intensity);

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _scheduleNextSpawn() => _spawnCountdown = spawnInterval;

  void _spawn() {
    final x = bubbleMargin + _random.nextDouble() * (width - 2 * bubbleMargin);
    bubbles.add(WorryBubble(x: x, y: height, labelIndex: _random.nextInt(worryLabelCount)));
  }

  static const double bubbleMargin = WaswasReactionConfig.bubbleRadius + 8;
  static const int worryLabelCount = 6;

  /// Sentuh titik ([x],[y]) — melepaskan gelembung terdekat dalam radius,
  /// kalau ada. Mengembalikan true kalau kena.
  bool tap(double x, double y) {
    WorryBubble? nearest;
    double nearestDist = double.infinity;
    for (final b in bubbles) {
      if (!b.alive) continue;
      final d = math.sqrt(math.pow(b.x - x, 2) + math.pow(b.y - y, 2));
      if (d <= WaswasReactionConfig.bubbleRadius && d < nearestDist) {
        nearest = b;
        nearestDist = d;
      }
    }
    if (nearest == null) return false;
    nearest.alive = false;
    bubbles.remove(nearest);
    hits++;
    score += WaswasReactionConfig.pointsPerPop;
    return true;
  }

  void step(double dt) {
    if (status != WaswasReactionStatus.playing) return;

    timeLeft -= dt;
    if (timeLeft <= 0) {
      timeLeft = 0;
      status = lives > 0 ? WaswasReactionStatus.won : WaswasReactionStatus.lost;
    }

    _spawnCountdown -= dt;
    if (_spawnCountdown <= 0) {
      _spawn();
      _scheduleNextSpawn();
    }

    for (final b in bubbles) {
      if (!b.alive) continue;
      b.y -= riseSpeed * dt;
      if (b.y <= topLine) {
        b.alive = false;
        lives--;
        if (lives <= 0) {
          status = WaswasReactionStatus.lost;
        }
      }
    }
    bubbles.removeWhere((b) => !b.alive);
  }
}
