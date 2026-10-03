/// Teks fitur Aplikasi Beku: rekap, setup, izin, interstisial, napas,
/// setelah napas, dan section "Buka Waktu Scroll" di Toko.
abstract class AppbekuStrings {
  const AppbekuStrings();

  // ── Umum ──
  String get title;
  String get notEnoughCoins;
  String get footerNote;
  String minutesShort(int minutes);

  /// Keterangan kontekstual di kartu aplikasi (rata-rata pemakaian nasional).
  String appUsageAverage(int minutesPerDay);
  String get whatsappNote;

  // ── Pengaman buka-berbayar ──
  String get unlockCapReached;
  String get earnedCoinsOnly;
  String get notEnoughEarnedCoins;
  String waitSeconds(int seconds);
  String unlocksLeftToday(int left);

  // ── Kunci ──
  String get lockInactiveNotice;
  String get lockInactiveAction;
  String get lockNotifTitle;
  String get lockNotifBody;
  String get lockTitle;
  String get lockOnBody;
  String get lockOffBody;
  String get lockNeedsPermission;
  String get grantPermission;
  String get accessibilityTitle;
  String get accessibilityHeadline;
  String get accessibilityBody;
  String get accessibilityReadTitle;
  List<String> get accessibilityReadItems;
  List<String> get accessibilityCannotItems;
  String get accessibilityRevoke;
  String get openAccessibilitySettings;

  // ── Interstisial ──
  String limitReachedChip(String appName, int usage);
  String get interstitialTitle;
  String get interstitialBody;
  String get interstitialNote;
  String get breatheFree;
  String unlockMoreCoins(int coins);

  // ── Napas ──
  String get breathIn;
  String get breathHold;
  String get breathOut;
  String breatheHeader(String? appName);
  String secondsLeft(int seconds);
  String get breatheHint;

  // ── Setelah napas ──
  String get postKicker;
  String get postTitle;
  String get postBody;
  String closeApp(String? appName);
  String unlockShortCoins(int coins);
  String get noWrongAnswer;

  // ── Izin ──
  String get permissionTitle;
  String get permissionHeadline;
  String get permissionBody;
  String get readTitle;
  List<String> get readItems;
  String get cannotSeeTitle;
  List<String> get cannotSeeItems;
  String get permissionRevoke;
  String get openAndroidSettings;

  // ── Rekap ──
  String get today;
  String scrollMinutes(int minutes);
  String underLimit(int minutes);
  String get totalLimitReached;
  String get perApp;
  String usedMinutes(int used);
  String get limitReachedInline;
  String ofLimit(int limit);
  String breathsTaken(int count);
  String get breathsLabel;
  String get coinsLabel;
  String streakDays(int days);
  String get streakLabel;
  String get didYouKnowText;
  String get didYouKnowSource;
  String get emptyTitle;
  String get emptyBody;
  String get setupApps;

  // ── Setup ──
  String get setupHeadline;
  String get setupBody;
  String get dailyLimit;
  String get pickAtLeastOne;
  String freezeCount(int count);

  // ── Toko: Buka Waktu Scroll ──
  String get unlockSectionTitle;
  String get unlockSectionBody;
  String get whichApp;
  String minutesFull(int minutes);
  String get forOneApp;
  String get bundles;
  String get relaxedTitle;
  String get relaxedSub;
  String get allSocialTitle;
  String get allSocialSub;
  String saveBadge(int percent);
  String get unlocked;
  String get coinsChanged;
  String get relaxedNeedsApps;
  String get relaxedUnlocked;
  String get socialNeedsApp;
  String get socialUnlocked;
  String itemMinutes(int minutes, String? appName);
  String get itemRelaxed;
  String get itemAllSocial;
}

class AppbekuStringsId extends AppbekuStrings {
  const AppbekuStringsId();

