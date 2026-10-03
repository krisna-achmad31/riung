import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:riung/features/minigame/logic/minigame_config.dart';
import 'package:riung/features/minigame/logic/waswas_reaction_config.dart';
import 'package:riung/features/minigame/logic/waswas_reaction_engine.dart';

/// Mesin "Lepaskan Pikiran" (Si Waswas): beda dari Block Breaker — goalnya
/// bertahan, bukan menghancurkan; kesulitan naik saat monster masih liar,
/// bukan dari pembelian (CLAUDE.md aturan #4).
void main() {
  test('sesi kosong (tanpa gelembung disentuh) berakhir menang kalau waktu habis dengan nyawa tersisa', () {
    final e = WaswasReactionEngine(intensity: 0, random: Random(1));
    // Waktu habis tanpa gelembung sempat lolos ke atas (spawn di dasar,
    // rise lambat, dt kecil sekali langkah tak sampai naik jauh).
    e.step(MinigameConfig.sessionSeconds.toDouble());
    expect(e.timeLeft, 0);
    expect(e.status, isNot(WaswasReactionStatus.playing));
  });

  test('gelembung naik dari bawah dan lenyap begitu melewati garis atas, mengurangi nyawa', () {
    final e = WaswasReactionEngine(intensity: 1, random: Random(2));
    final startLives = e.lives;
    // Majukan waktu sedikit demi sedikit sampai satu gelembung sempat spawn & naik habis.
    for (var i = 0; i < 2000 && e.status == WaswasReactionStatus.playing; i++) {
      e.step(0.05);
      if (e.lives < startLives) break;
    }
    expect(e.lives, lessThan(startLives));
  });

  test('nyawa habis → kalah, walau waktu belum habis', () {
    final e = WaswasReactionEngine(intensity: 1, random: Random(3));
    for (var i = 0; i < 20000 && e.status == WaswasReactionStatus.playing; i++) {
      e.step(0.05);
    }
    expect(e.status, WaswasReactionStatus.lost);
    expect(e.lives, 0);
    expect(e.timeLeft, greaterThan(0));
  });

  test('menyentuh gelembung tepat pada posisinya melepaskannya dan menambah skor', () {
    final e = WaswasReactionEngine(intensity: 0, random: Random(4));
    e.step(0.01); // biarkan spawn pertama muncul jika countdown sudah lewat kecil
    // Spawn manual dipastikan lewat step sampai ada 1 gelembung.
    for (var i = 0; i < 500 && e.bubbles.isEmpty; i++) {
      e.step(0.05);
    }
    expect(e.bubbles, isNotEmpty);
    final b = e.bubbles.first;
    final popped = e.tap(b.x, b.y);
    expect(popped, isTrue);
    expect(e.hits, 1);
    expect(e.score, WaswasReactionConfig.pointsPerPop);
    expect(e.bubbles.any((x) => identical(x, b)), isFalse);
  });

  test('menyentuh area kosong tidak melakukan apa-apa', () {
    final e = WaswasReactionEngine(intensity: 0, random: Random(5));
    final popped = e.tap(-999, -999);
    expect(popped, isFalse);
    expect(e.hits, 0);
    expect(e.score, 0);
  });

  test('intensitas 1 (paling liar) memunculkan & menaikkan gelembung lebih cepat daripada intensitas 0', () {
    final easy = WaswasReactionEngine(intensity: 0);
    final hard = WaswasReactionEngine(intensity: 1);
    expect(hard.spawnInterval, lessThan(easy.spawnInterval));
    expect(hard.riseSpeed, greaterThan(easy.riseSpeed));
  });

  test('intensitas selalu dijepit ke rentang 0..1', () {
    expect(WaswasReactionEngine(intensity: -5).intensity, 0);
    expect(WaswasReactionEngine(intensity: 5).intensity, 1);
  });

  test('setelah kalah atau menang, step lanjutan tidak mengubah apa pun lagi', () {
    final e = WaswasReactionEngine(intensity: 1, random: Random(6));
    for (var i = 0; i < 20000 && e.status == WaswasReactionStatus.playing; i++) {
      e.step(0.05);
    }
    expect(e.status, isNot(WaswasReactionStatus.playing));
    final scoreBefore = e.score;
    final livesBefore = e.lives;
    e.step(1);
    expect(e.score, scoreBefore);
    expect(e.lives, livesBefore);
  });
}
