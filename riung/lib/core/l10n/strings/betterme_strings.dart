/// Teks satu sesi Better Me: judul, isi, dan pertanyaan refleksi.
class BetterMeSessionText {
  const BetterMeSessionText({required this.judul, required this.konten, required this.pertanyaanRefleksi});

  final String judul;
  final String konten;
  final String pertanyaanRefleksi;
}

/// Teks satu level Better Me.
class BetterMeLevelText {
  const BetterMeLevelText({required this.judul, required this.deskripsi});

  final String judul;
  final String deskripsi;
}

/// Teks fitur Better Me. Konten (22 sesi, 3 level) ada di sini per bahasa;
/// struktur (id, level, tipe, estimasi menit) tetap di
/// `betterme_content.dart`.
abstract class BettermeStrings {
  const BettermeStrings();

  BetterMeSessionText session(String id);
  BetterMeLevelText level(int number);

  // ── Umum ──
  String get title;
  String typeLabel(String typeName);
  String levelName(int number);
  String sessionCount(int count);
  String sessionsProgress(int done, int total);
  String minutes(int minutes);
  String minutesLong(int minutes);
  String totalMinutes(int minutes);

  // ── Beranda ──
  String get subtitle;
  String totalDone(int done, int total);
  String levelLockedTitle(int number);
  String levelLockedNote(int previous);
  String levelTitleWithName(int number, String name);

  // ── Intro level & sesi ──
  String get startLevel;
  String continueWith(String sessionTitle);
  String get start;

  // ── Konten sesi ──
  String get reflectionHint;
  String get saving;

  // ── Selesai & milestone ──
  String get sessionDone;
  String get coins;
  String get sessionsInLevel;
  String levelDone(int number);
  String get allDone;
  String nextLevelOpen(int next);
}

class BettermeStringsId extends BettermeStrings {
  const BettermeStringsId();