  @override
  String get title => 'Aplikasi Beku';
  @override
  String get notEnoughCoins => 'Koinmu belum cukup.';
  @override
  String get footerNote => 'Riung nggak pernah menahanmu tanpa jalan keluar: napas sebentar gratis, dan kunci bisa dimatikan kapan saja di pengaturan.';
  @override
  String minutesShort(int minutes) => '$minutes mnt';

  @override
  String appUsageAverage(int minutesPerDay) {
    if (minutesPerDay < 60) return 'Rata-rata $minutesPerDay mnt/hari';
    final hours = (minutesPerDay / 60).toStringAsFixed(1).replaceAll('.', ',');
    return 'Rata-rata $hours jam/hari';
  }

  @override
  String get whatsappNote => 'Nggak dibekukan — jalur komunikasimu tetap terbuka.';

  @override
  String get unlockCapReached => 'Batas buka-berbayar hari ini sudah tercapai. Besok segar lagi, dan tarik napas sebentar selalu gratis.';
  @override
  String get earnedCoinsOnly => 'Buka waktu hanya memakai koin hasil latihan, bukan koin yang dibeli.';
  @override
  String get notEnoughEarnedCoins => 'Koin hasil latihanmu belum cukup. Tarik napas dulu (gratis), atau latihan untuk mengumpulkan koin.';
  @override
  String waitSeconds(int seconds) => 'Tunggu $seconds dtk';
  @override
  String unlocksLeftToday(int left) => 'Sisa $left kali buka-berbayar hari ini';

  @override
  String get lockInactiveNotice => 'Kunci Aplikasi Beku sedang tidak aktif karena izin Aksesibilitas Riung mati. Android mematikannya kalau Riung di-Force Stop atau diperbarui.';
  @override
  String get lockInactiveAction => 'Aktifkan';
  @override
  String get lockNotifTitle => 'Aplikasi Beku aktif';
  @override
  String get lockNotifBody => 'Riung menjaga batas aplikasi yang kamu pilih.';
  @override
  String get lockTitle => 'Kunci saat batas tercapai';
  @override
  String get lockOnBody => 'Aplikasi yang melewati batas ditutup oleh Riung. Kamu tetap bisa tarik napas dulu atau membuka waktu dengan koin.';
  @override
  String get lockOffBody => 'Riung cuma mengingatkan, aplikasinya tetap bisa dibuka.';
  @override
  String get lockNeedsPermission => 'Kunci butuh izin Aksesibilitas Riung sebelum bisa aktif.';
  @override
  String get grantPermission => 'Beri izin';
  @override
  String get accessibilityTitle => 'Aktifkan kunci';
  @override
  String get accessibilityHeadline => 'Kunci butuh izin Aksesibilitas Riung';
  @override
  String get accessibilityBody => 'Android baru bisa menjaga kunci tetap hidup (bahkan kalau Riung digeser dari recents) lewat izin ini. Izinnya terdengar besar, jadi ini batasnya dengan jujur. Kamu yang memutuskan.';
  @override
  String get accessibilityReadTitle => 'YANG RIUNG BACA';
  @override
  List<String> get accessibilityReadItems => const ['Cuma nama aplikasi yang kamu bekukan saat dibuka, untuk menampilkan layar jeda ketika batasnya tercapai', 'Tidak ada yang dikirim ke mana pun, semuanya di perangkatmu'];
  @override
  List<String> get accessibilityCannotItems => const ['Isi layar, chat, foto, atau apa yang kamu ketik (izin baca-isi-layar sengaja dimatikan)', 'Aplikasi lain di luar daftar yang kamu bekukan'];
  @override
  String get accessibilityRevoke => 'Caranya: tekan tombol di bawah, pilih Riung di daftar Aksesibilitas, lalu nyalakan. Kamu bisa mematikannya kapan pun di sana, atau matikan kuncinya di Pengaturan Aplikasi Beku.';
  @override
  String get openAccessibilitySettings => 'Buka pengaturan Aksesibilitas';

