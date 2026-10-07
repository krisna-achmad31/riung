import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/saboteur.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Satu latihan di peta Monster Kebiasaan: ikon node (frame `Peta latihan
/// Si …`) + fitur app yang bisa dibuka (null = latihan di dunia nyata).
class HabitPractice {
  const HabitPractice(this.icon, [this.feature]);

  final RiungIcon icon;
  final KenaliFeature? feature;
}

/// Monster Kebiasaan (keluarga kedua, bangun HANYA dari Kuis Besar Kenali
/// Dirimu). Tiga latihan berurutan per monster, lalu node bos.
abstract final class HabitMonsters {
  static const practices = <String, List<HabitPractice>>{
    'nanti': [HabitPractice(RiungIcon.fokus, KenaliFeature.fokus), HabitPractice(RiungIcon.jurnal, KenaliFeature.jurnal), HabitPractice(RiungIcon.checkin, KenaliFeature.checkin)],
    'gulir': [HabitPractice(RiungIcon.meditasi, KenaliFeature.meditasi), HabitPractice(RiungIcon.aplikasiBeku, KenaliFeature.aplikasiBeku), HabitPractice(RiungIcon.fokus)],
    'begadang': [HabitPractice(RiungIcon.jurnal, KenaliFeature.jurnal), HabitPractice(RiungIcon.tidur, KenaliFeature.tidur), HabitPractice(RiungIcon.streak, KenaliFeature.checkin)],
    'bunglon': [HabitPractice(RiungIcon.jurnal, KenaliFeature.jurnal), HabitPractice(RiungIcon.afirmasi, KenaliFeature.afirmasi), HabitPractice(RiungIcon.pelindung)],
    'bimbang': [HabitPractice(RiungIcon.afirmasi, KenaliFeature.afirmasi), HabitPractice(RiungIcon.fokus, KenaliFeature.fokus), HabitPractice(RiungIcon.jurnal, KenaliFeature.jurnal)],
    'bara': [HabitPractice(RiungIcon.meditasi, KenaliFeature.meditasi), HabitPractice(RiungIcon.laporan, KenaliFeature.laporan), HabitPractice(RiungIcon.afirmasi, KenaliFeature.afirmasi)],
  };

  static bool isHabit(String monsterId) => practices.containsKey(monsterId);

  static List<HabitPractice> practicesOf(String monsterId) => practices[monsterId] ?? const [];

  /// Monster kebiasaan sebagai [Saboteur] supaya alur serangan (mini-game,
  /// progres) yang sudah ada bisa dipakai apa adanya.
  static Saboteur saboteurFor(String monsterId, AppStrings s) => Saboteur(
        id: monsterId,
        nama: s.common.monsterName(monsterId),
        distorsiCbt: s.kenali.habitPill(monsterId),
        warna: AppColors.monsterColors[monsterId] ?? AppColors.primer,
        deskripsi: s.kenali.habitRealWorld(monsterId),
        tanda: s.kenali.habitQuotes(monsterId),
        caraMenjinakkan: s.kenali.habitTechnique(monsterId),
        faktaRiset: s.kenali.habitFact(monsterId),
        isBoss: false,
      );
}