  @override
  BetterMeSessionText session(String id) {
    switch (id) {
      case 'l1_s1':
        return const BetterMeSessionText(
          judul: 'Suara yang paling galak',
          konten:
              'Setiap orang punya suara batin yang mengomentari apa pun yang kamu lakukan. Buat sebagian orang, suara itu galak banget, selalu bilang kamu kurang, kamu gagal, kamu nggak cukup. Riung menyebutnya Si Hakim. Dia bukan fakta tentang dirimu, dia cuma pola pikir yang kebentuk lama, dan pola bisa dilatih ulang.',
          pertanyaanRefleksi: 'Kapan terakhir kali kamu dengar suara itu? Apa yang dia bilang?',
        );
      case 'l1_s2':
        return const BetterMeSessionText(
          judul: 'Beri nama sabotasemu',
          konten:
              'Ngasih nama ke pola pikir negatif bikin dia kerasa lebih kecil, lebih bisa dijinakkan, bukan bagian dari dirimu yang nggak terpisahkan. Itu kenapa di Riung tiap saboteur punya nama sendiri. Sekarang giliranmu: kalau suara Si Hakim di kepalamu punya nada atau gaya bicara khusus, coba kenali polanya.',
          pertanyaanRefleksi: 'Kalau suara itu punya nada bicara, kira-kira kayak apa?',
        );
      case 'l1_s3':
        return const BetterMeSessionText(
          judul: 'Kapan dia paling ribut',
          konten:
              'Si Hakim nggak ngomong terus-terusan, dia punya waktu favorit: sebelum mulai sesuatu yang baru, sesudah bikin kesalahan kecil, atau pas kamu lagi capek. Mengenali polanya bikin kamu bisa siap-siap duluan, bukan kaget tiap kali dia muncul.',
          pertanyaanRefleksi: 'Situasi apa yang paling sering memancing suara itu muncul?',
        );
      case 'l1_s4':
        return const BetterMeSessionText(
          judul: 'Vonis itu bukan fakta',
          konten:
              'Si Hakim suka ngomong pakai kata "selalu" dan "nggak pernah". Kamu selalu telat. Kamu nggak pernah becus. Tapi coba dicek, hampir semua vonis absolut itu punya pengecualian kalau kamu jujur nyari. Satu bukti kecil aja cukup bikin vonisnya goyah.',
          pertanyaanRefleksi: 'Vonis apa yang paling sering kamu dengar, dan satu pengecualian apa yang bisa membantahnya?',
        );
      case 'l1_s5':
        return const BetterMeSessionText(
          judul: 'Bukti kecil yang dia abaikan',
          konten:
              'Otak yang lagi capek cenderung nyari bukti yang cocok sama vonis negatif, dan ngelewatin yang nggak cocok. Ini bukan salahmu, ini cara kerja otak pas stres. Latihannya sederhana: tiap kali Si Hakim ngomong, tulis satu bukti kecil yang dia nggak sebutin.',
          pertanyaanRefleksi: 'Sebutkan satu hal kecil minggu ini yang membuktikan kamu lebih baik dari vonis Si Hakim.',
        );
      case 'l1_s6':
        return const BetterMeSessionText(
          judul: 'Ngomong ke diri sendiri kayak ke teman',
          konten:
              'Kalau temanmu cerita gagal ujian, kamu nggak bakal bilang "makanya bodoh". Tapi ke diri sendiri, kita sering jauh lebih kasar. Coba latihan kecil: tiap kali Si Hakim ngomong sesuatu, bayangkan itu diomongin ke temanmu, terus balas dengan kalimat yang biasa kamu pakai buat menghibur mereka.',
          pertanyaanRefleksi: 'Tulis satu kalimat yang biasa kamu pakai buat menghibur teman, lalu ucapkan ke dirimu sendiri.',
        );
      case 'l1_s7':
        return const BetterMeSessionText(
          judul: 'Napas dulu, baru lanjut',
          konten:
              'Sebelum masuk ke level berikutnya, ambil jeda. Kamu udah ngelewatin enam sesi ngobrol jujur sama suara paling galak di kepalamu, itu nggak kecil. Nggak perlu buru-buru berubah total, cukup sadar dulu bahwa suara itu ada dan bisa dilihat dari luar.',
          pertanyaanRefleksi: 'Apa satu hal yang berubah dari cara kamu lihat Si Hakim sejak sesi pertama?',
        );
      case 'l2_s1':
        return const BetterMeSessionText(
          judul: 'Uji pikiranmu di pengadilan kecil',
          konten:
              'Setiap pikiran yang bikin cemas bisa diuji kayak di persidangan: apa buktinya mendukung, apa buktinya menentang, dan kalau ini kejadian sama temanmu, saran apa yang bakal kamu kasih? Latihan ini bukan buat mengabaikan perasaanmu, tapi buat lihat gambar yang lebih lengkap.',
          pertanyaanRefleksi: 'Ambil satu pikiran cemas hari ini, apa bukti yang menentangnya?',
        );
      case 'l2_s2':
        return const BetterMeSessionText(
          judul: 'Gerak dulu, mood belakangan',
          konten:
              'Kita sering nunggu mood bagus dulu baru mau gerak, padahal sering kali urutannya kebalik: gerak dulu, mood ikut nyusul. Ini yang disebut aktivasi perilaku, satu langkah kecil bisa mecahin lingkaran diam-karena-lesu.',
          pertanyaanRefleksi: 'Satu aktivitas kecil apa yang bisa kamu lakukan sekarang, tanpa nunggu mood siap?',
        );
      case 'l2_s3':
        return const BetterMeSessionText(
          judul: 'Batas itu bukan tembok',
          konten:
              'Bilang "nggak bisa" atau "nanti dulu" ke orang lain sering kerasa kayak dosa, padahal itu cara jaga energimu supaya nggak abis buat semua orang kecuali dirimu sendiri. Batas yang sehat bukan mendorong orang menjauh, tapi bikin hubungan tetap adil buat kamu juga.',
          pertanyaanRefleksi: 'Ada permintaan apa belakangan ini yang sebenarnya pengen kamu tolak?',
        );
      case 'l2_s4':
        return const BetterMeSessionText(
          judul: 'Grounding lima indra',
          konten:
              'Saat pikiran berputar terlalu cepat, cara tercepat balik ke saat ini adalah lewat tubuh, bukan lewat logika. Coba sebutkan lima hal yang kamu lihat, empat yang kamu dengar, tiga yang kamu rasakan lewat sentuhan, dua yang kamu cium, satu yang kamu kecap.',
          pertanyaanRefleksi: 'Coba latihan lima indra sekarang, gimana rasanya sesudahnya?',
        );
      case 'l2_s5':
        return const BetterMeSessionText(
          judul: 'Istirahat bukan kemalasan',
          konten:
              'Si Hakim suka nyamain istirahat sama malas, padahal tubuh dan pikiran yang nggak pernah dikasih jeda bakal makin lambat, bukan makin produktif. Istirahat yang sungguhan (bukan sekadar scroll) itu bagian dari kerja, bukan lawan dari kerja.',
          pertanyaanRefleksi: 'Kapan terakhir kali kamu istirahat tanpa rasa bersalah?',
        );
      case 'l2_s6':
        return const BetterMeSessionText(
          judul: 'Kenali pola pikir sepihak',
          konten:
              'Berpikir "semua-atau-nggak-sama-sekali" bikin satu kesalahan kecil kerasa kayak kegagalan total. Latihannya: tiap kali muncul pikiran ekstrem, coba cari titik tengahnya. Nggak semua hal cuma punya dua pilihan.',
          pertanyaanRefleksi: 'Pikiran ekstrem apa yang muncul minggu ini, dan apa titik tengahnya?',
        );
      case 'l2_s7':
        return const BetterMeSessionText(
          judul: 'Rayakan langkah kecil',
          konten:
              'Kita cenderung cuma ngerayain pencapaian besar, padahal perubahan sungguhan kebentuk dari langkah-langkah kecil yang konsisten. Level ini udah selesai, itu sendiri layak dirayakan, bukan cuma ditunggu sampai "benar-benar berubah".',
          pertanyaanRefleksi: 'Langkah kecil apa dari level ini yang paling pengen kamu akui sebagai pencapaian?',
        );
      case 'l3_s1':
        return const BetterMeSessionText(
          judul: 'Kambuh itu bukan mulai dari nol',
          konten:
              'Suatu hari nanti Si Hakim atau saboteur lain bakal mampir lagi, itu bukan tanda kamu gagal, itu tanda kamu manusia. Bedanya sekarang, kamu udah punya alat buat mengenali dan meresponnya, jadi kamu nggak mulai dari nol lagi.',
          pertanyaanRefleksi: 'Kalau saboteur lamamu muncul lagi minggu depan, alat apa yang bakal kamu pakai duluan?',
        );
      case 'l3_s2':
        return const BetterMeSessionText(
          judul: 'Nilai yang benar-benar penting buatmu',
          konten:
              'Di tengah semua target dan tuntutan, gampang lupa apa yang sebenarnya kamu perjuangkan. Nilai personal itu kompas, bukan checklist, dia nggak pernah selesai dicapai, tapi bisa terus dijalani.',
          pertanyaanRefleksi: 'Sebutkan satu nilai (bukan tujuan) yang paling penting buat hidupmu sekarang.',
        );
      case 'l3_s3':
        return const BetterMeSessionText(
          judul: 'Rencana buat hari yang berat',
          konten:
              'Hari berat pasti datang lagi, itu bukan pertanyaan kalau, tapi kapan. Punya rencana kecil yang udah disiapin dari sekarang (siapa yang dihubungi, latihan apa yang dipakai) bikin hari berat itu terasa lebih bisa dilewati.',
          pertanyaanRefleksi: 'Tulis 3 langkah yang bisa kamu lakukan di hari yang benar-benar berat.',
        );
      case 'l3_s4':
        return const BetterMeSessionText(
          judul: 'Support system-mu siapa aja',
          konten:
              'Nggak ada yang bisa jinakkan semua monsternya sendirian, dan itu bukan kelemahan. Kenali siapa aja orang yang bisa kamu hubungi kalau lagi susah, dan jangan tunggu sampai benar-benar krisis buat mulai membangun hubungan itu.',
          pertanyaanRefleksi: 'Sebutkan satu orang yang bisa kamu hubungi kalau lagi berat, kapan terakhir kali kamu ngobrol sama mereka?',
        );
      case 'l3_s5':
        return const BetterMeSessionText(
          judul: 'Menengok jalan yang sudah dilewati',
          konten:
              'Gampang banget fokus ke seberapa jauh lagi yang harus ditempuh, sampai lupa seberapa jauh udah dilewati. Sebelum lanjut, coba lihat lagi dari sesi pertama sampai sekarang, apa yang berubah, sekecil apa pun itu.',
          pertanyaanRefleksi: 'Apa satu hal yang beda dari dirimu sekarang dibanding waktu mulai Better Me?',
        );
      case 'l3_s6':
        return const BetterMeSessionText(
          judul: 'Kabut boleh mampir, kamu tetap jalan',
          konten:
              'Nggak semua hari harus terasa baik supaya harinya berarti. Kamu bisa tetap jalan, tetap ngerjain hal kecil, sambil rasanya lagi kabur atau berat. Dua hal itu bisa ada bareng, nggak perlu nunggu kabutnya hilang dulu.',
          pertanyaanRefleksi: 'Kapan terakhir kali kamu tetap jalan meski lagi nggak baik-baik saja?',
        );
      case 'l3_s7':
        return const BetterMeSessionText(
          judul: 'Menulis surat buat diri sendiri',
          konten:
              'Tulis surat pendek buat dirimu sendiri di masa depan, kapan pun itu dibaca lagi. Nggak perlu formal, cukup jujur: apa yang pengen kamu ingatkan ke dirimu sendiri kalau lagi ketemu Si Hakim lagi.',
          pertanyaanRefleksi: 'Tulis satu kalimat pembuka surat itu di sini.',
        );
      case 'l3_s8':
        return const BetterMeSessionText(
          judul: 'Selamat, kamu sampai sini',
          konten:
              '22 sesi, tiga level, dan kamu masih di sini. Ini bukan garis akhir, program ini nggak pernah didesain buat "menyembuhkan" dalam satu putaran, tapi jadi latihan yang bisa kamu ulang kapan pun butuh. Monster-monstermu nggak hilang selamanya, tapi kamu sekarang tahu caranya menemani mereka.',
          pertanyaanRefleksi: 'Apa yang pengen kamu bawa dari program ini ke hari-hari biasa setelah ini?',
        );
    }
    return const BetterMeSessionText(judul: '', konten: '', pertanyaanRefleksi: '');
  }

