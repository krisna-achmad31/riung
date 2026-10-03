/// Teks fitur Home: Beranda, Jelajah, Mode Fokus (timer & sesi selesai),
/// kartu pemain, histori koin.
abstract class HomeStrings {
  const HomeStrings();

  // ── Beranda ──
  String get defaultUserName;
  String greeting(String name);
  String get loadError;
  String get checkinDone;
  String get checkinPrompt;
  String checkinDoneSub(int coins);
  String checkinPromptSub(int coins);
  String get checkinStart;
  String get bossBadge;
  String get hakimTamed;
  String get hakimWild;
  String progressToTamed(int percent);
  String missionTitle(String monsterName);
  List<String> get missions;
  String get missionNote;
  String get missionDone;
  String get focusTitle;
  String focusSub(int coins);
  String get tipText;
  String get tipSource;

  // ── Aksi cepat ──
  String get quickMeditation;
  String get quickMeditationSub;
  String get quickSleep;
  String get quickSleepSub;
  String get quickJournal;
  String get quickJournalSub;
  String get quickAffirmation;
  String get quickAffirmationSub;

  // ── Tiket serangan ──
  String ticketTitle(int tickets);
  String get ticketBody;
  String ticketBreakdown(int tickets, int free, int practice);
  String get attack;
  String get checkinSoon;
  String checkinDoneMood(int coins);

  // ── Jelajah ──
  String get tabMeditation;
  String get tabSleep;
  String get tabJournal;
  String get tabAffirmation;

  // ── Timer fokus ──
  String get appsBlocked;
  String sessionMinutes(int minutes);
  String get remaining;
  String get focusCompanion;
  String get resume;
  String get pause;
  String get emergencyExit;
  String notEnoughCoins(int coins);
  String get fastestWayToCoins;

  // ── Sesi selesai ──
  String fullMinutes(int minutes, String name);
  String get sessionRest;
  String get streakDays;
  String get viewPlayerCard;
  String get backToHome;

  // ── Kartu pemain ──
  String get playerCardTitle;
  String get shareNote;
  String get share;
  String get saveImage;
  String get playerRank;
  String get statStreak;
  String get statJournal;
  String get statTamed;
  String get statProgress;
  String tamedOf(int tamed);
  String get cardSaved;
  String get cardSaveFailed;
  String get cardShareFailed;
  String shareCaption(String name, int streak, int tamed);

  // ── Histori koin ──
  String get historyTitle;
  String get historyEmpty;
  String get today;
  String get yesterday;
  String get coinIn;
  String get coinOut;
  String get reasonCheckin;
  String get reasonJournal;
  String get reasonMeditation;
  String get reasonMinigame;
  String get reasonBetterMe;
  String get reasonTamed;
  String get reasonFocus;
  String get reasonPrepaidFocus;
  String get reasonPurchase;
  String get reasonCosmetic;
  String get reasonStreakShield;
  String get reasonScrollUnlock;
  String get reasonMission;
}

class HomeStringsId extends HomeStrings {
  const HomeStringsId();

  @override
  String get defaultUserName => 'kamu';
  @override
  String greeting(String name) => 'Halo, $name 🌙';
  @override
  String get loadError => 'Gagal memuat berandamu. Cek koneksi lalu coba lagi.';
  @override
  String get checkinDone => 'Check-in pagi ✓ selesai';
  @override
  String get checkinPrompt => 'Gimana perasaanmu pagi ini?';
  @override
  String checkinDoneSub(int coins) => 'Mood tercatat · +$coins koin masuk';
  @override
  String checkinPromptSub(int coins) => 'Check-in 1 menit · dapat $coins koin';
  @override
  String get checkinStart => 'Mulai check-in';
  @override
  String get bossBadge => 'BOS';
  @override
  String get hakimTamed => 'Sudah jinak · mampir lagi kadang wajar';
  @override
  String get hakimWild => 'Masih liar · lanjutkan latihanmu';
  @override
  String progressToTamed(int percent) => '$percent% menuju jinak';
  @override
  String missionTitle(String monsterName) => 'Misi harian lawan $monsterName';
  @override
  List<String> get missions => const [
        'Tunda khawatirmu ke slot 10 menit nanti sore',
        'Tarik napas 4 hitungan sebelum bereaksi',
        'Sebutkan 3 benda yang kamu lihat sekarang',
      ];
  @override
  String get missionNote => 'Misi baru tiap pagi, mengikuti monster yang lagi kamu jinakkan.';
  @override
  String get missionDone => 'Misi selesai';
  @override
  String get focusTitle => 'Mode Fokus';
  @override
  String focusSub(int coins) => 'Istirahatkan pikiran dari scroll. Mulai dari $coins koin.';
  @override
  String get tipText => 'Latihan pernapasan rutin terbukti mempercepat turunnya kecemasan. Coba 3 menit aja hari ini.';
  @override
  String get tipSource => 'Riset CBT';

