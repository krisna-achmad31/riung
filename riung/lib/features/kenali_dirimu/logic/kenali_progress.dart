import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/models/kenali_result.dart';
import '../../../core/models/personality_result.dart';
import '../../../core/services/kenali_result_repository.dart';

/// Turunan hasil Kenali Dirimu yang dipakai lintas layar (hub, Profil,
/// brankas). Semua dihitung ulang dari hasil tersimpan — tidak ada state
/// tambahan yang bisa basi.
abstract final class KenaliProgress {
  static KenaliResultRepository get _repo => KenaliResultRepository.instance;

  /// Monster yang dibangunkan/ditautkan oleh satu hasil (null = tidak ada).
  static String? monsterOf(KenaliEntry entry, KenaliResult result) =>
      entry.monsterFor(dominantTrait: result.dominantTrait, score: result.score);

  /// Jumlah tes selesai (JSON + tes kepribadian).
  static int doneCount(Map<PersonalityTest, PersonalityResult> personality) {
    final json = KenaliDirimuConfig.entries.where((e) => _repo.resultOf(e.id) != null).length;
    return json + personality.length;
  }

  /// Hasil kuis yang membangunkan [monsterId], kalau monster itu bangun.
  static KenaliResult? wakingResult(String monsterId) {
    final entry = KenaliDirimuConfig.quizForMonster(monsterId);
    if (entry == null) return null;
    final result = _repo.resultOf(entry.id);
    if (result == null || monsterOf(entry, result) != monsterId) return null;
    return result;
  }

  static bool isAwake(String monsterId) => wakingResult(monsterId) != null;

  /// Monster Kebiasaan yang sudah bangun, urut waktu bangun terbaru dulu.
  static List<String> awakeHabitMonsters() {
    final awake = [
      for (final id in KenaliDirimuConfig.habitMonsters)
        if (wakingResult(id) != null) id,
    ];
    awake.sort((a, b) => wakingResult(b)!.completedAt.compareTo(wakingResult(a)!.completedAt));
    return awake;
  }

  /// Trait wujud monster kebiasaan (null untuk Si Bara / belum bangun).
  static String? wujudTrait(String monsterId) => wakingResult(monsterId)?.dominantTrait;
}
