import '../../../core/config/audio_assets.dart';
import '../../../core/config/economy.dart';

/// Satu cerita tidur — rekaman LibriVox (domain publik / CC0), audionya
/// berbahasa Inggris. Judul, deskripsi, dan keterangan per bahasa ada di
/// `TidurStrings.story(id)`. 2 cerita pertama gratis
/// ([EconomyFreeTier.ceritaTidur]), sisanya premium.
class SleepStory {
  const SleepStory({
    required this.id,
    required this.reader,
    required this.durationMinutes,
    required this.targetMonsterId,
    required this.assetPath,
  });

  final String id;

  /// Pembaca (relawan LibriVox) — nama asli, bukan terjemahan.
  final String reader;
  final int durationMinutes;
  final String targetMonsterId;
  final String assetPath;
}

abstract final class SleepCatalog {
  static const List<SleepStory> stories = [
    SleepStory(
      id: 'happy_prince',
      reader: 'om123',
      durationMinutes: 24,
      targetMonsterId: 'meronta',
      assetPath: AudioAssets.happyPrince,
    ),
    SleepStory(
      id: 'selfish_giant',
      reader: 'om123',
      durationMinutes: 11,
      targetMonsterId: 'meronta',
      assetPath: AudioAssets.selfishGiant,
    ),
    SleepStory(
      id: 'nightingale_rose',
      reader: 'om123',
      durationMinutes: 16,
      targetMonsterId: 'meronta',
      assetPath: AudioAssets.nightingaleRose,
    ),
    SleepStory(
      id: 'velveteen_rabbit',
      reader: 'Barbara Bear & Mama Bear',
      durationMinutes: 23,
      targetMonsterId: 'meronta',
      assetPath: AudioAssets.velveteenRabbit,
    ),
  ];

  static bool isFree(int index) => index < EconomyFreeTier.ceritaTidur;

  static bool isStoryFree(String id) {
    final index = stories.indexWhere((s) => s.id == id);
    return index == -1 ? false : isFree(index);
  }
}

/// Suasana suara; label per bahasa: `TidurStrings.soundLabel(id)`.
class Soundscape {
  const Soundscape({required this.id, required this.assetPath});
  final String id;
  final String assetPath;
}

const List<Soundscape> soundscapes = [
  Soundscape(id: 'hujan', assetPath: AudioAssets.rain),
  Soundscape(id: 'ombak', assetPath: AudioAssets.waves),
  Soundscape(id: 'kipas', assetPath: AudioAssets.fan),
];

const List<int> sleepTimerPresets = [30, 45, 60];
