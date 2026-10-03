/// Teks laporan refleksi (mingguan gratis, bulanan Premium). Bahasa selalu
/// hangat, tidak menghakimi, dan hanya menyebut kecenderungan — bukan
/// sebab-akibat atau diagnosis.
abstract class LaporanStrings {
  const LaporanStrings();

  String get title;
  String get weekTab;
  String get monthTab;
  String get disclaimer;

  // ── ringkasan ──
  String activeSummary(int active, int window);
  String entriesSummary(int checkIns, int journals);
  String get averageLabel;
  String weekday(int weekday);

  // ── insight ──
  String get trendUp;
  String get trendDown;
  String get trendSteady;
  String bestDay(String day);
  String hardDay(String day);
  String topFactor(String factor, int count);
  String topMonster(String monster, int count);
  String factorLower(String factor);
  String factorHigher(String factor);
  String get insightsTitle;

  // ── data tidur (jam tangan) ──
  String duration(int minutes);
  String sleepAverage(String duration);
  String sleepMood(int restedHours, int shortHours);
  String get sleepConnectTitle;
  String get sleepConnectBody;
  String get sleepConnectCta;
  String get sleepConnected;
  String get sleepDisconnect;
  String get sleepConsentTitle;
  String get sleepConsentBody;
  String get sleepConsentAllow;
  String get sleepConsentLater;
  String get sleepUnsupported;
  String get sleepInstallBody;
  String get sleepInstallCta;
  String get sleepDenied;
  String get sleepNoData;

  // ── langkah kecil ──
  String get nextTitle;
  String get nextGentle;
  String get nextSteady;
  String get nextUp;

  // ── dukungan ──
  String get supportTitle;
  String get supportBody;
  String get supportCta;

  // ── data kurang ──
  String get emptyTitle;
  String emptyBody(int minDays, int active);
  String get emptyCta;

  // ── kunci Premium ──
  String get lockedTitle;
  String get lockedBody;
  String get lockedCta;
  String get monthLockedBody;

  // ── kartu Beranda ──
  String get homeTitle;
  String get homeSubReady;
  String get homeSubEmpty;
}

class LaporanStringsId extends LaporanStrings {
  const LaporanStringsId();

  @override
  String get title => 'Laporan refleksi';
  @override
  String get weekTab => 'Minggu ini';
  @override
  String get monthTab => 'Bulan ini';
  @override
  String get disclaimer => 'Ini alat refleksi dari catatanmu sendiri, bukan diagnosis. Datanya dihitung di HP-mu dan tidak dikirim ke mana pun.';

  @override
  String activeSummary(int active, int window) => 'Kamu hadir $active dari $window hari';
  @override
  String entriesSummary(int checkIns, int journals) => '$checkIns check-in · $journals jurnal';
  @override
  String get averageLabel => 'Rata-rata suasana hati';
  @override
  String weekday(int weekday) => const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'][weekday - 1];

  @override
  String get trendUp => 'Suasana hatimu terasa lebih ringan dibanding periode sebelumnya. Pelan-pelan, tapi nyata.';
  @override
  String get trendDown => 'Suasana hatimu terasa lebih berat dibanding periode sebelumnya. Itu wajar, dan kamu tetap hadir.';
  @override
  String get trendSteady => 'Suasana hatimu relatif stabil dibanding periode sebelumnya.';
  @override
  String bestDay(String day) => 'Hari yang biasanya terasa paling ringan: $day.';
  @override
  String hardDay(String day) => 'Hari yang biasanya lebih berat: $day. Boleh disiapkan lebih lembut.';
  @override
  String topFactor(String factor, int count) => 'Yang paling sering kamu sebut: $factor ($count kali).';
  @override
  String topMonster(String monster, int count) => 'Di jurnal, $monster paling sering muncul ($count kali).';
  @override
  String factorLower(String factor) => 'Di hari kamu menyebut $factor, suasana hatimu cenderung lebih rendah.';
  @override
  String factorHigher(String factor) => 'Di hari kamu menyebut $factor, suasana hatimu cenderung lebih baik.';
  @override
  String get insightsTitle => 'Yang terlihat dari catatanmu';

