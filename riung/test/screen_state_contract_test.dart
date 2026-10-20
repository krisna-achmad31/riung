import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kontrak state layar (CLAUDE.md "Definition of done"): layar fitur yang
/// memuat data wajib lewat `RiungStateView` / `RiungAsyncView` — skeleton
/// saat loading, `RiungErrorWidget` + "Coba lagi" saat gagal, empty state
/// saat kosong. Offline ditangani global oleh `RiungOfflineBanner`.
void main() {
  final features = Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String rel(File f) => f.path.replaceAll(r'\', '/');

  /// Pemakaian spinner yang BUKAN loading layar (cincin progres / spinner
  /// kecil di tombol), dengan alasannya.
  const spinnerAllowed = {
    'lib/features/betterme/screens/betterme_home_screen.dart', // cincin progres level
    'lib/features/meditasi/screens/meditasi_player_screen.dart', // cincin progres sesi
    'lib/features/onboarding/widgets/analyzing_step.dart', // animasi "menganalisis"
    'lib/features/kepribadian/screens/kepribadian_hub_screen.dart', // spinner kecil tombol "muat pola"
  };

  /// Pemuat yang hanya jalan saat aksi pengguna (tap) atau data opsional
  /// kecil yang punya fallback sendiri, bukan isi utama layar.
  const loaderAllowed = {
    'lib/features/afirmasi/screens/afirmasi_buat_screen.dart', // tag monster opsional
    'lib/features/afirmasi/screens/afirmasi_kartu_screen.dart', // tanda favorit opsional
    'lib/features/home/screens/kartu_pemain_screen.dart', // satu angka statistik ("…")
    'lib/features/kenali_dirimu/screens/kenali_hasil_screen.dart', // tap "lihat monster"
    'lib/features/kepribadian/screens/kepribadian_hub_screen.dart', // tap "muat pola"
    'lib/features/monster/screens/waswas_stage_map_screen.dart', // tap "afirmasi"
  };

  test('tidak ada FutureBuilder/StreamBuilder di layar fitur', () {
    final offenders = [
      for (final f in features)
        if (RegExp(r'\b(FutureBuilder|StreamBuilder)\b').hasMatch(f.readAsStringSync())) rel(f),
    ];
    expect(offenders, isEmpty, reason: 'pakai RiungAsyncView');
  });

  test('loading layar memakai skeleton, bukan spinner polos', () {
    final offenders = [
      for (final f in features)
        if (f.readAsStringSync().contains('CircularProgressIndicator') && !spinnerAllowed.contains(rel(f))) rel(f),
    ];
    expect(offenders, isEmpty, reason: 'pakai RiungStateView / RiungSkeletonList');
  });

  test('layar yang memuat data memakai RiungStateView/RiungAsyncView', () {
    final loader = RegExp(r'\.(getCheckIns|getJournalEntries|getSaboteurs|getAffirmations|getTransactions|getCustomAffirmations|getFavoriteAffirmationIds)\(');
    final offenders = [
      for (final f in features)
        if (loader.hasMatch(f.readAsStringSync()) &&
            !RegExp(r'RiungStateView|RiungAsyncView').hasMatch(f.readAsStringSync()) &&
            !loaderAllowed.contains(rel(f)))
          rel(f),
    ];
    expect(offenders, isEmpty);
  });

  test('daftar pengecualian tidak basi', () {
    for (final path in {...spinnerAllowed, ...loaderAllowed}) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