  @override
  String limitReachedChip(String appName, int usage) => '$appName · $usage mnt hari ini, batasmu tercapai';
  @override
  String get interstitialTitle => 'Si Kabut yang ngajak scroll, bukan kamu';
  @override
  String get interstitialBody => 'Jempolmu jalan sendiri, kan? Itu refleks, bukan pilihan. Yuk kembalikan jadi pilihan, jeda dulu satu menit.';
  @override
  String get interstitialNote => 'Si Kabut memang sudah jinak, tapi kadang dia mampir lagi. Itu normal.';
  @override
  String get breatheFree => 'Tarik napas 1 menit dulu · gratis';
  @override
  String unlockMoreCoins(int coins) => 'Buka 10 menit lagi · $coins koin';

  @override
  String get breathIn => 'Tarik napas';
  @override
  String get breathHold => 'Tahan';
  @override
  String get breathOut => 'Hembuskan';
  @override
  String breatheHeader(String? appName) => appName != null ? '$appName · napas dulu' : 'Jeda napas';
  @override
  String secondsLeft(int seconds) => '$seconds detik lagi';
  @override
  String get breatheHint => 'Nggak perlu buru-buru. Ikuti aja iramanya.';

  @override
  String get postKicker => '1 MENIT SELESAI · KABUTNYA MENIPIS';
  @override
  String get postTitle => 'Masih mau lanjut scroll?';
  @override
  String get postBody => 'Boleh banget, bedanya sekarang itu keputusanmu, bukan refleks. Dua-duanya pilihan yang sadar.';
  @override
  String closeApp(String? appName) => appName != null ? 'Tutup $appName, lanjut hariku' : 'Sudah cukup, lanjut hariku';
  @override
  String unlockShortCoins(int coins) => 'Buka 10 menit · $coins koin';
  @override
  String get noWrongAnswer => 'Nggak ada jawaban yang salah di sini.';

  @override
  String get permissionTitle => 'Satu izin dulu';
  @override
  String get permissionHeadline => 'Riung perlu izin "Akses data penggunaan"';
  @override
  String get permissionBody => 'Ini izin Android buat tahu aplikasi mana yang lagi terbuka dan berapa lama, cuma itu, dan kami mau jujur soal batasnya.';
  @override
  String get readTitle => 'YANG RIUNG BACA';
  @override
  List<String> get readItems => const ['Aplikasi mana yang kamu buka, dan berapa menit', 'Hanya untuk aplikasi yang kamu pilih sendiri'];
  @override
  String get cannotSeeTitle => 'YANG RIUNG NGGAK BISA LIHAT';
  @override
  List<String> get cannotSeeItems => const ['Isi layarmu, chat, foto, atau apa yang kamu tonton', 'Data ini nggak pernah keluar dari perangkatmu'];
  @override
  String get permissionRevoke => 'Bisa dicabut kapan pun di Pengaturan Android, Aplikasi Beku tinggal berhenti, fitur lain tetap jalan.';
  @override
  String get openAndroidSettings => 'Buka pengaturan Android';

  @override
  String get today => 'HARI INI';
  @override
  String scrollMinutes(int minutes) => '$minutes mnt scroll';
  @override
  String underLimit(int minutes) => '$minutes menit di bawah total batasmu';
  @override
  String get totalLimitReached => 'Batas totalmu sudah tercapai hari ini';
  @override
  String get perApp => 'PER APLIKASI';
  @override
  String usedMinutes(int used) => '$used mnt ';
  @override
  String get limitReachedInline => '· batas tercapai';
  @override
  String ofLimit(int limit) => '/ $limit mnt';
  @override
  String breathsTaken(int count) => '$count×';
  @override
  String get breathsLabel => 'jeda napas diambil';
  @override
  String get coinsLabel => 'koin buat buka waktu';
  @override
  String streakDays(int days) => '$days hari';
  @override
  String get streakLabel => 'di bawah batas beruntun';
  @override
  String get didYouKnowText =>
      'Jeda 60 detik sebelum membuka aplikasi terbukti memutus scroll otomatis, itulah kenapa napas selalu jadi pilihan pertama di sini.';
  @override
  String get didYouKnowSource => 'Riset kebiasaan digital';
  @override
  String get emptyTitle => 'Belum ada aplikasi dibekukan';
  @override
  String get emptyBody => 'Pilih aplikasi yang suka nyedot waktumu, kamu yang tentukan batasnya.';
  @override
  String get setupApps => 'Atur aplikasi';