  @override
  BetterMeLevelText level(int number) {
    switch (number) {
      case 1:
        return const BetterMeLevelText(judul: 'Kenalan sama Si Hakim', deskripsi: 'Mulai dari mengenali suara paling galak di kepalamu, sebelum mencoba mengubahnya.');
      case 2:
        return const BetterMeLevelText(judul: 'Melatih ulang kebiasaan', deskripsi: 'Dari sekadar mengenali, sekarang mulai melatih respons baru lewat tindakan kecil.');
      case 3:
        return const BetterMeLevelText(judul: 'Menjaga apa yang sudah tumbuh', deskripsi: 'Perubahan bukan garis lurus. Level ini soal bertahan, bukan lagi soal mulai.');
    }
    return const BetterMeLevelText(judul: '', deskripsi: '');
  }

  @override
  String get title => 'Better Me';
  @override
  String typeLabel(String typeName) {
    switch (typeName) {
      case 'psikoedukasi':
        return 'Psikoedukasi';
      case 'latihan':
        return 'Latihan';
      case 'restrukturisasi':
        return 'Restrukturisasi pikiran';
      case 'aktivasiPerilaku':
        return 'Aktivasi perilaku';
    }
    return typeName;
  }

  @override
  String levelName(int number) => 'Level $number';
  @override
  String sessionCount(int count) => '$count sesi';
  @override
  String sessionsProgress(int done, int total) => '$done/$total sesi';
  @override
  String minutes(int minutes) => '$minutes mnt';
  @override
  String minutesLong(int minutes) => '$minutes menit';
  @override
  String totalMinutes(int minutes) => '~$minutes menit total';

