import '../models/personality_result.dart';
import 'kenali_result_repository.dart';
import 'local_prefs_store.dart';
import 'user_repository.dart';

/// Menyusun ekspor "Unduh semua dataku". Satu tempat yang tahu seluruh data
/// pengguna, supaya fitur baru yang menyimpan data pribadi tinggal
/// ditambahkan di sini (dan di `test/data_export_test.dart` yang menjaga
/// tidak ada kunci penyimpanan yang terlewat).
///
/// Isi jurnal SENGAJA tidak disertakan: tersimpan terenkripsi di perangkat
/// (CLAUDE.md aturan #5) dan ekspor ini bisa disalin/dibagikan sebagai
/// teks biasa. Yang diekspor cuma metadata jurnal (tanggal, mood, tag).
class DataExportBuilder {
  const DataExportBuilder({required this.userRepository, required this.prefs});

  final UserRepository userRepository;
  final LocalPrefsStore prefs;

  Future<Map<String, dynamic>> build({required String uid, required String note}) async {
    final profile = await userRepository.getUserProfile(uid);
    final wallet = await userRepository.getWallet(uid);
    final monsters = await userRepository.getMonsterProgress(uid);
    final checkIns = await userRepository.getCheckIns(uid);
    final jurnal = await userRepository.getJournalEntries(uid);
    final favorit = await userRepository.getFavoriteAffirmationIds(uid);
    final buatanSendiri = await userRepository.getCustomAffirmations(uid);

    return {
      'profil': {
        'nama': profile.displayName,
        'bergabung': profile.createdAt.toIso8601String(),
        'bahasa': prefs.languageCode,
        'streakSekarang': profile.streakCurrent,
        'streakTerbaik': profile.streakLongest,
        'asesmen': {
          'monsterDominan': profile.dominantSaboteurs,
          'skor': profile.assessmentScores,
          'selesai': profile.assessmentCompletedAt?.toIso8601String(),
        },
      },
      'premium': {
        'aktif': profile.premiumActive,
        'paket': profile.premiumPlan,
        'berlakuSampai': profile.premiumRenewsAt?.toIso8601String(),
      },
      'koin': {
        'saldo': wallet.coins,
        'totalDidapat': wallet.lifetimeEarned,
        'totalDipakai': wallet.lifetimeSpent,
        'tiket': prefs.ticketBalance,
        'pelindungStreak': prefs.streakShieldBalance,
        'sesiFokusPrabayar': prefs.prepaidFocusSessions,
      },
      'monster': monsters.map((id, m) => MapEntry(id, {'progres': m.progress, 'status': m.state.name})),
      'kosmetikDimiliki': prefs.ownedCosmetics.toList()..sort(),
      'kosmetikDipakai': prefs.monsterCosmetics,
      'checkIn': [
        for (final c in checkIns)
          {
            'tanggal': c.date.toIso8601String(),
            'mood': c.mood,
            'energi': c.energy,
            'kualitasTidur': c.sleepQuality,
            'faktor': c.factors,
            'niat': c.intention,
          },
      ],
      'jurnalMetadata': [
        for (final j in jurnal) {'tanggal': j.createdAt.toIso8601String(), 'mood': j.mood, 'tags': j.tags},
      ],
      'afirmasi': {
        'favorit': favorit.toList()..sort(),
        'buatanSendiri': [for (final a in buatanSendiri) {'id': a.id, 'teks': a.teks}],
      },
      'kepribadian': personalitySection(),
      // Hasil Kenali Dirimu (skor/kategori; jawaban mentah tidak pernah disimpan).
      'kenaliDirimu': {
        for (final e in (KenaliResultRepository.instance.results.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) e.key: e.value.toMap(),
      },
      'kenaliDirimuRiwayat': [
        for (final r in KenaliResultRepository.instance.history) {'testId': r.testId, ...r.toMap()},
      ],
      'betterMe': {
        'sesiSelesai': prefs.betterMeCompleted.toList()..sort(),
        'refleksi': prefs.betterMeReflectionsJson,
      },
      'appBeku': {
        'kunciAktif': prefs.appBekuLockEnabled,
        'aplikasi': prefs.frozenAppsJson,
      },
      'pengaturan': {
        'notifikasi': prefs.notifSettingsJson,
        'pengingatTidur': prefs.hasSleepReminder ? prefs.sleepReminder.toMap() : null,
        'jamAfirmasi': prefs.afirmasiReminderTime,
        'biometrikJurnal': prefs.biometricUnlockEnabled,
        'dataTidurTerhubung': prefs.sleepSyncEnabled,
      },
      'catatan': note,
    };
  }

  /// Hasil tes kepribadian + karakter yang dipakai (aksesori, gaya kartu).
  Map<String, dynamic> personalitySection() {
    final results = prefs.personalityResults;
    final accessories = prefs.personalityAccessories;
    return {
      for (final test in PersonalityTest.values)
        test.name: {
          'hasil': results[test]?.toMap(),
          'aksesoriDipakai': accessories[test.name] ?? const <String, String>{},
          'gayaKartu': prefs.personalityCardStyle(test),
        },
    };
  }
}