  @override
  String get setupHeadline => 'Aplikasi mana yang suka nyedot waktumu?';
  @override
  String get setupBody => 'Pilih aplikasinya dan batas harianmu. Lewat batas, Riung meminta kamu jeda sebentar dulu.';
  @override
  String get dailyLimit => 'Batas harian';
  @override
  String get pickAtLeastOne => 'Pilih minimal satu aplikasi';
  @override
  String freezeCount(int count) => 'Bekukan $count aplikasi';

  @override
  String get unlockSectionTitle => 'Buka Waktu Scroll';
  @override
  String get unlockSectionBody => 'Waktu ekstra buat aplikasi yang dibekukan, berlaku hari ini saja, sisa batas besok tetap segar.';
  @override
  String get whichApp => 'Buat aplikasi mana?';
  @override
  String minutesFull(int minutes) => '$minutes menit';
  @override
  String get forOneApp => 'untuk satu aplikasi pilihanmu';
  @override
  String get bundles => 'Bundel';
  @override
  String get relaxedTitle => 'Sesi santai';
  @override
  String get relaxedSub => 'Instagram 15 mnt + TikTok 15 mnt';
  @override
  String get allSocialTitle => 'Semua sosmed';
  @override
  String get allSocialSub => '30 mnt untuk tiap aplikasi sosmedmu';
  @override
  String saveBadge(int percent) => 'HEMAT $percent%';
  @override
  String get unlocked => 'Waktu scroll terbuka.';
  @override
  String get coinsChanged => 'Koinnya keburu berubah, coba lagi.';
  @override
  String get relaxedNeedsApps => 'Bundel ini butuh Instagram & TikTok aktif di Aplikasi Beku.';
  @override
  String get relaxedUnlocked => 'Waktu scroll terbuka untuk keduanya.';
  @override
  String get socialNeedsApp => 'Bundel ini butuh minimal satu aplikasi sosmed aktif di Aplikasi Beku.';
  @override
  String get socialUnlocked => 'Waktu scroll terbuka untuk semua sosmed.';
  @override
  String itemMinutes(int minutes, String? appName) => '$minutes menit${appName != null ? ' · $appName' : ''}';
  @override
  String get itemRelaxed => 'Sesi santai · IG + TikTok 15 mnt';
  @override
  String get itemAllSocial => 'Semua sosmed · 30 mnt tiap aplikasi';
}

class AppbekuStringsEn extends AppbekuStrings {
  const AppbekuStringsEn();

  @override
  String get title => 'Frozen Apps';
  @override
  String get notEnoughCoins => 'You do not have enough coins yet.';
  @override
  String get footerNote => 'Riung never holds you without a way out: a short breath is free, and the lock can be turned off anytime in settings.';
  @override
  String minutesShort(int minutes) => '$minutes min';

  @override
  String appUsageAverage(int minutesPerDay) {
    if (minutesPerDay < 60) return 'Average $minutesPerDay min/day';
    final hours = (minutesPerDay / 60).toStringAsFixed(1);
    return 'Average $hours hrs/day';
  }

  @override
  String get whatsappNote => 'Not frozen, your line of communication stays open.';

  @override
  String get unlockCapReached => 'Today\'s paid-unlock limit is reached. It refreshes tomorrow, and a short breath is always free.';
  @override
  String get earnedCoinsOnly => 'Unlocking time only uses coins earned from practice, not purchased coins.';
  @override
  String get notEnoughEarnedCoins => 'Your practice coins are not enough yet. Take a breath first (free), or practice to collect coins.';
  @override
  String waitSeconds(int seconds) => 'Wait $seconds s';
  @override
  String unlocksLeftToday(int left) => '$left paid unlocks left today';