  @override
  String duration(int minutes) => '${minutes ~/ 60} jam ${minutes % 60} menit';
  @override
  String sleepAverage(String duration) => 'Rata-rata tidurmu sekitar $duration per malam.';
  @override
  String sleepMood(int restedHours, int shortHours) =>
      'Setelah tidur $restedHours jam atau lebih, suasana hatimu cenderung lebih baik dibanding setelah tidur kurang dari $shortHours jam.';
  @override
  String get sleepConnectTitle => 'Hubungkan data tidur';
  @override
  String get sleepConnectBody => 'Kalau kamu memakai jam tangan, Riung bisa membaca durasi tidurmu untuk melengkapi laporan. Opsional, dan bisa diputus kapan saja.';
  @override
  String get sleepConnectCta => 'Hubungkan';
  @override
  String get sleepConnected => 'Data tidur terhubung';
  @override
  String get sleepDisconnect => 'Putuskan';
  @override
  String get sleepConsentTitle => 'Izinkan Riung membaca data tidur?';
  @override
  String get sleepConsentBody =>
      'Riung hanya membaca durasi tidur dari Health Connect, dan hanya untuk laporan refleksimu. Datanya dibaca di HP-mu, tidak disimpan, dan tidak dikirim ke mana pun. Kamu bisa mencabut izin kapan saja di pengaturan Health Connect.';
  @override
  String get sleepConsentAllow => 'Lanjutkan';
  @override
  String get sleepConsentLater => 'Nanti saja';
  @override
  String get sleepUnsupported => 'HP-mu belum mendukung Health Connect, jadi data tidur belum bisa dihubungkan.';
  @override
  String get sleepInstallBody => 'Health Connect belum terpasang atau perlu diperbarui. Pasang dulu, lalu coba lagi.';
  @override
  String get sleepInstallCta => 'Pasang';
  @override
  String get sleepDenied => 'Izin belum diberikan. Nggak apa-apa, laporanmu tetap jalan tanpa data tidur.';
  @override
  String get sleepNoData => 'Belum ada data tidur dari jam tanganmu. Pastikan aplikasi jam menyimpan datanya ke Health Connect.';

  @override
  String get nextTitle => 'Langkah kecil berikutnya';
  @override
  String get nextGentle => 'Periode ini terasa berat. Cukup satu napas panjang atau satu kalimat di jurnal — nggak perlu lebih dari itu.';
  @override
  String get nextSteady => 'Pertahankan ritme yang sudah ada. Satu check-in singkat tiap hari sudah cukup.';
  @override
  String get nextUp => 'Ada yang mulai membaik. Coba ingat apa yang membantu, lalu ulangi sedikit saja.';

  @override
  String get supportTitle => 'Kamu nggak sendirian';
  @override
  String get supportBody => 'Beberapa hari terakhir terasa berat. Kalau butuh teman bicara, ada bantuan yang bisa kamu hubungi kapan saja.';
  @override
  String get supportCta => 'Lihat bantuan';

  @override
  String get emptyTitle => 'Laporanmu belum cukup terisi';
  @override
  String emptyBody(int minDays, int active) =>
      'Laporan mulai muncul setelah $minDays hari check-in. Sejauh ini $active hari — pelan-pelan saja, nggak ada yang terlewat.';
  @override
  String get emptyCta => 'Check-in sekarang';

  @override
  String get lockedTitle => 'Pola yang lebih dalam';
  @override
  String get lockedBody => 'Riung Premium menunjukkan pola antara faktor dan suasana hatimu, plus laporan bulanan.';
  @override
  String get lockedCta => 'Lihat Riung Premium';
  @override
  String get monthLockedBody => 'Laporan bulanan tersedia di Riung Premium — lihat gambaran 4 minggu sekaligus.';

  @override
  String get homeTitle => 'Laporan mingguanmu';
  @override
  String get homeSubReady => 'Lihat apa yang terlihat dari catatanmu minggu ini';
  @override
  String get homeSubEmpty => 'Muncul setelah beberapa hari check-in';
}

class LaporanStringsEn extends LaporanStrings {
  const LaporanStringsEn();

  @override
  String get title => 'Reflection report';
  @override
  String get weekTab => 'This week';
  @override
  String get monthTab => 'This month';
  @override
  String get disclaimer => 'A reflection tool built from your own notes, not a diagnosis. It is calculated on your phone and not sent anywhere.';

