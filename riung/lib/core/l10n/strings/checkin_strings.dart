/// Teks fitur Check-in (3 langkah + hasil + riwayat mood).
abstract class CheckinStrings {
  const CheckinStrings();

  // ── Langkah 1: mood ──
  String moodTitle(String name);
  String get moodSub;
  String get skipToday;
  String moodLabel(String id);

  // ── Langkah 2: faktor ──
  String get factorTitle;
  String get factorSub;
  String get hakimInsight;
  String factorLabel(String id);

  // ── Langkah 3: catatan ──
  String get noteTitle;
  List<String> get quickReplies;
  String get noteLock;
  String get finish;
  String get saving;
  String get skipNote;

  // ── Hasil ──
  String get resultTitle;
  String get coinsLabel;
  String get daysInARow;
  String get suggestionsLabel;
  String get suggestionPauseTitle;
  String get suggestionPauseSub;
  String get suggestionCbtTitle;
  String get suggestionCbtSub;
  String get resultHakimInsight;
  String get startMyDay;

  // ── Riwayat ──
  String get historyTitle;
  String get historyEmpty;
  String get last7Days;
  String get mostFrequent;
  String factorCount(String label, int count);
}

class CheckinStringsId extends CheckinStrings {
  const CheckinStringsId();

  @override
  String moodTitle(String name) => 'Pagi, $name. Gimana rasanya hari ini?';
  @override
  String get moodSub => 'Jawaban apa pun nggak ada yang salah.';
  @override
  String get skipToday => 'Lewati hari ini, streak tetap aman';
  @override
  String moodLabel(String id) {
    switch (id) {
      case 'berat':
        return 'Berat';
      case 'agak_berat':
        return 'Agak berat';
      case 'datar':
        return 'Datar';
      case 'cukup_baik':
        return 'Cukup baik';
      case 'senang':
        return 'Senang';
    }
    return id;
  }

  @override
  String get factorTitle => 'Apa yang paling kepikiran?';
  @override
  String get factorSub => 'Pilih maksimal 3 ya, biar sarannya pas.';
  @override
  String get hakimInsight =>
      '"Kerjaan" sama "takut gagal" itu kombinasi favorit Si Hakim. Nanti Riung siapkan latihan yang tepat sasaran.';
  @override
  String factorLabel(String id) {
    switch (id) {
      case 'kerjaan':
        return 'Kerjaan';
      case 'kuliah':
        return 'Kuliah / sekolah';
      case 'takut_gagal':
        return 'Takut gagal';
      case 'keluarga':
        return 'Keluarga';
      case 'uang':
        return 'Uang';
      case 'hubungan':
        return 'Hubungan';
      case 'kurang_tidur':
        return 'Kurang tidur';
      case 'kesehatan':
        return 'Kesehatan';
      case 'medsos':
        return 'Media sosial';
      case 'lainnya':
        return 'Lainnya';
    }
    return id;
  }

  @override
  String get noteTitle => 'Mau cerita dikit? Satu kalimat cukup.';
  @override
  List<String> get quickReplies => const ['Capek aja', 'Nggak tahu kenapa', 'Biasa aja sih'];
  @override
  String get noteLock => 'Catatan ini masuk jurnal terkuncimu, nggak pernah dibagikan.';
  @override
  String get finish => 'Selesai check-in';
  @override
  String get saving => 'Menyimpan…';
  @override
  String get skipNote => 'Lewati catatan';

  @override
  String get resultTitle => 'Makasih udah jujur sama diri sendiri';
  @override
  String get coinsLabel => 'koin';
  @override
  String get daysInARow => 'hari beruntun';
  @override
  String get suggestionsLabel => 'SARAN BUAT PAGIMU';
  @override
  String get suggestionPauseTitle => 'Jeda di Tengah Kerja';
  @override
  String get suggestionPauseSub => '5 mnt · pas buat deadline numpuk';
  @override
  String get suggestionCbtTitle => 'Uji pikiran "dianggap kurang"';
  @override
  String get suggestionCbtSub => 'Panduan CBT · melemahkan Si Hakim';
  @override
  String get resultHakimInsight =>
      'Si Hakim sering muncul bareng "kerjaan" + "takut gagal" di catatanmu. Polanya mulai kebaca.';
  @override
  String get startMyDay => 'Mulai hariku';