  @override
  String get lockInactiveNotice => 'The Frozen Apps lock is not active because Riung\'s Accessibility permission is off. Android turns it off when Riung is force-stopped or updated.';
  @override
  String get lockInactiveAction => 'Turn on';
  @override
  String get lockNotifTitle => 'Frozen Apps is active';
  @override
  String get lockNotifBody => 'Riung is keeping the limits of the apps you chose.';
  @override
  String get lockTitle => 'Lock when the limit is reached';
  @override
  String get lockOnBody => 'Apps past their limit are closed by Riung. You can still take a breath first or unlock time with coins.';
  @override
  String get lockOffBody => 'Riung only reminds you, the app can still be opened.';
  @override
  String get lockNeedsPermission => "The lock needs Riung's Accessibility permission before it can be active.";
  @override
  String get grantPermission => 'Grant permission';
  @override
  String get accessibilityTitle => 'Turn on the lock';
  @override
  String get accessibilityHeadline => "The lock needs Riung's Accessibility permission";
  @override
  String get accessibilityBody => 'Only this permission lets Android keep the lock alive (even if Riung is swiped away from recents). It sounds big, so here are its honest limits. You decide.';
  @override
  String get accessibilityReadTitle => 'WHAT RIUNG READS';
  @override
  List<String> get accessibilityReadItems => const ['Only the name of an app you froze when it opens, to show the pause screen once its limit is reached', 'Nothing is sent anywhere, it all stays on your device'];
  @override
  List<String> get accessibilityCannotItems => const ['Your screen content, chats, photos, or what you type (the read-screen-content permission is deliberately off)', 'Any app outside the list you froze'];
  @override
  String get accessibilityRevoke => 'How: tap the button below, pick Riung in the Accessibility list, and switch it on. You can turn it off there anytime, or turn the lock off in Frozen Apps settings.';
  @override
  String get openAccessibilitySettings => 'Open Accessibility settings';

  @override
  String limitReachedChip(String appName, int usage) => '$appName · $usage min today, your limit is reached';
  @override
  String get interstitialTitle => 'It is Si Kabut telling you to scroll, not you';
  @override
  String get interstitialBody => 'Your thumb is moving on its own, right? That is a reflex, not a choice. Let us turn it back into a choice, pause for one minute first.';
  @override
  String get interstitialNote => 'Si Kabut is already tamed, but sometimes it drops by again. That is normal.';
  @override
  String get breatheFree => 'Take a 1-minute breath first · free';
  @override
  String unlockMoreCoins(int coins) => 'Unlock 10 more minutes · $coins coins';

  @override
  String get breathIn => 'Breathe in';
  @override
  String get breathHold => 'Hold';
  @override
  String get breathOut => 'Breathe out';
  @override
  String breatheHeader(String? appName) => appName != null ? '$appName · breathe first' : 'Breathing pause';
  @override
  String secondsLeft(int seconds) => '$seconds seconds left';
  @override
  String get breatheHint => 'No need to rush. Just follow the rhythm.';

  @override
  String get postKicker => '1 MINUTE DONE · THE FOG IS THINNING';
  @override
  String get postTitle => 'Still want to keep scrolling?';
  @override
  String get postBody => 'Totally fine, the difference now is that it is your decision, not a reflex. Both are conscious choices.';
  @override
  String closeApp(String? appName) => appName != null ? 'Close $appName, carry on with my day' : "That's enough, carry on with my day";
  @override
  String unlockShortCoins(int coins) => 'Unlock 10 minutes · $coins coins';
  @override
  String get noWrongAnswer => 'There is no wrong answer here.';

