/// Teks satu pertanyaan asesmen. Urutan [options] HARUS sama dengan urutan
/// opsi di `onboarding_questions.dart` (poin skor dipetakan lewat indeks).
class OnboardingQuestionText {
  const OnboardingQuestionText({
    required this.tag,
    required this.question,
    required this.sub,
    required this.options,
  });

  final String tag;
  final String question;
  final String sub;
  final List<String> options;
}

/// Teks satu layar info. Urutan daftar HARUS sama dengan
/// `onboardingInfoScreens` (aksen/monster dipetakan lewat indeks).
class OnboardingInfoText {
  const OnboardingInfoText({
    required this.kicker,
    this.big,
    required this.title,
    required this.body,
    this.src,
    required this.cta,
  });

  final String kicker;
  final String? big;
  final String title;
  final String body;
  final String? src;
  final String cta;
}

/// Teks fitur Onboarding (kecuali paywall — itu di `TokoStrings`, dipakai
/// bersama paywall Toko).
abstract class OnboardingStrings {
  const OnboardingStrings();

  // ── Welcome ──
  String get welcomeTitle;
  String get welcomeBody;
  String get welcomeStart;
  String get haveAccountPrefix;
  String get signInLink;

  // ── Pertanyaan & info ──
  List<OnboardingQuestionText> get questions;
  List<OnboardingInfoText> get infoScreens;
  String get skip;

  // ── Jawaban bebas & nama ──
  String get freeTextQuestion;
  String get freeTextTag;
  String get freeTextPrivate;
  String get nameTag;
  String get freeTextHint;
  String get freeTextSend;
  String get nameQuestion;
  String get nameHint;

  // ── Menganalisis ──
  String analyzingTitle(String name);
  String get analyzingRead;
  String get analyzingMatch;
  String get analyzingPlan;

  // ── Hasil ──
  String get resultLabel;
  String resultIntro(String name);
  String get defaultName;
  String get bossBadge;
  String get bossTagline;
  String get minionsHeading;
  String get didYouKnow;
  String get didYouKnowSource;
  String get disclaimerText;
  String get disclaimerLink;
  String get startTaming;
  String get saving;

  // ── Rate us ──
  String get rateKicker;
  String rateAsk(String name);
  String get rateBody;
  String get rateYes;
  String get ratePlayTitle;
  String get ratePlaySub;
  String get rateSampleReview;
  String get ratePublicNote;
  String get rateLater;
  String get rateSend;
  String rateThanks(String name);
  String get rateThanksBody;
  String get rateBack;
}

class OnboardingStringsId extends OnboardingStrings {
  const OnboardingStringsId();

  @override
  String get welcomeTitle => 'Ada monster di kepalamu.\nYuk, kenalan.';
  @override
  String get welcomeBody =>
      'Pikiran negatif itu bukan musuh. Dia cuma monster kecil yang belum jinak. Riung menemanimu mengenali, menghadapi, dan menjinakkannya.';
  @override
  String get welcomeStart => 'Mulai kenalan (2 menit)';
  @override
  String get haveAccountPrefix => 'Sudah punya akun? ';
  @override
  String get signInLink => 'Masuk';