  @override
  String activeSummary(int active, int window) => 'You showed up $active of $window days';
  @override
  String entriesSummary(int checkIns, int journals) => '$checkIns check-ins · $journals journal entries';
  @override
  String get averageLabel => 'Average mood';
  @override
  String weekday(int weekday) => const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][weekday - 1];

  @override
  String get trendUp => 'Your mood felt lighter than the previous period. Slowly, but for real.';
  @override
  String get trendDown => 'Your mood felt heavier than the previous period. That is okay, and you still showed up.';
  @override
  String get trendSteady => 'Your mood stayed fairly steady compared with the previous period.';
  @override
  String bestDay(String day) => 'The day that usually feels lightest: $day.';
  @override
  String hardDay(String day) => 'The day that is usually heavier: $day. It may help to plan it more gently.';
  @override
  String topFactor(String factor, int count) => 'What you mention most: $factor ($count times).';
  @override
  String topMonster(String monster, int count) => 'In your journal, $monster shows up most ($count times).';
  @override
  String factorLower(String factor) => 'On days you mention $factor, your mood tends to be lower.';
  @override
  String factorHigher(String factor) => 'On days you mention $factor, your mood tends to be better.';
  @override
  String get insightsTitle => 'What your notes show';

  @override
  String duration(int minutes) => '${minutes ~/ 60} h ${minutes % 60} min';
  @override
  String sleepAverage(String duration) => 'You slept about $duration a night on average.';
  @override
  String sleepMood(int restedHours, int shortHours) =>
      'After sleeping $restedHours hours or more, your mood tends to be better than after less than $shortHours hours.';
  @override
  String get sleepConnectTitle => 'Connect sleep data';
  @override
  String get sleepConnectBody => 'If you wear a smartwatch, Riung can read how long you sleep to complete your report. Optional, and you can disconnect any time.';
  @override
  String get sleepConnectCta => 'Connect';
  @override
  String get sleepConnected => 'Sleep data connected';
  @override
  String get sleepDisconnect => 'Disconnect';
  @override
  String get sleepConsentTitle => 'Let Riung read your sleep data?';
  @override
  String get sleepConsentBody =>
      'Riung only reads sleep duration from Health Connect, and only for your reflection report. It is read on your phone, not stored, and not sent anywhere. You can revoke access any time in Health Connect settings.';
  @override
  String get sleepConsentAllow => 'Continue';
  @override
  String get sleepConsentLater => 'Not now';
  @override
  String get sleepUnsupported => 'Your phone does not support Health Connect yet, so sleep data cannot be connected.';
  @override
  String get sleepInstallBody => 'Health Connect is not installed or needs an update. Install it, then try again.';
  @override
  String get sleepInstallCta => 'Install';
  @override
  String get sleepDenied => 'Access was not granted. That is fine — your report works without sleep data.';
  @override
  String get sleepNoData => 'No sleep data from your watch yet. Make sure the watch app saves its data to Health Connect.';

  @override
  String get nextTitle => 'A small next step';
  @override
  String get nextGentle => 'This period felt heavy. One long breath or one sentence in your journal is enough — nothing more is needed.';
  @override
  String get nextSteady => 'Keep the rhythm you have. A short daily check-in is plenty.';
  @override
  String get nextUp => 'Something is getting better. Notice what helped, then repeat just a little of it.';

  @override
  String get supportTitle => 'You are not alone';
  @override
  String get supportBody => 'The last few days felt heavy. If you want someone to talk to, there is help you can reach any time.';
  @override
  String get supportCta => 'See help';

  @override
  String get emptyTitle => 'Your report is not filled in yet';
  @override
  String emptyBody(int minDays, int active) =>
      'The report appears after $minDays days of check-ins. So far it is $active — take it slowly, nothing is missed.';
  @override
  String get emptyCta => 'Check in now';

  @override
  String get lockedTitle => 'Deeper patterns';
  @override
  String get lockedBody => 'Riung Premium shows patterns between what you mention and your mood, plus a monthly report.';
  @override
  String get lockedCta => 'See Riung Premium';
  @override
  String get monthLockedBody => 'The monthly report is part of Riung Premium — see four weeks at a glance.';

  @override
  String get homeTitle => 'Your weekly report';
  @override
  String get homeSubReady => 'See what your notes show this week';
  @override
  String get homeSubEmpty => 'Appears after a few days of check-ins';
}
