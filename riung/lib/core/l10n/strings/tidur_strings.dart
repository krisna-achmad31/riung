/// Judul, ringkasan, dan deskripsi satu cerita tidur (nama pembaca bukan
/// terjemahan, tetap di katalog).
class SleepStoryText {
  const SleepStoryText({required this.title, required this.blurb, required this.description});

  final String title;

  /// Satu kalimat untuk kartu "cerita malam ini".
  final String blurb;
  final String description;
}

/// Teks fitur Tidur: beranda, detail, pemutar, selesai, laporan, pengingat.
abstract class TidurStrings {
  const TidurStrings();

  SleepStoryText story(String id);
  String soundLabel(String id);

  // ── Beranda ──
  String get title;
  String get subtitle;
  String get featuredKicker;
  String get play;
  String durationReader(int minutes, String reader);
  String get sectionStories;
  String get sectionSounds;
  String get soundsHint;

  // ── Detail ──
  String get download;
  String get alreadyOffline;
  String kicker(int minutes);
  String readBy(String reader);
  String get sourceNote;
  String get timerTitle;
  String minutes(int minutes);
  String get playStory;
  String freeTierNote(int freeCount);

  // ── Pemutar ──
  String get nightMode;
  String playerSub(String reader, int minutes);
  String get autoStop;

  // ── Selesai ──
  String get doneTitle;
  String get doneBody;

  // ── Laporan pagi ──
  String get reportTitle;
  String get reportEmptyTitle;
  String get reportEmptyBody;
  String get tryTonightStory;
  String get setReminder;
  String get noSensorNote;

  // ── Pengingat ──
  String get reminderTitle;
  String get reminderIntro;
  String get targetKicker;
  String adjustMinutes(int delta);
  String remindBefore(int minutes);
  String get activeDays;
  List<String> get dayInitials;
  String daysSummary(Set<int> days, List<String> weekdayShort);
  String get streakNote;
  String get saveReminder;
  String get reminderSaved;
  String get reminderOff;
}

class TidurStringsId extends TidurStrings {
  const TidurStringsId();

  @override
  SleepStoryText story(String id) {
    switch (id) {
      case 'happy_prince':
        return const SleepStoryText(
          title: 'Pangeran Bahagia',
          blurb: 'Kisah lembut dari Oscar Wilde tentang memberi.',
          description:
              'Patung pangeran yang berdiri tinggi di atas kota, dan seekor burung layang-layang kecil yang singgah '
              'untuk semalam. Dongeng pelan tentang memberi, karya Oscar Wilde. Ceritanya panjang dan tenang, '
              'nggak apa-apa kalau kamu tertidur di tengahnya.',
        );
      case 'selfish_giant':
        return const SleepStoryText(
          title: 'Raksasa yang Egois',
          blurb: 'Taman yang selalu musim dingin, sampai musim semi menyelinap masuk.',
          description:
              'Sebuah taman indah yang selalu musim dingin karena pemiliknya menutup pintu bagi anak-anak, sampai '
              'suatu pagi musim semi menyelinap masuk. Pendek dan hangat, pas untuk malam yang melelahkan.',
        );
      case 'nightingale_rose':
        return const SleepStoryText(
          title: 'Burung Bulbul dan Mawar',
          blurb: 'Dongeng puitis tentang mawar merah dan hati yang patah.',
          description:
              'Seekor burung bulbul mendengar seorang pelajar yang patah hati dan mencari satu tangkai mawar '
              'merah. Dongeng puitis Oscar Wilde, dibacakan dengan tempo yang tenang.',
        );
      case 'velveteen_rabbit':
        return const SleepStoryText(
          title: 'Kelinci Beludru',
          blurb: 'Kelinci mainan yang ingin menjadi nyata.',
          description:
              'Kelinci mainan yang ingin menjadi nyata, dan arti sebenarnya dari dicintai. Dibacakan dua suara yang '
              'hangat, klasik untuk menutup hari.',
        );
    }
    return const SleepStoryText(title: '', blurb: '', description: '');
  }

  @override
  String soundLabel(String id) {
    switch (id) {
      case 'hujan':
        return 'Hujan';
      case 'ombak':
        return 'Ombak';
      case 'kipas':
        return 'Kipas angin';
    }
    return id;
  }