  @override
  String get permissionTitle => 'One permission first';
  @override
  String get permissionHeadline => 'Riung needs the "Usage access" permission';
  @override
  String get permissionBody => 'This is an Android permission to know which app is open and for how long, just that, and we want to be honest about its limits.';
  @override
  String get readTitle => 'WHAT RIUNG READS';
  @override
  List<String> get readItems => const ['Which app you open, and for how many minutes', 'Only for the apps you choose yourself'];
  @override
  String get cannotSeeTitle => 'WHAT RIUNG CANNOT SEE';
  @override
  List<String> get cannotSeeItems => const ['Your screen content, chats, photos, or what you watch', 'This data never leaves your device'];
  @override
  String get permissionRevoke => 'You can revoke it anytime in Android Settings, Frozen Apps simply stops, other features keep working.';
  @override
  String get openAndroidSettings => 'Open Android settings';

  @override
  String get today => 'TODAY';
  @override
  String scrollMinutes(int minutes) => '$minutes min scrolling';
  @override
  String underLimit(int minutes) => '$minutes minutes under your total limit';
  @override
  String get totalLimitReached => 'Your total limit is reached today';
  @override
  String get perApp => 'PER APP';
  @override
  String usedMinutes(int used) => '$used min ';
  @override
  String get limitReachedInline => '· limit reached';
  @override
  String ofLimit(int limit) => '/ $limit min';
  @override
  String breathsTaken(int count) => '$count×';
  @override
  String get breathsLabel => 'breathing pauses taken';
  @override
  String get coinsLabel => 'coins to unlock time';
  @override
  String streakDays(int days) => days == 1 ? '1 day' : '$days days';
  @override
  String get streakLabel => 'under the limit in a row';
  @override
  String get didYouKnowText =>
      'A 60-second pause before opening an app has been shown to break automatic scrolling, which is why breathing is always the first option here.';
  @override
  String get didYouKnowSource => 'Digital habit research';
  @override
  String get emptyTitle => 'No frozen apps yet';
  @override
  String get emptyBody => 'Pick the apps that tend to drain your time, you decide the limit.';
  @override
  String get setupApps => 'Set up apps';

  @override
  String get setupHeadline => 'Which apps tend to drain your time?';
  @override
  String get setupBody => 'Pick the apps and your daily limit. Past the limit, Riung asks you to pause for a moment first.';
  @override
  String get dailyLimit => 'Daily limit';
  @override
  String get pickAtLeastOne => 'Pick at least one app';
  @override
  String freezeCount(int count) => count == 1 ? 'Freeze 1 app' : 'Freeze $count apps';

  @override
  String get unlockSectionTitle => 'Unlock Scroll Time';
  @override
  String get unlockSectionBody => 'Extra time for frozen apps, valid today only, tomorrow\'s limit stays fresh.';
  @override
  String get whichApp => 'For which app?';
  @override
  String minutesFull(int minutes) => '$minutes minutes';
  @override
  String get forOneApp => 'for one app of your choice';
  @override
  String get bundles => 'Bundles';
  @override
  String get relaxedTitle => 'Relaxed session';
  @override
  String get relaxedSub => 'Instagram 15 min + TikTok 15 min';
  @override
  String get allSocialTitle => 'All social media';
  @override
  String get allSocialSub => '30 min for each of your social apps';
  @override
  String saveBadge(int percent) => 'SAVE $percent%';
  @override
  String get unlocked => 'Scroll time unlocked.';
  @override
  String get coinsChanged => 'Your coins changed in the meantime, please try again.';
  @override
  String get relaxedNeedsApps => 'This bundle needs Instagram & TikTok active in Frozen Apps.';
  @override
  String get relaxedUnlocked => 'Scroll time unlocked for both.';
  @override
  String get socialNeedsApp => 'This bundle needs at least one social app active in Frozen Apps.';
  @override
  String get socialUnlocked => 'Scroll time unlocked for all social apps.';
  @override
  String itemMinutes(int minutes, String? appName) => '$minutes minutes${appName != null ? ' · $appName' : ''}';
  @override
  String get itemRelaxed => 'Relaxed session · IG + TikTok 15 min';
  @override
  String get itemAllSocial => 'All social · 30 min per app';
}
