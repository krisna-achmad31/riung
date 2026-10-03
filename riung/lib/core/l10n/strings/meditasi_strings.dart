import '../../../features/meditasi/logic/meditation_catalog.dart';

/// Judul & deskripsi satu sesi meditasi (nama pemandu bukan terjemahan,
/// tetap di katalog).
class MeditationText {
  const MeditationText({required this.title, required this.description});

  final String title;
  final String description;
}

/// Teks fitur Meditasi: perpustakaan, pencarian, detail, pemutar, selesai.
abstract class MeditasiStrings {
  const MeditasiStrings();

  // ── Katalog ──
  MeditationText session(String id);
  String filterLabel(MeditationFilter filter);

  // ── Perpustakaan ──
  String get title;
  String get subtitle;
  String get featuredKicker;
  String get play;
  String durationCoins(int minutes, int coins);
  String get sectionAnxiety;
  String get sectionStudents;
  String emptyCategory(String category);
  String durationAmbient(int minutes);

  // ── Pencarian ──
  String get searchHint;
  String get searchEmptyTitle;
  String searchEmptyBody(String query);
  List<String> get searchSuggestions;

  // ── Detail ──
  String get download;
  String get alreadyOffline;
  String fighting(String monsterName);
  String get duration;
  String minutes(int minutes);
  String get ambientTitle;
  String get ambientNote;
  String get whenDone;
  String tame(String monsterName);
  String get startSession;
  String freeTierNote(int freeCount);

  // ── Pemutar ──
  String get preparingTitle;
  String get preparingBody;
  String get running;
  String get followRhythm;
  String get seekBack;
  String get seekForward;
  String get breathIn;
  String breathHold(int seconds);
  String get breathOut;

  // ── Selesai ──
  String doneTitle(int minutes);
  String get doneBody;
  String get coins;
  String get totalSessions;
  String get repeatSession;
}

class MeditasiStringsId extends MeditasiStrings {
  const MeditasiStringsId();

  @override
  MeditationText session(String id) {
    switch (id) {
      case 'jeda_kerja':
        return const MeditationText(
          title: 'Jeda di Tengah Kerja',
          description: '5 menit melepas tegang di antara rapat, tanpa perlu ruang khusus.',
        );
      case 'napas_4_7_8':
        return const MeditationText(
          title: 'Napas 4-7-8 untuk Meredakan Cemas',
          description:
              'Teknik pernapasan sederhana yang menenangkan sistem sarafmu. Cocok saat dada terasa '
              'sesak sebelum ujian atau presentasi.',
        );
      case 'tenang_ujian':
        return const MeditationText(
          title: 'Tenang Sebelum Ujian',
          description: 'Latihan singkat menenangkan degup jantung sebelum menghadapi ujian atau presentasi.',
        );
      case 'body_scan':
        return const MeditationText(
          title: 'Body Scan: Turunkan Tegang di Bahu',
          description: 'Menyusuri tubuh pelan-pelan untuk melepas ketegangan yang menumpuk di bahu & leher.',
        );
      case 'menonton_pikiran':
        return const MeditationText(
          title: 'Menonton Pikiran Lewat',
          description: 'Latihan mindfulness membiarkan pikiran datang & pergi tanpa perlu dilawan.',
        );
      case 'berhenti_membandingkan':
        return const MeditationText(
          title: 'Berhenti Membandingkan Diri',
          description: 'Meredakan dorongan membandingkan diri lewat latihan menghargai langkah sendiri.',
        );
    }
    return const MeditationText(title: '', description: '');
  }

  @override
  String filterLabel(MeditationFilter filter) {
    switch (filter) {
      case MeditationFilter.semua:
        return 'Semua';
      case MeditationFilter.cemas:
        return 'Cemas';
      case MeditationFilter.stresKerja:
        return 'Stres kerja';
      case MeditationFilter.fokusBelajar:
        return 'Fokus belajar';
      case MeditationFilter.pemula:
        return 'Pemula';
    }
  }

  @override
  String get title => 'Meditasi';
  @override
  String get subtitle => 'Pilih sesi yang pas buat kamu hari ini';
  @override
  String get featuredKicker => 'UNTUK JAM KERJAMU';
  @override
  String get play => 'Putar';
  @override
  String durationCoins(int minutes, int coins) => '$minutes mnt · +$coins koin';
  @override
  String get sectionAnxiety => 'Redakan cemas';
  @override
  String get sectionStudents => 'Buat pelajar & mahasiswa';
  @override
  String emptyCategory(String category) => 'Belum ada sesi buat kategori "$category".';
  @override
  String durationAmbient(int minutes) => '$minutes mnt · suara latar';

  @override
  String get searchHint => 'Cari sesi meditasi';
  @override
  String get searchEmptyTitle => 'Belum ketemu yang itu';
  @override
  String searchEmptyBody(String query) => 'Nggak ada hasil untuk "$query". Coba kata yang lebih umum, atau intip yang sering dicari:';
  @override
  List<String> get searchSuggestions => const ['tidur nyenyak', 'sebelum ujian', 'overthinking'];

  @override
  String get download => 'Tersedia offline';
  @override
  String get alreadyOffline => 'Audio sesi ini sudah ada di perangkatmu, bisa diputar tanpa internet.';
  @override
  String fighting(String monsterName) => 'MELAWAN ${monsterName.toUpperCase()}';
  @override
  String get duration => 'Durasi';
  @override
  String minutes(int minutes) => '$minutes mnt';
  @override
  String get ambientTitle => 'Suara latar alam';
  @override
  String get ambientNote => 'Tanpa narasi, ikuti irama napasmu · rekaman CC0';
  @override
  String get whenDone => 'saat selesai';
  @override
  String tame(String monsterName) => 'jinakkan $monsterName';
  @override
  String get startSession => 'Mulai sesi';
  @override
  String freeTierNote(int freeCount) => 'Sementara itu, kamu masih punya $freeCount sesi gratis lain yang bisa dicoba dulu.';