  @override
  String get title => 'Tidur';
  @override
  String get subtitle => 'Antar pikiranmu pelan-pelan ke jam istirahat';
  @override
  String get featuredKicker => 'CERITA MALAM INI';
  @override
  String get play => 'Putar';
  @override
  String durationReader(int minutes, String reader) => '$minutes mnt · $reader';
  @override
  String get sectionStories => 'Cerita tidur';
  @override
  String get sectionSounds => 'Suasana suara';
  @override
  String get soundsHint => 'Ketuk untuk memutar, ketuk lagi untuk berhenti.';

  @override
  String get download => 'Tersedia offline';
  @override
  String get alreadyOffline => 'Audio cerita ini sudah ada di perangkatmu, bisa diputar tanpa internet.';
  @override
  String kicker(int minutes) => 'CERITA TIDUR · $minutes MENIT';
  @override
  String readBy(String reader) => 'Dibacakan $reader';
  @override
  String get sourceNote => 'Audio berbahasa Inggris · rekaman LibriVox, domain publik';
  @override
  String get timerTitle => 'Timer layar mati';
  @override
  String minutes(int minutes) => '$minutes mnt';
  @override
  String get playStory => 'Putar cerita';
  @override
  String freeTierNote(int freeCount) => 'Sementara itu, kamu masih punya $freeCount cerita gratis lain yang bisa dicoba dulu.';

  @override
  String get nightMode => 'Mode malam · layar redup';
  @override
  String playerSub(String reader, int minutes) => '$reader · timer $minutes menit';
  @override
  String get autoStop => 'Audio berhenti sendiri setelah cerita selesai. Selamat tidur 🌙';

  @override
  String get doneTitle => 'Selamat tidur 🌙';
  @override
  String get doneBody => 'Audio sudah berhenti. Semoga istirahatmu nyenyak malam ini.';

  @override
  String get reportTitle => 'Tidur semalam';
  @override
  String get reportEmptyTitle => 'Belum ada catatan tidur';
  @override
  String get reportEmptyBody =>
      'Mulai malam ini: putar satu cerita tidur atau atur pengingat, dan besok pagi kamu bisa lihat pola tidurmu di sini.';
  @override
  String get tryTonightStory => 'Coba cerita malam ini';
  @override
  String get setReminder => 'Atur pengingat tidur';
  @override
  String get noSensorNote => 'Riung nggak melacak tidurmu lewat sensor. Semua catatan berasal dari yang kamu isi sendiri.';

  @override
  String get reminderTitle => 'Pengingat tidur';
  @override
  String get reminderIntro => 'Riung bakal ngingetin kamu pelan-pelan, sekali aja, tanpa nada bersalah kalau kamu lewatkan.';
  @override
  String get targetKicker => 'TARGET MULAI TIDUR';
  @override
  String adjustMinutes(int delta) => '${delta > 0 ? '+' : ''}$delta mnt';
  @override
  String remindBefore(int minutes) => 'Ingatkan $minutes menit sebelumnya';
  @override
  String get activeDays => 'Hari aktif';
  @override
  List<String> get dayInitials => const ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
  @override
  String daysSummary(Set<int> days, List<String> weekdayShort) {
    if (days.isEmpty) return 'Tidak ada hari dipilih';
    if (days.length == 7) return 'Setiap hari';
    if (days.length == 5 && days.containsAll(const {0, 1, 2, 3, 4})) return 'Senin-Jumat';
    return (days.toList()..sort()).map((d) => weekdayShort[d]).join(', ');
  }

  @override
  String get streakNote => 'Streak kamu nggak putus karena telat tidur. Pengingat ini cuma bantuan, bukan penilaian.';
  @override
  String get saveReminder => 'Simpan pengingat';
  @override
  String get reminderSaved => 'Pengingat tidur disimpan.';
  @override
  String get reminderOff => 'Pengingat tidur dimatikan.';
}

class TidurStringsEn extends TidurStrings {
  const TidurStringsEn();

