import 'app_language.dart';
import 'strings/common_strings.dart';
import 'strings/kepribadian_strings.dart';
import 'strings/laporan_strings.dart';
import 'strings/appbeku_strings.dart';
import 'strings/betterme_strings.dart';
import 'strings/tidur_strings.dart';
import 'strings/meditasi_strings.dart';
import 'strings/jurnal_strings.dart';
import 'strings/toko_strings.dart';
import 'strings/monster_strings.dart';
import 'strings/checkin_strings.dart';
import 'strings/afirmasi_strings.dart';
import 'strings/focus_strings.dart';
import 'strings/notif_strings.dart';
import 'strings/minigame_strings.dart';
import 'strings/home_strings.dart';
import 'strings/onboarding_strings.dart';
import 'strings/launch_strings.dart';
import 'strings/profil_strings.dart';

/// Pintu tunggal ke semua teks UI. Tiap fitur punya class strings sendiri di
/// `l10n/strings/` (abstract + implementasi per bahasa dalam SATU file, supaya
/// terjemahan berdampingan & mudah dicek). Bahasa baru cukup menambah
/// implementasi baru — kompiler menolak build kalau ada teks yang belum
/// diterjemahkan.
///
/// Pakai lewat `context.s.<fitur>.<teks>` (lihat `language_scope.dart`).
abstract class AppStrings {
  const AppStrings();

  static AppStrings of(AppLanguage language) {
    switch (language) {
      case AppLanguage.indonesia:
        return const AppStringsId();
      case AppLanguage.english:
        return const AppStringsEn();
    }
  }

  AppLanguage get language;

  /// Locale `intl` untuk `DateFormat`.
  String get dateLocale => language.intlLocale;

  CommonStrings get common;
  KepribadianStrings get kepribadian;
  LaporanStrings get laporan;
  AppbekuStrings get appbeku;
  BettermeStrings get betterme;
  TidurStrings get tidur;
  MeditasiStrings get meditasi;
  JurnalStrings get jurnal;
  TokoStrings get toko;
  MonsterStrings get monster;
  CheckinStrings get checkin;
  AfirmasiStrings get afirmasi;
  FocusStrings get focus;
  NotifStrings get notif;
  MinigameStrings get minigame;
  HomeStrings get home;
  OnboardingStrings get onboarding;
  LaunchStrings get launch;
  ProfilStrings get profil;
}

class AppStringsId extends AppStrings {
  const AppStringsId();

  @override
  AppLanguage get language => AppLanguage.indonesia;

  @override
  CommonStrings get common => const CommonStringsId();

  @override
  KepribadianStrings get kepribadian => const KepribadianStringsId();

  @override
  LaporanStrings get laporan => const LaporanStringsId();

  @override
  AppbekuStrings get appbeku => const AppbekuStringsId();

  @override
  BettermeStrings get betterme => const BettermeStringsId();

  @override
  TidurStrings get tidur => const TidurStringsId();

  @override
  MeditasiStrings get meditasi => const MeditasiStringsId();

  @override
  JurnalStrings get jurnal => const JurnalStringsId();

  @override
  TokoStrings get toko => const TokoStringsId();

  @override
  MonsterStrings get monster => const MonsterStringsId();

  @override
  CheckinStrings get checkin => const CheckinStringsId();

  @override
  AfirmasiStrings get afirmasi => const AfirmasiStringsId();

  @override
  FocusStrings get focus => const FocusStringsId();

  @override
  NotifStrings get notif => const NotifStringsId();

  @override
  MinigameStrings get minigame => const MinigameStringsId();

  @override
  HomeStrings get home => const HomeStringsId();

  @override
  OnboardingStrings get onboarding => const OnboardingStringsId();

  @override
  LaunchStrings get launch => const LaunchStringsId();

  @override
  ProfilStrings get profil => const ProfilStringsId();
}

class AppStringsEn extends AppStrings {
  const AppStringsEn();

  @override
  AppLanguage get language => AppLanguage.english;

  @override
  CommonStrings get common => const CommonStringsEn();

  @override
  KepribadianStrings get kepribadian => const KepribadianStringsEn();

  @override
  LaporanStrings get laporan => const LaporanStringsEn();

  @override
  AppbekuStrings get appbeku => const AppbekuStringsEn();

  @override
  BettermeStrings get betterme => const BettermeStringsEn();

  @override
  TidurStrings get tidur => const TidurStringsEn();

  @override
  MeditasiStrings get meditasi => const MeditasiStringsEn();

  @override
  JurnalStrings get jurnal => const JurnalStringsEn();

  @override
  TokoStrings get toko => const TokoStringsEn();

  @override
  MonsterStrings get monster => const MonsterStringsEn();

  @override
  CheckinStrings get checkin => const CheckinStringsEn();

  @override
  AfirmasiStrings get afirmasi => const AfirmasiStringsEn();

  @override
  FocusStrings get focus => const FocusStringsEn();

  @override
  NotifStrings get notif => const NotifStringsEn();

  @override
  MinigameStrings get minigame => const MinigameStringsEn();

  @override
  HomeStrings get home => const HomeStringsEn();

  @override
  OnboardingStrings get onboarding => const OnboardingStringsEn();

  @override
  LaunchStrings get launch => const LaunchStringsEn();

  @override
  ProfilStrings get profil => const ProfilStringsEn();
}
