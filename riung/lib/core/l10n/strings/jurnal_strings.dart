/// Teks satu panduan CBT jurnal, dipetakan lewat id prompt.
class JournalPromptText {
  const JournalPromptText({required this.title, required this.sub, required this.guideQuestion});

  final String title;
  final String sub;
  final String guideQuestion;
}

/// Teks fitur Jurnal: daftar, pilih prompt, editor, tersimpan, PIN.
abstract class JurnalStrings {
  const JurnalStrings();

  // ── Daftar ──
  String get title;
  String get lockedSubtitle;
  String entryCount(int count);
  String get emptyTitle;
  String get emptyBody;
  String writeFirst(int coins);
  String writeCta(int coins);
  String get recentEntries;
  String get encryptedNote;
  String get dailyLimitTitle;
  String get lockedTitle;
  String get lockedBody;
  String get unlockCta;
  String get dailyLimitNote;

  // ── Pilih prompt ──
  String get promptScreenTitle;
  String get freeWriteKicker;
  String get freeWriteTitle;
  String get freeWriteBody;
  String get orCbtGuide;
  String promptText(String id, {required bool title});
  JournalPromptText prompt(String id);
  String threeSentences(int coins);

  // ── Editor ──
  String get autoSaved;
  String get done;
  String get guidePrefix;
  String get editorHint;
  String get moodLabel;
  String monsterDetected(String monsterName);
  String monsterMarked(String monsterName);
  String get syncFailedTitle;
  String get syncFailedSub;
  String get syncFailedPrefix;
  String get syncFailedSafe;
  String get syncFailedSuffix;
  String get syncFailedOk;

  // ── Tersimpan ──
  String get savedBossTitle;
  String get savedTitle;
  String get savedBossSub;
  String get savedSub;
  String get coins;
  String get savedNote;
  String get backToJournal;

  // ── PIN ──
  String get pinCreate;
  String get pinRepeat;
  String get pinCreateSub;
  String get pinRepeatSub;
  String get pinLocalOnly;
  String get pinMismatch;
  String get pinEnter;
  String get pinEnterSub;
  String get pinWrong;
  String get useFingerprint;
  String get pinOldTitle;
  String get pinOldSub;
  String get pinForgotOld;
  String get biometricReason;
}

class JurnalStringsId extends JurnalStrings {
  const JurnalStringsId();

  @override
  String get title => 'Jurnal';
  @override
  String get lockedSubtitle => 'Terkunci & hanya untukmu 🔒';
  @override
  String entryCount(int count) => '$count entri';
  @override
  String get emptyTitle => 'Halaman pertamamu masih kosong';
  @override
  String get emptyBody =>
      'Nggak perlu rapi, nggak perlu panjang. Tiga kalimat tentang harimu udah cukup buat mulai, dan Si Kabut paling nggak tahan sama pikiran yang dituliskan.';
  @override
  String writeFirst(int coins) => 'Tulis entri pertama · +$coins koin';
  @override
  String writeCta(int coins) => 'Tulis · +$coins koin';
  @override
  String get recentEntries => 'Entri terakhir';
  @override
  String get encryptedNote => 'Terkunci, terenkripsi, hanya untukmu';
  @override
  String get lockedTitle => 'Jurnalmu terkunci';
  @override
  String get lockedBody => 'Hanya kamu yang bisa membukanya, dengan PIN atau sidik jari.';
  @override
  String get unlockCta => 'Buka jurnal';
  @override
  String get dailyLimitTitle => 'Entri jurnal hari ini';
  @override
  String get dailyLimitNote => 'Kamu sudah pakai jatah 1 entri gratis hari ini, besok segar lagi.';

  @override
  String get promptScreenTitle => 'Mau nulis dari mana?';
  @override
  String get freeWriteKicker => 'TULIS BEBAS';
  @override
  String get freeWriteTitle => 'Kosongkan saja isi kepala';
  @override
  String get freeWriteBody => 'Tanpa arahan, tanpa format. Tulis apa pun yang lagi penuh di pikiranmu.';
  @override
  String get orCbtGuide => 'Atau pakai panduan CBT';
  @override
  String promptText(String id, {required bool title}) => title ? prompt(id).title : prompt(id).sub;
  @override
  JournalPromptText prompt(String id) {
    switch (id) {
      case 'p_hakim':
        return const JournalPromptText(
          title: 'Lawan balik suara "aku pasti gagal"',
          sub: 'Cocok kalau kamu lagi keras banget sama diri sendiri.',
          guideQuestion: 'Apa bukti kalau pikiran ini benar? Apa bukti sebaliknya?',
        );
      case 'p_kabut':
        return const JournalPromptText(
          title: 'Tulis apa yang bikin numpuk di kepala',
          sub: 'Buat hari yang berat atau bikin kewalahan.',
          guideQuestion: 'Kalau harus dipilih satu, hal apa yang paling terasa berat hari ini?',
        );
      case 'p_cermin':
        return const JournalPromptText(
          title: 'Bandingin diri sama siapa hari ini?',
          sub: 'Buat saat scroll medsos bikin insecure.',
          guideQuestion: 'Apa yang sebenarnya kamu banggakan dari harimu, di luar yang orang lain lihat?',
        );
      case 'p_waswas':
        return const JournalPromptText(
          title: 'Apa skenario terburuk yang kamu takutkan?',
          sub: 'Buat kecemasan soal sesuatu yang belum terjadi.',
          guideQuestion: 'Kalau skenario terburuk itu terjadi, seberapa besar kemungkinan kamu bisa menghadapinya?',
        );
      case 'p_mengelak':
        return const JournalPromptText(
          title: 'Hal apa yang kamu tunda hari ini?',
          sub: 'Buat saat menghindar terasa lebih mudah.',
          guideQuestion: 'Apa yang sebenarnya kamu takutkan kalau langsung mulai mengerjakannya?',
        );
    }
    return const JournalPromptText(title: '', sub: '', guideQuestion: '');
  }

