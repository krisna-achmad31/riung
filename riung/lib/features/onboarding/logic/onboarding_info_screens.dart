import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/riung_monster.dart';

/// Konfigurasi VISUAL satu layar info (aksen, glow, monster, titik
/// progres). Teksnya (kicker, judul, isi, sumber, tombol) ada di
/// `OnboardingStrings.infoScreens` dengan urutan indeks yang sama, supaya
/// bisa diganti bahasa tanpa menyentuh konfigurasi ini.
class OnboardingInfoScreen {
  const OnboardingInfoScreen({
    required this.glowColor,
    required this.accentColor,
    required this.dotIndex,
    required this.dotTotal,
    this.monsterId,
    this.monsterState = MonsterVisualState.liar,
    this.monsterWidth,
    this.monsterHeight,
    this.monsterRow,
  });

  final Color glowColor;
  final Color accentColor;
  final int dotIndex;
  final int dotTotal;
  final String? monsterId;
  final MonsterVisualState monsterState;
  final double? monsterWidth;
  final double? monsterHeight;
  final List<String>? monsterRow;
}

/// 11 layar info — urutan persis `design/Onboarding.dc.html` (array `IS`):
/// reality check ×4, masalahmu ×3, dampak ×1, cara Riung membantu ×3.
final List<OnboardingInfoScreen> onboardingInfoScreens = [
  const OnboardingInfoScreen(
    glowColor: AppColors.primer,
    accentColor: AppColors.primer,
    dotIndex: 0,
    dotTotal: 4,
  ),
  const OnboardingInfoScreen(
    glowColor: AppColors.monsterWaswas,
    accentColor: AppColors.monsterWaswas,
    dotIndex: 1,
    dotTotal: 4,
  ),
  const OnboardingInfoScreen(
    glowColor: AppColors.error,
    accentColor: AppColors.error,
    dotIndex: 2,
    dotTotal: 4,
  ),
  const OnboardingInfoScreen(
    glowColor: AppColors.sekunder,
    accentColor: AppColors.sekunder,
    dotIndex: 3,
    dotTotal: 4,
  ),
  const OnboardingInfoScreen(
    glowColor: AppColors.monsterKabut,
    accentColor: AppColors.monsterKabut,
    dotIndex: 0,
    dotTotal: 3,
    monsterId: 'kabut',
    monsterWidth: 130,
    monsterHeight: 136,
  ),
  const OnboardingInfoScreen(
    glowColor: AppColors.monsterHakim,
    accentColor: AppColors.monsterHakim,
    dotIndex: 1,
    dotTotal: 3,
    monsterRow: ['meronta', 'waswas', 'kabut', 'cermin', 'sempurna', 'mengelak'],
  ),
  const OnboardingInfoScreen(
    glowColor: AppColors.monsterHakim,
    accentColor: AppColors.monsterHakim,
    dotIndex: 2,
    dotTotal: 3,
    monsterId: 'hakim',
    monsterWidth: 150,
    monsterHeight: 157,
  ),
  const OnboardingInfoScreen(
    glowColor: AppColors.error,
    accentColor: AppColors.error,
    dotIndex: 0,
    dotTotal: 1,
    monsterId: 'meronta',
    monsterWidth: 120,
    monsterHeight: 126,
  ),
  const OnboardingInfoScreen(
    glowColor: AppColors.sekunder,
    accentColor: AppColors.sekunder,
    dotIndex: 0,
    dotTotal: 3,
    monsterId: 'sempurna',
    monsterState: MonsterVisualState.jinak,
    monsterWidth: 110,
    monsterHeight: 115,
  ),
  const OnboardingInfoScreen(
    glowColor: AppColors.primer,
    accentColor: AppColors.primer,
    dotIndex: 1,
    dotTotal: 3,
    monsterId: 'waswas',
    monsterState: MonsterVisualState.jinak,
    monsterWidth: 110,
    monsterHeight: 115,
  ),
  const OnboardingInfoScreen(
    glowColor: AppColors.aksenHangat,
    accentColor: AppColors.aksenHangat,
    dotIndex: 2,
    dotTotal: 3,
    monsterId: 'mengelak',
    monsterState: MonsterVisualState.jinak,
    monsterWidth: 110,
    monsterHeight: 115,
  ),
];