  @override
  List<OnboardingQuestionText> get questions => const [
        OnboardingQuestionText(
          tag: 'Tahap hidup',
          question: 'Sekarang kegiatan utamamu apa?',
          sub: 'Biar Riung bisa menyesuaikan bahasanya',
          options: ['Masih sekolah', 'Kuliah', 'Kerja', 'Di antara keduanya / lainnya'],
        ),
        OnboardingQuestionText(
          tag: 'Usia',
          question: 'Berapa usiamu?',
          sub: 'Pilih satu',
          options: ['15-17 tahun', '18-24 tahun', '25-32 tahun', '33-40 tahun'],
        ),
        OnboardingQuestionText(
          tag: 'Isi kepala',
          question: 'Kalau lagi banyak pikiran, apa yang paling sering muncul di kepalamu?',
          sub: 'Pilih semua yang terasa relevan',
          options: [
            'Takut hasilnya nggak sesuai harapan',
            'Hidup orang lain kelihatan lebih oke',
            'Bingung mau mulai dari mana',
            'Nyalahin diri sendiri terus-terusan',
            'Merasa keadaan nggak pernah berpihak padaku',
            'Susah tidur karena kepikiran',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Kecemasan',
          question: 'Seminggu terakhir, seberapa sering kamu merasa cemas atau tegang?',
          sub: 'Pilih satu',
          options: ['Hampir nggak pernah', 'Kadang-kadang', 'Sering', 'Hampir setiap hari'],
        ),
        OnboardingQuestionText(
          tag: 'Prokrastinasi',
          question: 'Saat ada tugas penting yang harus dimulai, biasanya kamu…',
          sub: 'Pilih satu',
          options: [
            'Langsung mengerjakan',
            'Buka HP dulu "sebentar"',
            'Bingung dan akhirnya nggak mulai-mulai',
            'Panik dan lembur di menit terakhir',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Media sosial',
          question: 'Setelah scroll medsos lama, biasanya kamu merasa…',
          sub: 'Pilih satu',
          options: [
            'Terhibur, biasa saja',
            'Kosong, waktunya kebuang',
            'Minder lihat hidup orang lain',
            'Kesel sama diri sendiri',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Pemicu stres',
          question: 'Situasi mana yang paling sering bikin kamu stres?',
          sub: 'Pilih semua yang relevan, geser untuk lihat semua',
          options: [
            'Tugas / ujian menumpuk',
            'Beban kerja & lembur',
            'Perjalanan pergi-pulang yang panjang',
            'Omongan / ekspektasi orang tua',
            'Lingkungan pertemanan',
            'Kondisi keuangan',
            'Hubungan / percintaan',
            'Masa depan yang belum jelas',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Tidur',
          question: 'Gimana kualitas tidurmu belakangan ini?',
          sub: 'Pilih satu',
          options: [
            'Nyenyak, bangun segar',
            'Lumayan, kadang kebangun',
            'Susah mulai tidur karena overthinking',
            'Sering begadang, bangun capek',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Kritik batin',
          question: 'Saat hasil kerja atau nilaimu keluar, suara di kepalamu biasanya bilang…',
          sub: 'Pilih satu',
          options: [
            '"Lumayan, aku sudah berusaha"',
            '"Harusnya bisa lebih baik"',
            '"Aku memang nggak becus"',
            '"Yang penting selesai"',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Takut gagal',
          question: 'Seberapa sering kamu menunda sesuatu karena takut hasilnya jelek?',
          sub: 'Pilih satu',
          options: ['Jarang', 'Kadang-kadang', 'Sering banget', 'Sampai ada yang nggak pernah kumulai'],
        ),
        OnboardingQuestionText(
          tag: 'Coping',
          question: 'Selama ini, apa yang kamu lakukan saat pikiran lagi berat?',
          sub: 'Pilih semua yang relevan, geser untuk lihat semua',
          options: [
            'Scroll medsos sampai lupa waktu',
            'Main game / nonton maraton',
            'Makan / jajan',
            'Dipendam sendiri',
            'Cerita ke teman',
            'Olahraga',
            'Nulis jurnal',
            'Meditasi / latihan napas',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Perbandingan',
          question: 'Kalau lihat teman seumuranmu lebih "maju", kamu merasa…',
          sub: 'Pilih satu',
          options: ['Terpacu, ikut semangat', 'Biasa saja', 'Tertinggal jauh', 'Mempertanyakan hidupku sendiri'],
        ),
        OnboardingQuestionText(
          tag: 'Rencana gagal',
          question: 'Kalau rencana penting tiba-tiba gagal, pikiran pertamamu biasanya…',
          sub: 'Pilih satu',
          options: [
            '"Kenapa selalu aku sih"',
            '"Pasti ada yang salah sama caraku"',
            '"Ya sudah, cari jalan lain"',
            '"Mending nggak usah coba lagi"',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Menghakimi diri',
          question: 'Seberapa keras kamu menghakimi dirimu sendiri?',
          sub: 'Jujur aja, nggak ada jawaban yang salah',
          options: [
            'Aku cukup berdamai dengan diriku',
            'Kadang keras, kadang longgar',
            'Keras, standarku tinggi banget',
            'Sangat keras, nggak pernah puas',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Tujuan',
          question: 'Apa yang paling ingin kamu capai bersama Riung?',
          sub: 'Pilih semua yang relevan',
          options: [
            'Lebih tenang, nggak gampang cemas',
            'Tidur lebih nyenyak',
            'Fokus, berhenti menunda',
            'Lebih sayang sama diri sendiri',
            'Bangun kebiasaan yang konsisten',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Komitmen',
          question: 'Berapa menit per hari yang realistis buat latihanmu?',
          sub: 'Sedikit tapi rutin lebih ampuh daripada banyak tapi sekali',
          options: ['5 menit', '10 menit', '15 menit', '20+ menit'],
        ),
        OnboardingQuestionText(
          tag: 'Waktu latihan',
          question: 'Kapan waktu paling pas buat check-in harianmu?',
          sub: 'Pilih satu',
          options: [
            'Pagi, sebelum mulai aktivitas',
            'Siang, saat istirahat',
            'Sore, setelah aktivitas',
            'Malam, sebelum tidur',
          ],
        ),
      ];

  @override
  List<OnboardingInfoText> get infoScreens => const [
        OnboardingInfoText(
          kicker: 'Kamu nggak sendirian',
          big: '1 dari 3',
          title: 'remaja Indonesia punya setidaknya satu masalah kesehatan mental',
          body:
              'Itu sekitar 15,5 juta orang: teman sekelasmu, rekan kerjamu, mungkin orang di sebelahmu di KRL. Ini bukan kelemahan. Ini hal yang sangat umum.',
          src: 'I-NAMHS 2022',
          cta: 'Lanjut',
        ),
        OnboardingInfoText(
          kicker: 'Yang paling umum',
          big: '28,2%',
          title: 'remaja perempuan dan 25,4% laki-laki mengalami kecemasan',
          body:
              'Kecemasan adalah masalah kesehatan mental paling umum di Indonesia. Rasa waswas yang kamu ceritakan tadi? Sangat, sangat normal.',
          src: 'I-NAMHS 2022',
          cta: 'Lanjut',
        ),
        OnboardingInfoText(
          kicker: 'Tapi ada yang timpang',
          big: '1 dari 10',
          title: 'anak muda dengan depresi yang mencari bantuan',
          body:
              'Prevalensi depresi paling tinggi justru di usia 15-24 tahun, tapi hampir semuanya diam. Dengan berada di sini, kamu sudah melakukan hal yang jarang orang berani lakukan.',
          src: 'SKI 2023, Kemenkes',
          cta: 'Lanjut',
        ),
        OnboardingInfoText(
          kicker: 'Ada kabar baiknya',
          big: '20-30%',
          title: 'risiko cemas & depresi naik karena scroll berlebihan, artinya itu bisa diturunkan',
          body:
              'Layar berlebihan juga mengganggu tidur yang meregulasi mood. Kabar baiknya: pola ini bisa diubah, dan pekerja muda di bawah 40 dengan risiko 2,5× lebih tinggi paling merasakan efeknya.',
          src: 'Studi nasional 2025',
          cta: 'Aku siap',
        ),
        OnboardingInfoText(
          kicker: 'Dari jawabanmu',
          title: 'Bukan kamu yang "rusak", ada pola yang berulang',
          body:
              'Overthinking sebelum tidur, menunda karena takut jelek, membandingkan diri… Itu bukan kepribadianmu. Itu pola pikir yang bisa dikenali dan diubah.',
          cta: 'Lanjut',
        ),
        OnboardingInfoText(
          kicker: 'Pola itu punya nama',
          title: 'Kenalkan: monster-monster batinmu',
          body:
              'Psikologi CBT menyebutnya distorsi kognitif. Di Riung, mereka jadi tujuh monster yang bisa kamu lihat, hadapi, dan jinakkan satu per satu.',
          cta: 'Lanjut',
        ),
        OnboardingInfoText(
          kicker: 'Dan bos di balik semuanya',
          title: 'Si Hakim, kritik batin yang membangunkan monster lainnya',
          body:
              'Dialah suara "kamu nggak becus" itu. Dari vonisnya lahir cemas, minder, dan menunda. Dialah bos yang akan kita jinakkan pelan-pelan.',
          cta: 'Lihat dampaknya',
        ),
        OnboardingInfoText(
          kicker: 'Kalau dibiarkan',
          title: 'Pola ini saling menguatkan',
          body:
              'Cemas → susah tidur → capek → makin gampang menunda → makin keras menghakimi diri → makin cemas. Lingkarannya nyata, tapi bisa diputus dari titik mana pun. 10 menit sehari cukup untuk mulai.',
          cta: 'Putus lingkarannya',
        ),
        OnboardingInfoText(
          kicker: 'Metode yang terbukti',
          title: 'Berbasis CBT, metode paling efektif di aplikasi',
          body:
              'Komponen aktifnya: menata ulang pikiran (cognitive restructuring), aktivasi perilaku, dan penetapan tujuan. Latihan pernapasan rutin juga terbukti mempercepat turunnya kecemasan.',
          src: 'Riset CBT',
          cta: 'Lanjut',
        ),
        OnboardingInfoText(
          kicker: 'Rutinitas kecil harian',
          title: 'Check-in pagi, meditasi, jurnal, afirmasi & tidur',
          body:
              'Sesuai pilihanmu: 10 menit tiap pagi. Ada juga Mode Fokus untuk mengistirahatkan pikiranmu dari scroll, lengkap dengan sesi "Jeda di Tengah Kerja".',
          cta: 'Lanjut',
        ),
        OnboardingInfoText(
          kicker: 'Dan serunya',
          title: 'Tiap latihan menjinakkan monstermu',
          body:
              'Kumpulkan koin, jaga streak, dan saksikan monster liar berubah jinak satu per satu di Vault, sampai akhirnya Si Hakim pun takluk.',
          cta: 'Lihat hasilku',
        ),
      ];

  @override
  String get skip => 'Lewati';

  @override
  String get freeTextTag => 'Ceritamu';
  @override
  String get freeTextPrivate => 'Hanya di perangkatmu';
  @override
  String get nameTag => 'Satu lagi';
  @override
  String get freeTextQuestion => 'Ceritakan dengan katamu sendiri, apa yang paling ingin kamu ubah?';
  @override
  String get freeTextHint => 'Tulis di sini… bebas, tidak dinilai siapa pun.';
  @override
  String get freeTextSend => 'Kirim';
  @override
  String get nameQuestion => 'Satu lagi, kami harus manggil kamu siapa?';
  @override
  String get nameHint => 'Nama panggilanmu';

  @override
  String analyzingTitle(String name) => 'Menyusun profil monstermu${name.isEmpty ? '' : ', $name'}…';
  @override
  String get analyzingRead => 'Membaca pola jawabanmu';
  @override
  String get analyzingMatch => 'Mencocokkan dengan 7 pola sabotase';
  @override
  String get analyzingPlan => 'Menyiapkan rencana latihanmu…';

  @override
  String get resultLabel => 'PROFIL MONSTERMU';
  @override
  String resultIntro(String name) => '$name, kenalkan bos para monstermu:';
  @override
  String get defaultName => 'Kamu';
  @override
  String get bossBadge => 'SANG BOS';
  @override
  String get bossTagline => 'Kritik batinmu, dialah yang membangunkan monster lainnya';
  @override
  String get minionsHeading => 'Anak buahnya, dari yang paling aktif';
  @override
  String get didYouKnow =>
      'Hanya sekitar 1 dari 10 anak muda dengan depresi yang mencari bantuan. Kamu sudah selangkah lebih maju hari ini.';
  @override
  String get didYouKnowSource => 'SKI 2023, Kemenkes';
  @override
  String get disclaimerText =>
      'Hasil ini bukan diagnosis. Aplikasi ini bukan alat diagnosis atau pengganti bantuan profesional. ';
  @override
  String get disclaimerLink => 'Cari bantuan profesional';
  @override
  String get startTaming => 'Mulai jinakkan Si Hakim';
  @override
  String get saving => 'Menyimpan…';

  @override
  String get rateKicker => 'SI KABUT BARU SAJA JINAK';
  @override
  String rateAsk(String name) => 'Boleh minta bantuan kecil, $name?';
  @override
  String get rateBody =>
      'Kalau Riung membantumu sampai sini, ulasanmu di Play Store membantu orang lain yang senasib menemukannya.';
  @override
  String get rateYes => 'Boleh, lanjutkan';
  @override
  String get ratePlayTitle => 'Nikmati Riung?';
  @override
  String get ratePlaySub => 'Ketuk bintang di Google Play';
  @override
  String get rateSampleReview =>
      'Monster pertamaku jinak minggu ini. Latihannya nggak terasa kayak "terapi", malah ditungguin tiap pagi.';
  @override
  String get ratePublicNote => 'Ulasan dapat dilihat publik beserta nama dan foto profil Google Play kamu.';
  @override
  String get rateLater => 'Nanti';
  @override
  String get rateSend => 'Kirim';
  @override
  String rateThanks(String name) => 'Makasih, $name 💜';
  @override
  String get rateThanksBody => 'Ulasanmu membantu lebih banyak orang menemukan jalan pulang ke pikirannya sendiri.';
  @override
  String get rateBack => 'Kembali ke petualanganmu';
}

class OnboardingStringsEn extends OnboardingStrings {
  const OnboardingStringsEn();

  @override
  String get welcomeTitle => "There's a monster in your head.\nLet's meet.";
  @override
  String get welcomeBody =>
      "Negative thoughts are not the enemy. They're just small monsters that haven't been tamed yet. Riung helps you recognize, face, and tame them.";
  @override
  String get welcomeStart => 'Start getting to know them (2 min)';
  @override
  String get haveAccountPrefix => 'Already have an account? ';
  @override
  String get signInLink => 'Sign in';

  @override
  List<OnboardingQuestionText> get questions => const [
        OnboardingQuestionText(
          tag: 'Life stage',
          question: 'What do you mainly do right now?',
          sub: 'So Riung can adjust its language',
          options: ['Still in school', 'College', 'Work', 'Somewhere in between / other'],
        ),
        OnboardingQuestionText(
          tag: 'Age',
          question: 'How old are you?',
          sub: 'Pick one',
          options: ['15-17 years', '18-24 years', '25-32 years', '33-40 years'],
        ),
        OnboardingQuestionText(
          tag: 'On your mind',
          question: 'When your mind is crowded, what shows up most in your head?',
          sub: 'Pick all that feel relevant',
          options: [
            "Afraid the results won't meet expectations",
            "Other people's lives look better",
            "Confused about where to start",
            'Blaming myself nonstop',
            'Feeling like circumstances never side with me',
            "Can't sleep because I keep thinking",
          ],
        ),
        OnboardingQuestionText(
          tag: 'Anxiety',
          question: 'Over the past week, how often did you feel anxious or tense?',
          sub: 'Pick one',
          options: ['Almost never', 'Sometimes', 'Often', 'Almost every day'],
        ),
        OnboardingQuestionText(
          tag: 'Procrastination',
          question: 'When there is an important task to start, you usually…',
          sub: 'Pick one',
          options: [
            'Get right to it',
            'Open my phone "just for a bit"',
            'Get confused and never start',
            'Panic and pull an all-nighter at the last minute',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Social media',
          question: 'After scrolling social media for a long time, you usually feel…',
          sub: 'Pick one',
          options: [
            'Entertained, just fine',
            'Empty, time wasted',
            "Insecure seeing other people's lives",
            'Annoyed at myself',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Stress triggers',
          question: 'Which situations stress you out the most?',
          sub: 'Pick all that apply, scroll to see them all',
          options: [
            'Piled-up assignments / exams',
            'Workload & overtime',
            'Long commutes',
            "Parents' comments / expectations",
            'Friend circles',
            'Financial situation',
            'Relationships / romance',
            'An unclear future',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Sleep',
          question: 'How has your sleep quality been lately?',
          sub: 'Pick one',
          options: [
            'Deep sleep, wake up fresh',
            'Okay, sometimes I wake up',
            'Hard to fall asleep because of overthinking',
            'Often stay up late, wake up tired',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Inner critic',
          question: 'When your work results or grades come out, the voice in your head usually says…',
          sub: 'Pick one',
          options: [
            '"Not bad, I did try"',
            '"Should have been better"',
            '"I\'m just no good"',
            '"As long as it\'s done"',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Fear of failing',
          question: "How often do you put things off because you're afraid the result will be bad?",
          sub: 'Pick one',
          options: ['Rarely', 'Sometimes', 'Very often', "Some things I've never even started"],
        ),
        OnboardingQuestionText(
          tag: 'Coping',
          question: 'So far, what do you do when your mind feels heavy?',
          sub: 'Pick all that apply, scroll to see them all',
          options: [
            'Scroll social media until I lose track of time',
            'Play games / binge-watch',
            'Eat / snack',
            'Keep it to myself',
            'Talk to friends',
            'Exercise',
            'Write in a journal',
            'Meditate / breathing exercises',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Comparison',
          question: 'When you see friends your age who are more "advanced", you feel…',
          sub: 'Pick one',
          options: ['Motivated, energized', 'Nothing much', 'Far behind', 'Questioning my own life'],
        ),
        OnboardingQuestionText(
          tag: 'Failed plans',
          question: 'When an important plan suddenly falls through, your first thought is usually…',
          sub: 'Pick one',
          options: [
            '"Why is it always me"',
            '"Something must be wrong with my approach"',
            '"Oh well, find another way"',
            '"Better not to try again"',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Self-judgment',
          question: 'How harshly do you judge yourself?',
          sub: 'Be honest, there are no wrong answers',
          options: [
            "I'm fairly at peace with myself",
            'Sometimes harsh, sometimes lenient',
            'Harsh, my standards are really high',
            'Very harsh, never satisfied',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Goal',
          question: 'What do you most want to achieve with Riung?',
          sub: 'Pick all that apply',
          options: [
            'Feel calmer, less easily anxious',
            'Sleep more soundly',
            'Focus and stop procrastinating',
            'Be kinder to myself',
            'Build consistent habits',
          ],
        ),
        OnboardingQuestionText(
          tag: 'Commitment',
          question: 'How many minutes a day is realistic for your practice?',
          sub: 'A little but regular beats a lot but once',
          options: ['5 minutes', '10 minutes', '15 minutes', '20+ minutes'],
        ),
        OnboardingQuestionText(
          tag: 'Practice time',
          question: 'When is the best time for your daily check-in?',
          sub: 'Pick one',
          options: [
            'Morning, before the day starts',
            'Noon, during a break',
            'Afternoon, after activities',
            'Night, before sleep',
          ],
        ),
      ];

  @override
  List<OnboardingInfoText> get infoScreens => const [
        OnboardingInfoText(
          kicker: 'You are not alone',
          big: '1 in 3',
          title: 'Indonesian teens have at least one mental health problem',
          body:
              'That is about 15.5 million people: your classmates, your coworkers, maybe the person next to you on the train. This is not a weakness. It is very common.',
          src: 'I-NAMHS 2022',
          cta: 'Continue',
        ),
        OnboardingInfoText(
          kicker: 'The most common',
          big: '28.2%',
          title: 'of girls and 25.4% of boys experience anxiety',
          body:
              'Anxiety is the most common mental health problem in Indonesia. That worry you described earlier? Very, very normal.',
          src: 'I-NAMHS 2022',
          cta: 'Continue',
        ),
        OnboardingInfoText(
          kicker: 'But there is a gap',
          big: '1 in 10',
          title: 'young people with depression who seek help',
          body:
              'Depression prevalence is highest at ages 15-24, yet almost everyone stays silent. By being here, you are doing something few people dare to do.',
          src: 'SKI 2023, Ministry of Health',
          cta: 'Continue',
        ),
        OnboardingInfoText(
          kicker: 'There is good news',
          big: '20-30%',
          title: 'higher risk of anxiety & depression from excessive scrolling, meaning it can be lowered',
          body:
              'Too much screen time also disrupts the sleep that regulates mood. The good news: this pattern can be changed, and young workers under 40 with a 2.5× higher risk feel the effects most.',
          src: 'National study 2025',
          cta: "I'm ready",
        ),
        OnboardingInfoText(
          kicker: 'From your answers',
          title: 'You are not "broken", there is a pattern that repeats',
          body:
              "Overthinking before sleep, putting things off out of fear of doing badly, comparing yourself… That is not your personality. It is a way of thinking that can be recognized and changed.",
          cta: 'Continue',
        ),
        OnboardingInfoText(
          kicker: 'Patterns have names',
          title: 'Meet your inner monsters',
          body:
              'CBT psychology calls them cognitive distortions. In Riung, they become seven monsters you can see, face, and tame one by one.',
          cta: 'Continue',
        ),
        OnboardingInfoText(
          kicker: 'And the boss behind it all',
          title: 'Si Hakim, the inner critic who wakes the other monsters',
          body:
              'He is that "you are no good" voice. From his verdicts are born anxiety, insecurity, and procrastination. He is the boss we will tame slowly.',
          cta: 'See the impact',
        ),
        OnboardingInfoText(
          kicker: 'If left alone',
          title: 'These patterns feed each other',
          body:
              "Anxious → can't sleep → tired → easier to procrastinate → judging yourself harder → more anxious. The loop is real, but it can be broken from any point. 10 minutes a day is enough to start.",
          cta: 'Break the loop',
        ),
        OnboardingInfoText(
          kicker: 'A proven method',
          title: 'Based on CBT, the most effective method in apps',
          body:
              'The active components: restructuring your thoughts (cognitive restructuring), behavioral activation, and goal setting. Regular breathing exercises are also proven to speed up the drop in anxiety.',
          src: 'CBT research',
          cta: 'Continue',
        ),
        OnboardingInfoText(
          kicker: 'Small daily routines',
          title: 'Morning check-in, meditation, journal, affirmations & sleep',
          body:
              'As you chose: 10 minutes each morning. There is also Focus Mode to rest your mind from scrolling, complete with the "Break in the Middle of Work" session.',
          cta: 'Continue',
        ),
        OnboardingInfoText(
          kicker: 'And the fun part',
          title: 'Every exercise tames your monsters',
          body:
              'Collect coins, keep your streak, and watch wild monsters turn tame one by one in the Vault, until even Si Hakim surrenders.',
          cta: 'See my results',
        ),
      ];

  @override
  String get skip => 'Skip';

  @override
  String get freeTextTag => 'Your story';
  @override
  String get freeTextPrivate => 'Only on your device';
  @override
  String get nameTag => 'One more';
  @override
  String get freeTextQuestion => 'In your own words, what do you most want to change?';
  @override
  String get freeTextHint => 'Write here… free and unjudged by anyone.';
  @override
  String get freeTextSend => 'Send';
  @override
  String get nameQuestion => 'One more thing, what should we call you?';
  @override
  String get nameHint => 'Your nickname';

  @override
  String analyzingTitle(String name) => 'Building your monster profile${name.isEmpty ? '' : ', $name'}…';
  @override
  String get analyzingRead => 'Reading your answer patterns';
  @override
  String get analyzingMatch => 'Matching against 7 sabotage patterns';
  @override
  String get analyzingPlan => 'Preparing your practice plan…';

  @override
  String get resultLabel => 'YOUR MONSTER PROFILE';
  @override
  String resultIntro(String name) => '$name, meet the boss of your monsters:';
  @override
  String get defaultName => 'You';
  @override
  String get bossBadge => 'THE BOSS';
  @override
  String get bossTagline => 'Your inner critic, the one who wakes the other monsters';
  @override
  String get minionsHeading => 'His minions, most active first';
  @override
  String get didYouKnow =>
      'Only about 1 in 10 young people with depression seek help. You are already one step ahead today.';
  @override
  String get didYouKnowSource => 'SKI 2023, Ministry of Health';
  @override
  String get disclaimerText =>
      'This result is not a diagnosis. This app is not a diagnostic tool or a substitute for professional help. ';
  @override
  String get disclaimerLink => 'Seek professional help';
  @override
  String get startTaming => 'Start taming Si Hakim';
  @override
  String get saving => 'Saving…';

  @override
  String get rateKicker => 'SI KABUT HAS JUST BEEN TAMED';
  @override
  String rateAsk(String name) => 'Could we ask a small favor, $name?';
  @override
  String get rateBody =>
      'If Riung has helped you this far, your Play Store review helps others in the same boat find it.';
  @override
  String get rateYes => 'Sure, continue';
  @override
  String get ratePlayTitle => 'Enjoying Riung?';
  @override
  String get ratePlaySub => 'Tap a star on Google Play';
  @override
  String get rateSampleReview =>
      'My first monster got tamed this week. The exercises don\'t feel like "therapy", I actually look forward to them every morning.';
  @override
  String get ratePublicNote => 'Reviews are public, along with your Google Play name and profile photo.';
  @override
  String get rateLater => 'Later';
  @override
  String get rateSend => 'Send';
  @override
  String rateThanks(String name) => 'Thank you, $name 💜';
  @override
  String get rateThanksBody => 'Your review helps more people find their way home to their own minds.';
  @override
  String get rateBack => 'Back to your adventure';
}