  @override
  SleepStoryText story(String id) {
    switch (id) {
      case 'happy_prince':
        return const SleepStoryText(
          title: 'The Happy Prince',
          blurb: 'A gentle tale by Oscar Wilde about giving.',
          description:
              'A statue of a prince standing high above the city, and a little swallow who stops by for one night. '
              'A slow tale about giving, by Oscar Wilde. The story is long and calm, and it is fine if you fall '
              'asleep in the middle of it.',
        );
      case 'selfish_giant':
        return const SleepStoryText(
          title: 'The Selfish Giant',
          blurb: 'A garden stuck in winter, until spring sneaks in.',
          description:
              'A beautiful garden that stays in winter because its owner shut the door on the children, until one '
              'morning spring slips in. Short and warm, just right for a tiring night.',
        );
      case 'nightingale_rose':
        return const SleepStoryText(
          title: 'The Nightingale and the Rose',
          blurb: 'A poetic tale about a red rose and a broken heart.',
          description:
              'A nightingale hears a heartbroken student searching for a single red rose. A poetic tale by Oscar '
              'Wilde, read at a calm pace.',
        );
      case 'velveteen_rabbit':
        return const SleepStoryText(
          title: 'The Velveteen Rabbit',
          blurb: 'A toy rabbit who wants to become real.',
          description:
              'A toy rabbit who wants to become real, and what it truly means to be loved. Read by two warm voices, '
              'a classic for closing the day.',
        );
    }
    return const SleepStoryText(title: '', blurb: '', description: '');
  }

  @override
  String soundLabel(String id) {
    switch (id) {
      case 'hujan':
        return 'Rain';
      case 'ombak':
        return 'Waves';
      case 'kipas':
        return 'Fan';
    }
    return id;
  }

  @override
  String get title => 'Sleep';
  @override
  String get subtitle => 'Gently guide your mind toward rest';
  @override
  String get featuredKicker => "TONIGHT'S STORY";
  @override
  String get play => 'Play';
  @override
  String durationReader(int minutes, String reader) => '$minutes min · $reader';
  @override
  String get sectionStories => 'Sleep stories';
  @override
  String get sectionSounds => 'Soundscapes';
  @override
  String get soundsHint => 'Tap to play, tap again to stop.';

  @override
  String get download => 'Available offline';
  @override
  String get alreadyOffline => "This story's audio is already on your device and plays without internet.";
  @override
  String kicker(int minutes) => 'SLEEP STORY · $minutes MIN';
  @override
  String readBy(String reader) => 'Read by $reader';
  @override
  String get sourceNote => 'LibriVox recording, public domain';
  @override
  String get timerTitle => 'Screen-off timer';
  @override
  String minutes(int minutes) => '$minutes min';
  @override
  String get playStory => 'Play story';
  @override
  String freeTierNote(int freeCount) => 'Meanwhile, you still have $freeCount other free stories to try first.';

  @override
  String get nightMode => 'Night mode · dimmed screen';
  @override
  String playerSub(String reader, int minutes) => '$reader · $minutes-minute timer';
  @override
  String get autoStop => 'The audio stops on its own once the story ends. Good night 🌙';

  @override
  String get doneTitle => 'Good night 🌙';
  @override
  String get doneBody => 'The audio has stopped. May you rest well tonight.';

  @override
  String get reportTitle => 'Last night\'s sleep';
  @override
  String get reportEmptyTitle => 'No sleep notes yet';
  @override
  String get reportEmptyBody =>
      "Starting tonight: play a sleep story or set a reminder, and tomorrow morning you can see your sleep pattern here.";
  @override
  String get tryTonightStory => "Try tonight's story";
  @override
  String get setReminder => 'Set a sleep reminder';
  @override
  String get noSensorNote => "Riung doesn't track your sleep with sensors. Every note comes from what you fill in yourself.";

  @override
  String get reminderTitle => 'Sleep reminder';
  @override
  String get reminderIntro => 'Riung will remind you gently, just once, with no guilt if you miss it.';
  @override
  String get targetKicker => 'BEDTIME TARGET';
  @override
  String adjustMinutes(int delta) => '${delta > 0 ? '+' : ''}$delta min';
  @override
  String remindBefore(int minutes) => 'Remind me $minutes minutes before';
  @override
  String get activeDays => 'Active days';
  @override
  List<String> get dayInitials => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  @override
  String daysSummary(Set<int> days, List<String> weekdayShort) {
    if (days.isEmpty) return 'No days selected';
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && days.containsAll(const {0, 1, 2, 3, 4})) return 'Mon-Fri';
    return (days.toList()..sort()).map((d) => weekdayShort[d]).join(', ');
  }

  @override
  String get streakNote => 'Your streak does not break because you went to bed late. This reminder is only a helper, not a judgment.';
  @override
  String get saveReminder => 'Save reminder';
  @override
  String get reminderSaved => 'Sleep reminder saved.';
  @override
  String get reminderOff => 'Sleep reminder turned off.';
}
