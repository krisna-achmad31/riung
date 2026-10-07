import 'package:flutter/material.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../afirmasi/screens/afirmasi_kategori_screen.dart';
import '../../appbeku/screens/appbeku_setup_screen.dart';
import '../../checkin/screens/checkin_mood_screen.dart';
import '../../focus/screens/focus_mode_entry_screen.dart';
import '../../jurnal/screens/jurnal_home_screen.dart';
import '../../laporan/screens/laporan_screen.dart';
import '../../meditasi/screens/meditasi_list_screen.dart';
import '../../tidur/screens/tidur_list_screen.dart';

/// Membuka fitur app untuk satu langkah kecil / latihan peta. Selesai
/// ketika layar fitur ditutup lagi.
Future<void> openKenaliFeature(BuildContext context, KenaliFeature feature) {
  final Widget screen = switch (feature) {
    KenaliFeature.fokus => const FocusModeEntryScreen(),
    KenaliFeature.jurnal => const JurnalHomeScreen(),
    KenaliFeature.checkin => const CheckInMoodScreen(),
    KenaliFeature.meditasi => const MeditasiListScreen(),
    KenaliFeature.aplikasiBeku => const AppBekuSetupScreen(),
    KenaliFeature.tidur => const TidurListScreen(),
    KenaliFeature.afirmasi => const AfirmasiKategoriScreen(),
    KenaliFeature.laporan => const LaporanScreen(),
  };
  return Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}