  @override
  String get historyTitle => 'Riwayat mood';
  @override
  String get historyEmpty => 'Belum ada riwayat check-in. Mulai besok pagi, ya.';
  @override
  String get last7Days => '7 hari terakhir';
  @override
  String get mostFrequent => 'Yang paling sering muncul';
  @override
  String factorCount(String label, int count) => '$label · $count hari';
}

class CheckinStringsEn extends CheckinStrings {
  const CheckinStringsEn();

  @override
  String moodTitle(String name) => 'Morning, $name. How does today feel?';
  @override
  String get moodSub => 'There are no wrong answers.';
  @override
  String get skipToday => 'Skip today, your streak stays safe';
  @override
  String moodLabel(String id) {
    switch (id) {
      case 'berat':
        return 'Heavy';
      case 'agak_berat':
        return 'A bit heavy';
      case 'datar':
        return 'Flat';
      case 'cukup_baik':
        return 'Pretty good';
      case 'senang':
        return 'Happy';
    }
    return id;
  }

  @override
  String get factorTitle => 'What is on your mind the most?';
  @override
  String get factorSub => 'Pick up to 3, so the suggestions fit.';
  @override
  String get hakimInsight =>
      '"Work" plus "fear of failing" is Si Hakim\'s favorite combo. Riung will prepare exercises that hit the mark.';
  @override
  String factorLabel(String id) {
    switch (id) {
      case 'kerjaan':
        return 'Work';
      case 'kuliah':
        return 'College / school';
      case 'takut_gagal':
        return 'Fear of failing';
      case 'keluarga':
        return 'Family';
      case 'uang':
        return 'Money';
      case 'hubungan':
        return 'Relationships';
      case 'kurang_tidur':
        return 'Lack of sleep';
      case 'kesehatan':
        return 'Health';
      case 'medsos':
        return 'Social media';
      case 'lainnya':
        return 'Other';
    }
    return id;
  }

  @override
  String get noteTitle => 'Want to share a little? One sentence is enough.';
  @override
  List<String> get quickReplies => const ['Just tired', 'Not sure why', 'Just okay'];
  @override
  String get noteLock => 'This note goes into your locked journal and is never shared.';
  @override
  String get finish => 'Finish check-in';
  @override
  String get saving => 'Saving…';
  @override
  String get skipNote => 'Skip note';

  @override
  String get resultTitle => 'Thanks for being honest with yourself';
  @override
  String get coinsLabel => 'coins';
  @override
  String get daysInARow => 'days in a row';
  @override
  String get suggestionsLabel => 'SUGGESTIONS FOR YOUR MORNING';
  @override
  String get suggestionPauseTitle => 'Break in the Middle of Work';
  @override
  String get suggestionPauseSub => '5 min · just right for piled-up deadlines';
  @override
  String get suggestionCbtTitle => 'Test the thought "seen as not enough"';
  @override
  String get suggestionCbtSub => 'CBT guide · weakens Si Hakim';
  @override
  String get resultHakimInsight =>
      'Si Hakim often shows up together with "work" + "fear of failing" in your notes. The pattern is starting to show.';
  @override
  String get startMyDay => 'Start my day';

  @override
  String get historyTitle => 'Mood history';
  @override
  String get historyEmpty => 'No check-in history yet. Start tomorrow morning.';
  @override
  String get last7Days => 'Last 7 days';
  @override
  String get mostFrequent => 'Most frequent';
  @override
  String factorCount(String label, int count) => '$label · ${count == 1 ? '1 day' : '$count days'}';
}