  @override
  String get quickMeditation => 'Meditasi';
  @override
  String get quickMeditationSub => '6 sesi';
  @override
  String get quickSleep => 'Tidur';
  @override
  String get quickSleepSub => 'Cerita & suara';
  @override
  String get quickJournal => 'Jurnal';
  @override
  String get quickJournalSub => 'Terkunci & pribadi';
  @override
  String get quickAffirmation => 'Afirmasi';
  @override
  String get quickAffirmationSub => 'Kartu harian';

  @override
  String ticketTitle(int tickets) => 'Kamu punya $tickets tiket serangan!';
  @override
  String get ticketBody => 'Si Hakim sedang lengah. Serang sekarang lewat mini-game "pecahkan balok".';
  @override
  String ticketBreakdown(int tickets, int free, int practice) => '×$tickets tiket · $free gratis + $practice latihan';
  @override
  String get attack => 'Serang';
  @override
  String get checkinSoon => 'Yuk check-in dulu';
  @override
  String checkinDoneMood(int coins) => 'Mood: cukup tenang · +$coins koin masuk';

  @override
  String get tabMeditation => 'Meditasi';
  @override
  String get tabSleep => 'Tidur';
  @override
  String get tabJournal => 'Jurnal';
  @override
  String get tabAffirmation => 'Afirmasi';

  @override
  String get appsBlocked => 'Aplikasi lain diblokir';
  @override
  String sessionMinutes(int minutes) => 'Sesi $minutes menit';
  @override
  String get remaining => 'tersisa';
  @override
  String get focusCompanion => 'Si Waswas ikut tenang tiap kali kamu fokus. Tarik napas, biarkan notifikasi menunggu.';
  @override
  String get resume => 'Lanjutkan';
  @override
  String get pause => 'Jeda sebentar';
  @override
  String get emergencyExit => 'Keluar darurat, streak tetap aman, sesi tidak dihitung';
  @override
  String notEnoughCoins(int coins) => 'Koinmu belum cukup, sesi ini butuh $coins koin.';
  @override
  String get fastestWayToCoins => 'Cara tercepat dapat koin: check-in pagi, jurnal, atau selesaikan misi harian dulu.';

  @override
  String fullMinutes(int minutes, String name) => '$minutes menit penuh. Keren${name.isEmpty ? '' : ', $name'}!';
  @override
  String get sessionRest => 'Pikiranmu baru saja dapat jeda yang dia butuhkan.';
  @override
  String get streakDays => 'hari streak';
  @override
  String get viewPlayerCard => 'Lihat kartu pemainku';
  @override
  String get backToHome => 'Kembali ke beranda';

  @override
  String get playerCardTitle => 'Kartu pemain';
  @override
  String get shareNote => 'Bagikan progresmu tanpa membagikan isi jurnalmu 🔒';
  @override
  String get share => 'Bagikan';
  @override
  String get saveImage => 'Simpan';
  @override
  String get playerRank => 'PENJINAK PEMULA';
  @override
  String get statStreak => 'streak saat ini';
  @override
  String get statJournal => 'entri jurnal';
  @override
  String get statTamed => 'monster jinak';
  @override
  String get statProgress => 'progres total';
  @override
  String tamedOf(int tamed) => '$tamed dari 7 jinak';
  @override
  String get cardSaved => 'Kartu tersimpan ke galeri.';
  @override
  String get cardSaveFailed => 'Gagal simpan kartu, coba lagi.';
  @override
  String get cardShareFailed => 'Gagal membagikan kartu, coba lagi.';
  @override
  String shareCaption(String name, int streak, int tamed) =>
      '$name · streak $streak hari · $tamed dari 7 monster jinak, via Riung';