  @override
  String threeSentences(int coins) => 'Menulis 3 kalimat saja sudah dihitung selesai · +$coins koin';

  @override
  String get autoSaved => 'Tersimpan otomatis ✓';
  @override
  String get done => 'Selesai';
  @override
  String get guidePrefix => 'Panduan: ';
  @override
  String get editorHint => 'Mulai dari apa pun yang lagi kepikiran…';
  @override
  String get moodLabel => 'MOOD';
  @override
  String monsterDetected(String monsterName) => '$monsterName terdeteksi';
  @override
  String monsterMarked(String monsterName) =>
      'Riung menandai pola ini sebagai suara $monsterName. Menyelesaikan entri ini melemahkannya +2%.';
  @override
  String get syncFailedTitle => 'Belum tersinkron';
  @override
  String get syncFailedSub => 'Koneksi terputus saat menyimpan';
  @override
  String get syncFailedPrefix => 'Tenang, tulisanmu ';
  @override
  String get syncFailedSafe => 'sudah aman tersimpan di perangkat ini';
  @override
  String get syncFailedSuffix => '. Riung akan menyinkronkannya otomatis begitu kamu online, koinmu juga tetap masuk.';
  @override
  String get syncFailedOk => 'Oke, lanjut menulis';

  @override
  String get savedBossTitle => 'Kamu barusan melawan balik Si Hakim ✍️';
  @override
  String get savedTitle => 'Entrimu tersimpan ✍️';
  @override
  String get savedBossSub => 'Menuliskan bukti sebaliknya itu inti dari CBT, dan kamu melakukannya sendiri.';
  @override
  String get savedSub => 'Menuliskan isi kepala itu langkah kecil yang berarti besar.';
  @override
  String get coins => 'koin';
  @override
  String get savedNote => 'Entri ini terenkripsi di perangkatmu. Progresmu bisa dibagikan, isinya nggak pernah.';
  @override
  String get backToJournal => 'Kembali ke jurnal';

  @override
  String get pinCreate => 'Buat PIN 6 digit';
  @override
  String get pinRepeat => 'Ulangi PIN-mu';
  @override
  String get pinCreateSub => 'PIN ini mengunci jurnalmu. Cuma kamu yang tahu.';
  @override
  String get pinRepeatSub => 'Masukkan sekali lagi supaya kami yakin PIN-nya benar.';
  @override
  String get pinLocalOnly => 'PIN ini cuma tersimpan di HP ini. Login supaya PIN bisa dipulihkan kalau ganti HP.';
  @override
  String get pinMismatch => 'PIN-nya beda nih, coba lagi dari awal.';
  @override
  String get pinEnter => 'Masukkan PIN';
  @override
  String get pinEnterSub => 'Jurnalmu terkunci. Cuma kamu yang bisa membukanya.';
  @override
  String get pinWrong => 'PIN-nya salah, coba lagi.';
  @override
  String get useFingerprint => 'Pakai sidik jari';
  @override
  String get pinOldTitle => 'Masukkan PIN lamamu';
  @override
  String get pinOldSub => 'Kamu pernah bikin PIN jurnal di HP lain. Masukkan PIN yang sama untuk buka jurnalmu di sini.';
  @override
  String get pinForgotOld => 'Lupa PIN lama? Buat PIN baru';
  @override
  String get biometricReason => 'Buka jurnalmu dengan sidik jari';
}

class JurnalStringsEn extends JurnalStrings {
  const JurnalStringsEn();

  @override
  String get title => 'Journal';
  @override
  String get lockedSubtitle => 'Locked & only for you 🔒';
  @override
  String entryCount(int count) => count == 1 ? '1 entry' : '$count entries';
  @override
  String get emptyTitle => 'Your first page is still empty';
  @override
  String get emptyBody =>
      "It doesn't need to be neat or long. Three sentences about your day are enough to start, and Si Kabut can't stand thoughts that get written down.";
  @override
  String writeFirst(int coins) => 'Write your first entry · +$coins coins';
  @override
  String writeCta(int coins) => 'Write · +$coins coins';
  @override
  String get recentEntries => 'Recent entries';
  @override
  String get encryptedNote => 'Locked, encrypted, only for you';
  @override
  String get lockedTitle => 'Your journal is locked';
  @override
  String get lockedBody => 'Only you can open it, with your PIN or fingerprint.';
  @override
  String get unlockCta => 'Open journal';
  @override
  String get dailyLimitTitle => "Today's journal entry";
  @override
  String get dailyLimitNote => "You've used your 1 free entry for today, it refreshes tomorrow.";