  @override
  String get subtitle => 'Perubahan kecil yang kelihatan kalau dikumpulkan';
  @override
  String totalDone(int done, int total) => '$done/$total sesi selesai';
  @override
  String levelLockedTitle(int number) => 'Level $number masih terkunci';
  @override
  String levelLockedNote(int previous) => 'Selesaikan Level $previous dan aktifkan Riung Premium buat membuka level ini.';
  @override
  String levelTitleWithName(int number, String name) => 'Level $number · $name';

  @override
  String get startLevel => 'Mulai level ini';
  @override
  String continueWith(String sessionTitle) => 'Lanjut · $sessionTitle';
  @override
  String get start => 'Mulai';

  @override
  String get reflectionHint => 'Tulis di sini, nggak ada jawaban salah...';
  @override
  String get saving => 'Menyimpan...';

  @override
  String get sessionDone => 'Sesi selesai';
  @override
  String get coins => 'koin';
  @override
  String get sessionsInLevel => 'sesi di level ini';
  @override
  String levelDone(int number) => 'LEVEL $number SELESAI';
  @override
  String get allDone => 'Kamu menyelesaikan semua 22 sesi Better Me. Ini bukan garis akhir, tapi latihan yang bisa kamu ulang kapan pun butuh.';
  @override
  String nextLevelOpen(int next) => 'Level $next sudah terbuka. Nggak perlu buru-buru lanjut, jeda dulu kalau butuh.';
}