  @override
  String get historyTitle => 'Histori koin';
  @override
  String get historyEmpty => 'Belum ada transaksi koin. Mulai dari check-in atau meditasi pertama, yuk.';
  @override
  String get today => 'Hari ini';
  @override
  String get yesterday => 'Kemarin';
  @override
  String get coinIn => 'Koin masuk';
  @override
  String get coinOut => 'Koin keluar';
  @override
  String get reasonCheckin => 'Check-in harian';
  @override
  String get reasonJournal => 'Entri jurnal';
  @override
  String get reasonMeditation => 'Sesi meditasi';
  @override
  String get reasonMinigame => 'Menang mini-game';
  @override
  String get reasonBetterMe => 'Sesi Better me';
  @override
  String get reasonTamed => 'Monster jinak';
  @override
  String get reasonFocus => 'Mode Fokus';
  @override
  String get reasonPrepaidFocus => 'Beli sesi fokus';
  @override
  String get reasonPurchase => 'Pembelian koin';
  @override
  String get reasonCosmetic => 'Kosmetik monster';
  @override
  String get reasonStreakShield => 'Pelindung streak';
  @override
  String get reasonScrollUnlock => 'Buka blokir scroll';
  @override
  String get reasonMission => 'Misi harian';
}

class HomeStringsEn extends HomeStrings {
  const HomeStringsEn();

  @override
  String get defaultUserName => 'there';
  @override
  String greeting(String name) => 'Hi, $name 🌙';
  @override
  String get loadError => 'Could not load your home. Check your connection and try again.';
  @override
  String get checkinDone => 'Morning check-in ✓ done';
  @override
  String get checkinPrompt => 'How are you feeling this morning?';
  @override
  String checkinDoneSub(int coins) => 'Mood logged · +$coins coins earned';
  @override
  String checkinPromptSub(int coins) => '1-minute check-in · earn $coins coins';
  @override
  String get checkinStart => 'Start check-in';
  @override
  String get bossBadge => 'BOSS';
  @override
  String get hakimTamed => 'Already tamed · it is normal for him to drop by sometimes';
  @override
  String get hakimWild => 'Still wild · keep up your practice';
  @override
  String progressToTamed(int percent) => '$percent% to tamed';
  @override
  String missionTitle(String monsterName) => 'Daily mission against $monsterName';
  @override
  List<String> get missions => const [
        'Postpone your worry to a 10-minute slot this afternoon',
        'Breathe in for 4 counts before reacting',
        'Name 3 things you can see right now',
      ];
  @override
  String get missionNote => 'New missions every morning, following the monster you are taming.';
  @override
  String get missionDone => 'Mission done';
  @override
  String get focusTitle => 'Focus Mode';
  @override
  String focusSub(int coins) => 'Rest your mind from scrolling. Starting from $coins coins.';
  @override
  String get tipText => 'Regular breathing exercises are proven to speed up the drop in anxiety. Try just 3 minutes today.';
  @override
  String get tipSource => 'CBT research';

  @override
  String get quickMeditation => 'Meditation';
  @override
  String get quickMeditationSub => '6 sessions';
  @override
  String get quickSleep => 'Sleep';
  @override
  String get quickSleepSub => 'Stories & sounds';
  @override
  String get quickJournal => 'Journal';
  @override
  String get quickJournalSub => 'Locked & private';
  @override
  String get quickAffirmation => 'Affirmations';
  @override
  String get quickAffirmationSub => 'Daily cards';