  @override
  String get promptScreenTitle => 'Where do you want to start?';
  @override
  String get freeWriteKicker => 'FREE WRITING';
  @override
  String get freeWriteTitle => 'Just empty your head';
  @override
  String get freeWriteBody => 'No guidance, no format. Write whatever is filling your mind.';
  @override
  String get orCbtGuide => 'Or use a CBT guide';
  @override
  String promptText(String id, {required bool title}) => title ? prompt(id).title : prompt(id).sub;
  @override
  JournalPromptText prompt(String id) {
    switch (id) {
      case 'p_hakim':
        return const JournalPromptText(
          title: 'Fight back against the "I will surely fail" voice',
          sub: 'Good for when you are being very hard on yourself.',
          guideQuestion: 'What is the evidence that this thought is true? What is the evidence against it?',
        );
      case 'p_kabut':
        return const JournalPromptText(
          title: 'Write down what is piling up in your head',
          sub: 'For heavy or overwhelming days.',
          guideQuestion: 'If you had to pick just one, what feels heaviest today?',
        );
      case 'p_cermin':
        return const JournalPromptText(
          title: 'Who are you comparing yourself to today?',
          sub: 'For when scrolling social media makes you insecure.',
          guideQuestion: 'What are you actually proud of about your day, apart from what others can see?',
        );
      case 'p_waswas':
        return const JournalPromptText(
          title: 'What is the worst-case scenario you fear?',
          sub: 'For anxiety about something that has not happened yet.',
          guideQuestion: 'If that worst case happened, how likely is it that you could face it?',
        );
      case 'p_mengelak':
        return const JournalPromptText(
          title: 'What did you put off today?',
          sub: 'For when avoiding feels easier.',
          guideQuestion: 'What are you actually afraid of if you start working on it right away?',
        );
    }
    return const JournalPromptText(title: '', sub: '', guideQuestion: '');
  }

  @override
  String threeSentences(int coins) => 'Writing just 3 sentences counts as done · +$coins coins';

  @override
  String get autoSaved => 'Saved automatically ✓';
  @override
  String get done => 'Done';
  @override
  String get guidePrefix => 'Guide: ';
  @override
  String get editorHint => 'Start with whatever is on your mind…';
  @override
  String get moodLabel => 'MOOD';
  @override
  String monsterDetected(String monsterName) => '$monsterName detected';
  @override
  String monsterMarked(String monsterName) =>
      'Riung marks this pattern as the voice of $monsterName. Finishing this entry weakens it by +2%.';
  @override
  String get syncFailedTitle => 'Not synced yet';
  @override
  String get syncFailedSub => 'Connection lost while saving';
  @override
  String get syncFailedPrefix => 'Don\'t worry, your writing ';
  @override
  String get syncFailedSafe => 'is safely stored on this device';
  @override
  String get syncFailedSuffix => '. Riung will sync it automatically once you are online, and your coins still count.';
  @override
  String get syncFailedOk => 'Okay, keep writing';

  @override
  String get savedBossTitle => 'You just fought back against Si Hakim ✍️';
  @override
  String get savedTitle => 'Your entry is saved ✍️';
  @override
  String get savedBossSub => 'Writing down the evidence to the contrary is the heart of CBT, and you did it yourself.';
  @override
  String get savedSub => 'Writing out what is in your head is a small step that means a lot.';
  @override
  String get coins => 'coins';
  @override
  String get savedNote => 'This entry is encrypted on your device. Your progress can be shared, its content never.';
  @override
  String get backToJournal => 'Back to journal';

  @override
  String get pinCreate => 'Create a 6-digit PIN';
  @override
  String get pinRepeat => 'Repeat your PIN';
  @override
  String get pinCreateSub => 'This PIN locks your journal. Only you know it.';
  @override
  String get pinRepeatSub => 'Enter it once more so we are sure the PIN is right.';
  @override
  String get pinLocalOnly => 'This PIN is only stored on this phone. Sign in so the PIN can be restored if you switch phones.';
  @override
  String get pinMismatch => 'The PINs differ, please start over.';
  @override
  String get pinEnter => 'Enter PIN';
  @override
  String get pinEnterSub => 'Your journal is locked. Only you can open it.';
  @override
  String get pinWrong => 'Wrong PIN, please try again.';
  @override
  String get useFingerprint => 'Use fingerprint';
  @override
  String get pinOldTitle => 'Enter your old PIN';
  @override
  String get pinOldSub => 'You created a journal PIN on another phone. Enter the same PIN to open your journal here.';
  @override
  String get pinForgotOld => 'Forgot your old PIN? Create a new one';
  @override
  String get biometricReason => 'Open your journal with your fingerprint';
}