class BettermeStringsEn extends BettermeStrings {
  const BettermeStringsEn();

  @override
  BetterMeSessionText session(String id) {
    switch (id) {
      case 'l1_s1':
        return const BetterMeSessionText(
          judul: 'The harshest voice',
          konten:
              'Everyone has an inner voice that comments on whatever you do. For some people, that voice is really harsh, always saying you fall short, you failed, you are not enough. Riung calls it Si Hakim. It is not a fact about you, just a thinking pattern formed long ago, and patterns can be retrained.',
          pertanyaanRefleksi: 'When did you last hear that voice? What did it say?',
        );
      case 'l1_s2':
        return const BetterMeSessionText(
          judul: 'Name your saboteur',
          konten:
              'Giving a name to a negative thought pattern makes it feel smaller and easier to tame, not an inseparable part of you. That is why every saboteur in Riung has its own name. Now it is your turn: if the voice of Si Hakim in your head has a particular tone or way of speaking, try to recognize its pattern.',
          pertanyaanRefleksi: 'If that voice had a tone of speaking, what would it sound like?',
        );
      case 'l1_s3':
        return const BetterMeSessionText(
          judul: 'When it gets the loudest',
          konten:
              'Si Hakim does not talk all the time, it has favorite moments: before starting something new, after a small mistake, or when you are tired. Recognizing the pattern lets you get ready ahead of time, instead of being caught off guard every time it shows up.',
          pertanyaanRefleksi: 'What situation most often makes that voice show up?',
        );
      case 'l1_s4':
        return const BetterMeSessionText(
          judul: 'A verdict is not a fact',
          konten:
              'Si Hakim likes to speak with the words "always" and "never". You are always late. You never get anything right. But if you check honestly, almost every absolute verdict has an exception. Just one small piece of evidence is enough to make the verdict wobble.',
          pertanyaanRefleksi: 'Which verdict do you hear most often, and what one exception could disprove it?',
        );
      case 'l1_s5':
        return const BetterMeSessionText(
          judul: 'The small evidence it ignores',
          konten:
              'A tired brain tends to look for evidence that matches a negative verdict, and skip the evidence that does not. It is not your fault, it is how the brain works under stress. The exercise is simple: every time Si Hakim speaks, write down one small piece of evidence it did not mention.',
          pertanyaanRefleksi: 'Name one small thing this week that proves you are better than Si Hakim\'s verdict.',
        );
      case 'l1_s6':
        return const BetterMeSessionText(
          judul: 'Talking to yourself like a friend',
          konten:
              'If a friend told you they failed an exam, you would not say "that is what you get for being dumb". But to ourselves, we are often far harsher. Try a small exercise: every time Si Hakim says something, imagine it being said to your friend, then reply with the words you would normally use to comfort them.',
          pertanyaanRefleksi: 'Write one sentence you would normally use to comfort a friend, then say it to yourself.',
        );
      case 'l1_s7':
        return const BetterMeSessionText(
          judul: 'Breathe first, then continue',
          konten:
              'Before moving on to the next level, take a pause. You have gone through six sessions of an honest conversation with the harshest voice in your head, and that is not small. There is no need to rush into changing completely, just notice first that the voice exists and can be seen from the outside.',
          pertanyaanRefleksi: 'What is one thing that has changed in how you see Si Hakim since the first session?',
        );
      case 'l2_s1':
        return const BetterMeSessionText(
          judul: 'Put your thoughts on a small trial',
          konten:
              'Every anxious thought can be tested like in a courtroom: what evidence supports it, what evidence goes against it, and if this happened to your friend, what advice would you give? This exercise is not about ignoring your feelings, but about seeing the fuller picture.',
          pertanyaanRefleksi: 'Take one anxious thought from today. What evidence goes against it?',
        );
      case 'l2_s2':
        return const BetterMeSessionText(
          judul: 'Move first, mood follows',
          konten:
              'We often wait for a good mood before we are willing to move, but the order is often the other way around: move first, and the mood catches up. This is called behavioral activation, one small step can break the cycle of staying still because you feel drained.',
          pertanyaanRefleksi: 'What is one small activity you could do right now, without waiting for the mood to be ready?',
        );
      case 'l2_s3':
        return const BetterMeSessionText(
          judul: 'A boundary is not a wall',
          konten:
              'Saying "I can\'t" or "maybe later" to others often feels like a sin, when it is actually a way to protect your energy so it does not run out for everyone except yourself. A healthy boundary does not push people away, it keeps the relationship fair for you too.',
          pertanyaanRefleksi: 'What request lately have you actually wanted to turn down?',
        );
      case 'l2_s4':
        return const BetterMeSessionText(
          judul: 'Five senses grounding',
          konten:
              'When your thoughts spin too fast, the quickest way back to the present is through the body, not through logic. Try naming five things you can see, four you can hear, three you can feel by touch, two you can smell, and one you can taste.',
          pertanyaanRefleksi: 'Try the five senses exercise now. How does it feel afterwards?',
        );
      case 'l2_s5':
        return const BetterMeSessionText(
          judul: 'Rest is not laziness',
          konten:
              'Si Hakim likes to equate rest with laziness, but a body and mind that are never given a break will only get slower, not more productive. Real rest (not just scrolling) is part of work, not the opposite of work.',
          pertanyaanRefleksi: 'When did you last rest without feeling guilty?',
        );
      case 'l2_s6':
        return const BetterMeSessionText(
          judul: 'Spot one-sided thinking',
          konten:
              'All-or-nothing thinking makes one small mistake feel like a total failure. The exercise: every time an extreme thought shows up, try to find the middle ground. Not everything has only two options.',
          pertanyaanRefleksi: 'What extreme thought showed up this week, and what is the middle ground?',
        );
      case 'l2_s7':
        return const BetterMeSessionText(
          judul: 'Celebrate the small steps',
          konten:
              'We tend to celebrate only big achievements, but real change is built from small, consistent steps. Finishing this level is itself worth celebrating, not just waiting until you have "truly changed".',
          pertanyaanRefleksi: 'Which small step from this level do you most want to acknowledge as an achievement?',
        );
      case 'l3_s1':
        return const BetterMeSessionText(
          judul: 'A relapse is not starting from zero',
          konten:
              'Someday Si Hakim or another saboteur will drop by again, and that is not a sign you failed, it is a sign you are human. The difference now is that you have tools to recognize and respond to it, so you are not starting from zero again.',
          pertanyaanRefleksi: 'If your old saboteur shows up again next week, which tool will you use first?',
        );
      case 'l3_s2':
        return const BetterMeSessionText(
          judul: 'The values that truly matter to you',
          konten:
              'Amid all the targets and demands, it is easy to forget what you are really striving for. A personal value is a compass, not a checklist, it is never finished being achieved, but it can keep being lived.',
          pertanyaanRefleksi: 'Name one value (not a goal) that matters most in your life right now.',
        );
      case 'l3_s3':
        return const BetterMeSessionText(
          judul: 'A plan for the heavy days',
          konten:
              'Heavy days will come again, the question is not if, but when. Having a small plan prepared from now (who to reach out to, which exercise to use) makes those heavy days feel more manageable.',
          pertanyaanRefleksi: 'Write 3 steps you can take on a truly heavy day.',
        );
      case 'l3_s4':
        return const BetterMeSessionText(
          judul: 'Who is in your support system',
          konten:
              'No one can tame all their monsters alone, and that is not a weakness. Know who you can reach out to when things are hard, and do not wait until a real crisis to start building those relationships.',
          pertanyaanRefleksi: 'Name one person you can reach out to when things feel heavy. When did you last talk to them?',
        );
      case 'l3_s5':
        return const BetterMeSessionText(
          judul: 'Looking back at the road you have walked',
          konten:
              'It is so easy to focus on how far is left to go, and forget how far you have already come. Before continuing, look back from the first session until now, and see what has changed, however small.',
          pertanyaanRefleksi: 'What is one thing that is different about you now compared to when you started Better Me?',
        );
      case 'l3_s6':
        return const BetterMeSessionText(
          judul: 'The fog may visit, you keep walking',
          konten:
              'Not every day has to feel good for the day to matter. You can keep walking, keep doing small things, even while feeling foggy or heavy. Both can exist together, there is no need to wait until the fog clears.',
          pertanyaanRefleksi: 'When did you last keep going even while not feeling okay?',
        );
      case 'l3_s7':
        return const BetterMeSessionText(
          judul: 'Writing a letter to yourself',
          konten:
              'Write a short letter to your future self, whenever it gets read again. It does not have to be formal, just honest: what do you want to remind yourself of when you meet Si Hakim again.',
          pertanyaanRefleksi: 'Write the opening sentence of that letter here.',
        );
      case 'l3_s8':
        return const BetterMeSessionText(
          judul: 'Congratulations, you made it here',
          konten:
              '22 sessions, three levels, and you are still here. This is not a finish line, this program was never designed to "cure" in a single round, but to be a practice you can repeat whenever you need it. Your monsters will not disappear forever, but now you know how to keep them company.',
          pertanyaanRefleksi: 'What do you want to carry from this program into your ordinary days after this?',
        );
    }
    return const BetterMeSessionText(judul: '', konten: '', pertanyaanRefleksi: '');
  }