  @override
  String get preparingTitle => 'Menyiapkan sesimu…';
  @override
  String get preparingBody => 'Menyiapkan audio. Sesi ini bisa diputar tanpa internet.';
  @override
  String get running => 'Sesi berjalan';
  @override
  String get followRhythm => 'Ikuti iramanya. Pikiranmu boleh melambat sekarang.';
  @override
  String get seekBack => '-15 dtk';
  @override
  String get seekForward => '+15 dtk';
  @override
  String get breathIn => 'Tarik napas…';
  @override
  String breathHold(int seconds) => 'Tahan… $seconds detik';
  @override
  String get breathOut => 'Hembuskan…';

  @override
  String doneTitle(int minutes) => '$minutes menit buat dirimu sendiri 💙';
  @override
  String get doneBody => 'Nggak semua orang berani berhenti sejenak. Kamu barusan melakukannya.';
  @override
  String get coins => 'koin';
  @override
  String get totalSessions => 'total sesi';
  @override
  String get repeatSession => 'Ulangi sesi ini';
}

class MeditasiStringsEn extends MeditasiStrings {
  const MeditasiStringsEn();

  @override
  MeditationText session(String id) {
    switch (id) {
      case 'jeda_kerja':
        return const MeditationText(
          title: 'A Pause in the Middle of Work',
          description: '5 minutes to release tension between meetings, no special room needed.',
        );
      case 'napas_4_7_8':
        return const MeditationText(
          title: '4-7-8 Breathing to Ease Anxiety',
          description:
              'A simple breathing technique that calms your nervous system. Great when your chest feels '
              'tight before an exam or a presentation.',
        );
      case 'tenang_ujian':
        return const MeditationText(
          title: 'Calm Before an Exam',
          description: 'A short exercise to settle your heartbeat before facing an exam or a presentation.',
        );
      case 'body_scan':
        return const MeditationText(
          title: 'Body Scan: Release Tension in Your Shoulders',
          description: 'Slowly move through your body to let go of the tension built up in your shoulders & neck.',
        );
      case 'menonton_pikiran':
        return const MeditationText(
          title: 'Watching Thoughts Pass By',
          description: 'A mindfulness exercise in letting thoughts come & go without fighting them.',
        );
      case 'berhenti_membandingkan':
        return const MeditationText(
          title: 'Stop Comparing Yourself',
          description: 'Ease the urge to compare yourself by practicing appreciation for your own steps.',
        );
    }
    return const MeditationText(title: '', description: '');
  }

  @override
  String filterLabel(MeditationFilter filter) {
    switch (filter) {
      case MeditationFilter.semua:
        return 'All';
      case MeditationFilter.cemas:
        return 'Anxiety';
      case MeditationFilter.stresKerja:
        return 'Work stress';
      case MeditationFilter.fokusBelajar:
        return 'Study focus';
      case MeditationFilter.pemula:
        return 'Beginner';
    }
  }

  @override
  String get title => 'Meditation';
  @override
  String get subtitle => 'Pick the session that fits you today';
  @override
  String get featuredKicker => 'FOR YOUR WORK HOURS';
  @override
  String get play => 'Play';
  @override
  String durationCoins(int minutes, int coins) => '$minutes min · +$coins coins';
  @override
  String get sectionAnxiety => 'Ease anxiety';
  @override
  String get sectionStudents => 'For students';
  @override
  String emptyCategory(String category) => 'No sessions yet in the "$category" category.';
  @override
  String durationAmbient(int minutes) => '$minutes min · ambient sound';

  @override
  String get searchHint => 'Search meditation sessions';
  @override
  String get searchEmptyTitle => "Couldn't find that one";
  @override
  String searchEmptyBody(String query) => 'No results for "$query". Try a more general word, or peek at what people often search for:';
  @override
  List<String> get searchSuggestions => const ['sleep well', 'before an exam', 'overthinking'];

  @override
  String get download => 'Available offline';
  @override
  String get alreadyOffline => "This session's audio is already on your device and plays without internet.";
  @override
  String fighting(String monsterName) => 'FIGHTING ${monsterName.toUpperCase()}';
  @override
  String get duration => 'Duration';
  @override
  String minutes(int minutes) => '$minutes min';
  @override
  String get ambientTitle => 'Natural ambient sound';
  @override
  String get ambientNote => 'No narration, follow your breathing rhythm · CC0 recording';
  @override
  String get whenDone => 'when finished';
  @override
  String tame(String monsterName) => 'tame $monsterName';
  @override
  String get startSession => 'Start session';
  @override
  String freeTierNote(int freeCount) => 'Meanwhile, you still have $freeCount other free sessions to try first.';

  @override
  String get preparingTitle => 'Preparing your session…';
  @override
  String get preparingBody => 'Preparing audio. This session plays without internet.';
  @override
  String get running => 'Session in progress';
  @override
  String get followRhythm => 'Follow the rhythm. Your mind is allowed to slow down now.';
  @override
  String get seekBack => '-15 s';
  @override
  String get seekForward => '+15 s';
  @override
  String get breathIn => 'Breathe in…';
  @override
  String breathHold(int seconds) => 'Hold… $seconds seconds';
  @override
  String get breathOut => 'Breathe out…';

  @override
  String doneTitle(int minutes) => '$minutes minutes for yourself 💙';
  @override
  String get doneBody => "Not everyone dares to pause for a moment. You just did.";
  @override
  String get coins => 'coins';
  @override
  String get totalSessions => 'total sessions';
  @override
  String get repeatSession => 'Repeat this session';
}
