import 'package:flutter/material.dart';

import '../../../core/config/audio_assets.dart';
import '../../../core/config/economy.dart';
import '../../../core/theme/theme.dart';

/// Satu sesi meditasi. Urutan persis `design/Meditasi.dc.html`; judul &
/// deskripsi per bahasa ada di `MeditasiStrings.session(id)`.
/// 3 sesi pertama gratis ([EconomyFreeTier.meditasi]), sisanya premium.
class MeditationSession {
  const MeditationSession({
    required this.id,
    required this.ambientAsset,
    required this.category,
    required this.durations,
    required this.defaultDurationIndex,
    required this.targetMonsterId,
    required this.icon,
    required this.color,
  });

  final String id;
  /// Suara latar CC0 yang diputar berulang selama sesi (belum ada narasi;
  /// ritme napas diikuti lewat animasi di layar).
  final String ambientAsset;
  final String category;
  final List<int> durations;
  final int defaultDurationIndex;
  final String targetMonsterId;
  final IconData icon;
  final Color color;

  int get defaultDuration => durations[defaultDurationIndex];
}

/// Katalog statis — konten mengikuti `design/Meditasi.dc.html`, indeks
/// 0..[EconomyFreeTier.meditasi]-1 gratis (lihat [MeditationCatalog.isFree]).
abstract final class MeditationCatalog {
  static const List<MeditationSession> all = [
    MeditationSession(
      id: 'jeda_kerja',
      ambientAsset: AudioAssets.rain,
      category: 'kerja',
      durations: [5],
      defaultDurationIndex: 0,
      targetMonsterId: 'waswas',
      icon: Icons.center_focus_strong,
      color: AppColors.sekunder,
    ),
    MeditationSession(
      id: 'napas_4_7_8',
      ambientAsset: AudioAssets.waves,
      category: 'cemas',
      durations: [5, 10, 15],
      defaultDurationIndex: 1,
      targetMonsterId: 'waswas',
      icon: Icons.self_improvement,
      color: AppColors.sekunder,
    ),
    MeditationSession(
      id: 'tenang_ujian',
      ambientAsset: AudioAssets.rain,
      category: 'pelajar',
      durations: [7],
      defaultDurationIndex: 0,
      targetMonsterId: 'waswas',
      icon: Icons.menu_book_rounded,
      color: AppColors.aksenHangat,
    ),
    MeditationSession(
      id: 'body_scan',
      ambientAsset: AudioAssets.waves,
      category: 'cemas',
      durations: [12],
      defaultDurationIndex: 0,
      targetMonsterId: 'waswas',
      icon: Icons.accessibility_new,
      color: AppColors.primer,
    ),
    MeditationSession(
      id: 'menonton_pikiran',
      ambientAsset: AudioAssets.rain,
      category: 'cemas',
      durations: [8],
      defaultDurationIndex: 0,
      targetMonsterId: 'kabut',
      icon: Icons.auto_awesome,
      color: AppColors.monsterKabut,
    ),
    MeditationSession(
      id: 'berhenti_membandingkan',
      ambientAsset: AudioAssets.waves,
      category: 'pelajar',
      durations: [11],
      defaultDurationIndex: 0,
      targetMonsterId: 'cermin',
      icon: Icons.favorite,
      color: AppColors.monsterCermin,
    ),
  ];

  static bool isFree(int index) => index < EconomyFreeTier.meditasi;

  static bool isSessionFree(String id) {
    final index = all.indexWhere((s) => s.id == id);
    return index == -1 ? false : isFree(index);
  }

  static MeditationSession byId(String id) => all.firstWhere((s) => s.id == id);
}

/// Chip filter di perpustakaan (label per bahasa: `MeditasiStrings.filterLabel`).
enum MeditationFilter { semua, cemas, stresKerja, fokusBelajar, pemula }