  @override
  BetterMeLevelText level(int number) {
    switch (number) {
      case 1:
        return const BetterMeLevelText(judul: 'Get to know Si Hakim', deskripsi: 'Start by recognizing the harshest voice in your head, before trying to change it.');
      case 2:
        return const BetterMeLevelText(judul: 'Retraining your habits', deskripsi: 'From just recognizing to practicing new responses through small actions.');
      case 3:
        return const BetterMeLevelText(judul: 'Keeping what has grown', deskripsi: 'Change is not a straight line. This level is about staying with it, not starting anymore.');
    }
    return const BetterMeLevelText(judul: '', deskripsi: '');
  }

  @override
  String get title => 'Better Me';
  @override
  String typeLabel(String typeName) {
    switch (typeName) {
      case 'psikoedukasi':
        return 'Psychoeducation';
      case 'latihan':
        return 'Exercise';
      case 'restrukturisasi':
        return 'Thought restructuring';
      case 'aktivasiPerilaku':
        return 'Behavioral activation';
    }
    return typeName;
  }

  @override
  String levelName(int number) => 'Level $number';
  @override
  String sessionCount(int count) => count == 1 ? '1 session' : '$count sessions';
  @override
  String sessionsProgress(int done, int total) => '$done/$total sessions';
  @override
  String minutes(int minutes) => '$minutes min';
  @override
  String minutesLong(int minutes) => '$minutes minutes';
  @override
  String totalMinutes(int minutes) => '~$minutes minutes total';

  @override
  String get subtitle => 'Small changes that show when you add them up';
  @override
  String totalDone(int done, int total) => '$done/$total sessions completed';
  @override
  String levelLockedTitle(int number) => 'Level $number is still locked';
  @override
  String levelLockedNote(int previous) => 'Finish Level $previous and activate Riung Premium to open this level.';
  @override
  String levelTitleWithName(int number, String name) => 'Level $number · $name';

  @override
  String get startLevel => 'Start this level';
  @override
  String continueWith(String sessionTitle) => 'Continue · $sessionTitle';
  @override
  String get start => 'Start';

  @override
  String get reflectionHint => 'Write here, there is no wrong answer...';
  @override
  String get saving => 'Saving...';

  @override
  String get sessionDone => 'Session complete';
  @override
  String get coins => 'coins';
  @override
  String get sessionsInLevel => 'sessions in this level';
  @override
  String levelDone(int number) => 'LEVEL $number COMPLETE';
  @override
  String get allDone => 'You finished all 22 Better Me sessions. This is not a finish line, but a practice you can repeat whenever you need it.';
  @override
  String nextLevelOpen(int next) => 'Level $next is now open. No need to rush on, take a break if you need one.';
}