  @override
  String ticketTitle(int tickets) => tickets == 1 ? 'You have 1 attack ticket!' : 'You have $tickets attack tickets!';
  @override
  String get ticketBody => 'Si Hakim has let his guard down. Attack now with the "break the blocks" mini-game.';
  @override
  String ticketBreakdown(int tickets, int free, int practice) =>
      '×$tickets ${tickets == 1 ? 'ticket' : 'tickets'} · $free free + $practice from practice';
  @override
  String get attack => 'Attack';
  @override
  String get checkinSoon => 'Check in first';
  @override
  String checkinDoneMood(int coins) => 'Mood: fairly calm · +$coins coins earned';

  @override
  String get tabMeditation => 'Meditation';
  @override
  String get tabSleep => 'Sleep';
  @override
  String get tabJournal => 'Journal';
  @override
  String get tabAffirmation => 'Affirmations';

  @override
  String get appsBlocked => 'Other apps blocked';
  @override
  String sessionMinutes(int minutes) => '$minutes-minute session';
  @override
  String get remaining => 'remaining';
  @override
  String get focusCompanion => 'Si Waswas calms down every time you focus. Take a breath, let the notifications wait.';
  @override
  String get resume => 'Resume';
  @override
  String get pause => 'Pause for a moment';
  @override
  String get emergencyExit => 'Emergency exit, your streak stays safe, the session is not counted';
  @override
  String notEnoughCoins(int coins) => 'Not enough coins yet, this session needs $coins coins.';
  @override
  String get fastestWayToCoins => 'Fastest ways to earn coins: morning check-in, journal, or finish your daily missions first.';

  @override
  String fullMinutes(int minutes, String name) => '$minutes full minutes. Nice${name.isEmpty ? '' : ', $name'}!';
  @override
  String get sessionRest => 'Your mind just got the break it needed.';
  @override
  String get streakDays => 'day streak';
  @override
  String get viewPlayerCard => 'See my player card';
  @override
  String get backToHome => 'Back to home';

  @override
  String get playerCardTitle => 'Player card';
  @override
  String get shareNote => 'Share your progress without sharing your journal 🔒';
  @override
  String get share => 'Share';
  @override
  String get saveImage => 'Save';
  @override
  String get playerRank => 'NOVICE TAMER';
  @override
  String get statStreak => 'current streak';
  @override
  String get statJournal => 'journal entries';
  @override
  String get statTamed => 'monsters tamed';
  @override
  String get statProgress => 'total progress';
  @override
  String tamedOf(int tamed) => '$tamed of 7 tamed';
  @override
  String get cardSaved => 'Card saved to your gallery.';
  @override
  String get cardSaveFailed => 'Could not save the card, please try again.';
  @override
  String get cardShareFailed => 'Could not share the card, please try again.';
  @override
  String shareCaption(String name, int streak, int tamed) =>
      '$name · $streak-day streak · $tamed of 7 monsters tamed, via Riung';

  @override
  String get historyTitle => 'Coin history';
  @override
  String get historyEmpty => 'No coin transactions yet. Start with your first check-in or meditation.';
  @override
  String get today => 'Today';
  @override
  String get yesterday => 'Yesterday';
  @override
  String get coinIn => 'Coins in';
  @override
  String get coinOut => 'Coins out';
  @override
  String get reasonCheckin => 'Daily check-in';
  @override
  String get reasonJournal => 'Journal entry';
  @override
  String get reasonMeditation => 'Meditation session';
  @override
  String get reasonMinigame => 'Mini-game win';
  @override
  String get reasonBetterMe => 'Better Me session';
  @override
  String get reasonTamed => 'Monster tamed';
  @override
  String get reasonFocus => 'Focus Mode';
  @override
  String get reasonPrepaidFocus => 'Focus sessions purchase';
  @override
  String get reasonPurchase => 'Coin purchase';
  @override
  String get reasonCosmetic => 'Monster cosmetic';
  @override
  String get reasonStreakShield => 'Streak shield';
  @override
  String get reasonScrollUnlock => 'Scroll unblock';
  @override
  String get reasonMission => 'Daily mission';
}
