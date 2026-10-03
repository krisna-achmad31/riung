/// Teks fitur Profil: profil, pengaturan, bantuan krisis, ekspor/hapus akun,
/// PIN jurnal, kalender latihan, kebijakan privasi, langganan, notifikasi.
abstract class ProfilStrings {
  const ProfilStrings();

  // ── Tab Profil ──
  String get title;
  String get defaultName;
  String get levelPremium;
  String get levelNovice;
  String joined(String date);
  String get statStreak;
  String get statCoins;
  String get statTamed;
  String get betterMeTitle;
  String get betterMeSub;
  String get vaultTitle;
  String vaultSub(int tamed);
  String get calendarTitle;
  String get calendarSub;
  String get shopTitle;
  String get shopSub;
  String get shopBadge;
  String get premiumTitle;
  String get premiumSubActive;
  String get premiumSubInactive;
  String get notifTitle;
  String get notifSub;
  String get crisisTitle;
  String get crisisSub;

  // ── Pengaturan ──
  String get settingsTitle;
  String get sectionAccount;
  String get sectionApp;
  String get sectionSupport;
  String get emailTitle;
  String get emailNotLinked;
  String alreadySignedIn(String email);
  String get changeNameAvatar;
  String get journalLock;
  String get frozenApps;
  String get subscriptionRow;
  String get activeBadge;
  String get downloadData;
  String get privacyPolicy;
  String get disclaimer;
  String get signOut;
  String get deleteAccount;
  String get signOutTitle;
  String get signOutBody;

  // ── Bantuan krisis ──
  String get crisisScreenTitle;
  String get crisisIntro;
  String get crisisEmergencyLabel;
  String get crisisMinistry;
  String get crisisCallButton;
  String get crisisPrivacyNote;
  String get sejiwaSub;
  String get intoTheLightSub;
  String get ipkSub;
  String get actionCall;
  String get actionOpenSite;
  String get actionSearch;

  // ── Edit profil ──
  String get editTitle;
  String get nicknameLabel;
  String get pickAvatar;
  String get saving;

  // ── Ekspor data ──
  String get exportIntro;
  String get exportCopy;
  String get exportCopied;
  String get exportNote;

  // ── Hapus akun ──
  String get deleteConfirmTitle;
  String get deleteConfirmBody;
  String get deletePermanent;
  String get deleteHeading;
  String deleteBody(int coins);
  String get deleteHint;
  String get deleteBack;
  String get deleting;
  String get deleteYes;

  // ── PIN jurnal ──
  String get pinChange;
  String get pinBiometric;

  // ── Kalender latihan ──
  String get calendarScreenTitle;
  List<String> get weekdayShort;
  List<String> get monthNames;
  String daysCount(int days);
  String get streakNow;
  String get streakBest;
  String get thisWeek;
  String get legendFull;
  String get legendPracticed;
  String get legendEmpty;
  String get calendarNote;

  // ── Kebijakan privasi ──
  String get privacyJournalTitle;
  String get privacyJournalBody;
  String get privacySyncTitle;
  String get privacySyncBody;
  String get privacyCrisisTitle;
  String get privacyCrisisBody;
  String get privacyFrozenTitle;
  String get privacyFrozenBody;
  String get privacyDataTitle;
  String get privacyDataBody;
  String get privacyDeleteTitle;
  String get privacyDeleteBody;

  // ── Langganan ──
  String get subTitle;
  String get planMonthly;
  String get planYearly;
  String planTitle(String plan);
  String get activeUntil;
  String get autoRenew;
  String get statusRenewsSoon;
  String get expiredTitle;
  String get expiredBody;
  String get restorePurchases;
  String get subscribeAgain;
  String get restoreChecking;
  String get dailyCoinsTitle;
  String dailyCoinsBody(int coins);
  String claimDaily(int coins);
  String get claimedToday;
  String get dailyCoinsNote;
  String claimedSnack(int coins);
  String get switchYearlyTitle;
  String switchYearlyBody(int paidMonths, int coins);
  String get switchYearly;
  String priceVia(String price, bool monthly);
  String get whatYouGet;
  List<String> get subBenefits;
  String get manageSub;
  String get cancelNote;
  String get notSubscribed;
  String get notSubscribedBody;
  String get viewPremium;

  // ── Notifikasi ──
  String get notifScreenTitle;
  String get notifIntro;
  String get notifCheckinTitle;
  String get notifCheckinSub;
  String get notifAffirmationTitle;
  String get notifAffirmationSub;
  String get notifSleepTitle;
  String get notifSleepSub;
  String get notifTicketTitle;
  String get notifTicketSub;
  String get notifNewsTitle;
  String get notifNewsSub;
  String get notifQuiet;
}

class ProfilStringsId extends ProfilStrings {
  const ProfilStringsId();

  @override
  String get title => 'Profil';
  @override
  String get defaultName => 'Kamu';
  @override
  String get levelPremium => 'Riung Premium';
  @override
  String get levelNovice => 'Penjinak pemula';
  @override
  String joined(String date) => 'Bergabung $date';
  @override
  String get statStreak => 'hari streak';
  @override
  String get statCoins => 'koin';
  @override
  String get statTamed => 'jinak';
  @override
  String get betterMeTitle => 'Better Me';
  @override
  String get betterMeSub => 'Program latihan 22 sesi';
  @override
  String get vaultTitle => 'Brankas monster';
  @override
  String vaultSub(int tamed) => '$tamed dari 7 jinak';
  @override
  String get calendarTitle => 'Kalender latihan';
  @override
  String get calendarSub => 'Riwayat check-in & jurnalmu';
  @override
  String get shopTitle => 'Toko';
  @override
  String get shopSub => 'Sesi fokus, kosmetik, isi koin';
  @override
  String get shopBadge => 'BARU';
  @override
  String get premiumTitle => 'Riung Premium';
  @override
  String get premiumSubActive => 'Aktif';
  @override
  String get premiumSubInactive => 'Buka semua latihan penjinakan';
  @override
  String get notifTitle => 'Notifikasi';
  @override
  String get notifSub => 'Atur pengingat harian';
  @override
  String get crisisTitle => 'Butuh bantuan sekarang';
  @override
  String get crisisSub => 'Layanan krisis, selalu bisa diakses';

  @override
  String get settingsTitle => 'Pengaturan';
  @override
  String get sectionAccount => 'AKUN';
  @override
  String get sectionApp => 'APLIKASI';
  @override
  String get sectionSupport => 'DUKUNGAN';
  @override
  String get emailTitle => 'Email';
  @override
  String get emailNotLinked => 'Belum terhubung, ketuk buat daftar';
  @override
  String alreadySignedIn(String email) => 'Kamu sudah masuk dengan $email';
  @override
  String get changeNameAvatar => 'Ganti nama & avatar';
  @override
  String get journalLock => 'Kunci jurnal & PIN';
  @override
  String get frozenApps => 'Aplikasi Beku';
  @override
  String get subscriptionRow => 'Langganan Riung Premium';
  @override
  String get activeBadge => 'AKTIF';
  @override
  String get downloadData => 'Unduh semua dataku';
  @override
  String get privacyPolicy => 'Kebijakan privasi';
  @override
  String get disclaimer =>
      'Riung adalah alat bantu kesejahteraan mental berbasis latihan CBT, bukan pengganti diagnosis, terapi, atau penanganan profesional. Kalau kondisimu terasa berat atau membahayakan, hubungi profesional atau layanan krisis di halaman "Butuh bantuan sekarang".';
  @override
  String get signOut => 'Keluar akun';
  @override
  String get deleteAccount => 'Hapus akun';
  @override
  String get signOutTitle => 'Keluar akun?';
  @override
  String get signOutBody => 'Progresmu tersimpan, kamu bisa masuk lagi kapan saja dengan akun yang sama.';

  @override
  String get crisisScreenTitle => 'Butuh bantuan sekarang';
  @override
  String get crisisIntro =>
      'Kalau kamu sedang dalam kondisi yang terasa nggak tertahankan, atau punya pikiran menyakiti diri, kamu berhak dibantu manusia sungguhan, secepatnya. Ini bukan hal yang harus kamu hadapi sendirian.';
  @override
  String get crisisEmergencyLabel => 'DARURAT · 24 JAM';
  @override
  String get crisisMinistry => 'Layanan Kesehatan Jiwa Kemenkes';
  @override
  String get crisisCallButton => 'Telepon 119 ext. 8';
  @override
  String get crisisPrivacyNote =>
      'Riung nggak mencatat atau membagikan bahwa kamu membuka halaman ini. Streak dan datamu nggak terpengaruh.';
  @override
  String get sejiwaSub => 'Konseling psikologis · 119 ext. 8';
  @override
  String get intoTheLightSub => 'Dukungan sebaya, chat dan email';
  @override
  String get ipkSub => 'Direktori psikolog klinis terdekat';
  @override
  String get actionCall => 'Telepon';
  @override
  String get actionOpenSite => 'Buka situs';
  @override
  String get actionSearch => 'Cari';

  @override
  String get editTitle => 'Profil & avatar';
  @override
  String get nicknameLabel => 'Nama panggilan';
  @override
  String get pickAvatar => 'Pilih avatar';
  @override
  String get saving => 'Menyimpan...';

  @override
  String get exportIntro =>
      'Ringkasan datamu dalam format JSON. Isi jurnal nggak ikut karena tersimpan terenkripsi di perangkatmu.';
  @override
  String get exportCopy => 'Salin ke clipboard';
  @override
  String get exportCopied => 'Tersalin.';
  @override
  String get exportNote =>
      'Isi jurnal tidak disertakan — tersimpan terenkripsi di perangkatmu, buka lewat Jurnal di app.';

  @override
  String get deleteConfirmTitle => 'Yakin sekali?';
  @override
  String get deleteConfirmBody =>
      'Ini langkah terakhir. Setelah ini semua datamu hilang permanen dan nggak bisa dibatalkan.';
  @override
  String get deletePermanent => 'Hapus permanen';
  @override
  String get deleteHeading => 'Yakin mau menghapus akunmu?';
  @override
  String deleteBody(int coins) =>
      'Semua jurnal, progres monster, dan $coins koinmu akan dihapus permanen. Ini nggak bisa dibatalkan.';
  @override
  String get deleteHint =>
      'Kalau alasannya biaya, paket bulanan bisa dijeda tanpa kehilangan data. Kalau aplikasinya terasa nggak membantu, kami mau dengar, ceritakan ke tim Riung.';
  @override
  String get deleteBack => 'Nggak jadi, kembali';
  @override
  String get deleting => 'Menghapus...';
  @override
  String get deleteYes => 'Ya, hapus akunku';

  @override
  String get pinChange => 'Ganti PIN';
  @override
  String get pinBiometric => 'Buka pakai biometrik';

  @override
  String get calendarScreenTitle => 'Kalender latihan';
  @override
  List<String> get weekdayShort => const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  @override
  List<String> get monthNames => const [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
  @override
  String daysCount(int days) => '$days hari';
  @override
  String get streakNow => 'streak sekarang';
  @override
  String get streakBest => 'streak terbaik';
  @override
  String get thisWeek => 'minggu ini';
  @override
  String get legendFull => 'Hari penuh, check-in + jurnal';
  @override
  String get legendPracticed => 'Latihan dilakukan';
  @override
  String get legendEmpty => 'Hari kosong';
  @override
  String get calendarNote => 'Hari kosong bukan kegagalan, kalender ini catatan, bukan rapor.';

  @override
  String get privacyJournalTitle => 'Jurnal & catatan pribadimu';
  @override
  String get privacyJournalBody =>
      'Isi jurnal tersimpan terenkripsi langsung di perangkatmu, dikunci PIN/biometrik. Kami tidak pernah mengirim atau menyimpan isinya di server.';
  @override
  String get privacySyncTitle => 'Yang tersinkron ke server';
  @override
  String get privacySyncBody =>
      'Cuma profil (nama, avatar), saldo koin, streak, progres monster, dan status Premium — supaya bisa lanjut di perangkat lain. Semuanya dilindungi aturan akses yang cuma bisa dibaca/ditulis akunmu sendiri.';
  @override
  String get privacyCrisisTitle => 'Halaman krisis';
  @override
  String get privacyCrisisBody =>
      'Membuka "Butuh bantuan sekarang" tidak pernah dicatat atau dilaporkan ke mana pun. Streak dan datamu tidak terpengaruh.';
  @override
  String get privacyFrozenTitle => 'Aplikasi Beku';
  @override
  String get privacyFrozenBody =>
      'Riung memakai izin "Akses data penggunaan" untuk membaca durasi pemakaian aplikasi yang kamu pilih sendiri. Kalau kamu menyalakan kunci, Riung juga memakai layanan Aksesibilitas HANYA untuk mengetahui aplikasi mana yang sedang terbuka di antara aplikasi beku pilihanmu, lalu membawamu kembali ke Riung saat batas terlewat. Riung tidak membaca isi layar, ketikan, atau kata sandi. Semuanya diproses di perangkat, tidak pernah dikirim ke server, dan bisa dimatikan kapan saja di Pengaturan Aksesibilitas.';
  @override
  String get privacyDataTitle => 'Laporan, kepribadian & data tidur';
  @override
  String get privacyDataBody =>
      'Laporan refleksi dan hasil tes kepribadianmu dihitung di perangkat dari check-in dan metadata jurnal (tanggal, mood, tag), tanpa membaca isi jurnal, dan tidak dikirim ke server. Kalau kamu menghubungkan data tidur, Riung membaca durasi tidur dari Health Connect hanya untuk laporan itu, tidak menyimpannya, dan kamu bisa mencabut izinnya kapan saja.';
  @override
  String get privacyDeleteTitle => 'Hapus akun';
  @override
  String get privacyDeleteBody =>
      'Menghapus akun akan menghapus profil, wallet, dan progres monstermu dari server, serta semua data di perangkat ini (jurnal, check-in, hasil tes). Ini permanen dan tidak bisa dibatalkan.';

  @override
  String get subTitle => 'Langgananku';
  @override
  String get planMonthly => 'Bulanan';
  @override
  String get planYearly => 'Tahunan';
  @override
  String planTitle(String plan) => 'Riung Premium · $plan';
  @override
  String get activeUntil => 'Aktif sampai ';
  @override
  String get autoRenew => ' · diperpanjang otomatis';
  @override
  String get statusRenewsSoon => 'Menunggu perpanjangan. Kalau gagal, cek metode pembayaranmu di Google Play.';
  @override
  String get expiredTitle => 'Langgananmu sudah berakhir';
  @override
  String get expiredBody => 'Kalau kamu sudah memperpanjang di Google Play, ketuk Pulihkan pembelian. Semua catatan dan progresmu tetap aman.';
  @override
  String get restorePurchases => 'Pulihkan pembelian';
  @override
  String get subscribeAgain => 'Berlangganan lagi';
  @override
  String get restoreChecking => 'Memeriksa pembelianmu di Google Play…';
  @override
  String get dailyCoinsTitle => 'Koin harian tahunan';
  @override
  String dailyCoinsBody(int coins) => 'Ambil $coins koin setiap hari selama langganan tahunanmu aktif. Hari yang terlewat tidak menumpuk, dan tidak ada yang perlu dikejar.';
  @override
  String claimDaily(int coins) => 'Ambil +$coins koin';
  @override
  String get claimedToday => 'Sudah diambil hari ini';
  @override
  String get dailyCoinsNote => 'Koin ini tidak bisa dipakai membuka waktu aplikasi beku.';
  @override
  String claimedSnack(int coins) => '+$coins koin masuk. Sampai besok!';
  @override
  String get switchYearlyTitle => 'Lebih hemat dengan paket tahunan';
  @override
  String switchYearlyBody(int paidMonths, int coins) => 'Bayar $paidMonths bulan untuk 12 bulan, plus $coins koin setiap hari.';
  @override
  String get switchYearly => 'Lihat paket tahunan';
  @override
  String priceVia(String price, bool monthly) => 'Rp$price/${monthly ? 'bulan' : 'tahun'} via Google Play';
  @override
  String get whatYouGet => 'YANG KAMU DAPAT';
  @override
  List<String> get subBenefits => const [
        'Semua meditasi & cerita tidur (120+)',
        'Panduan jurnal CBT lengkap',
        'Unduhan offline tanpa batas',
        'Laporan Better Me bulanan',
      ];
  @override
  String get manageSub => 'Kelola / batalkan perpanjangan';
  @override
  String get cancelNote =>
      'Kalau dibatalkan, Riung Premium tetap aktif sampai akhir periode. Progres, jurnal, dan monstermu nggak hilang.';
  @override
  String get notSubscribed => 'Belum berlangganan Riung Premium';
  @override
  String get notSubscribedBody => 'Buka semua latihan penjinakan, meditasi, dan cerita tidur.';
  @override
  String get viewPremium => 'Lihat Riung Premium';

  @override
  String get notifScreenTitle => 'Notifikasi';
  @override
  String get notifIntro =>
      'Riung nggak akan spam. Semua pengingat maksimal sekali per hari, dan bisa dimatikan satu-satu.';
  @override
  String get notifCheckinTitle => 'Check-in pagi';
  @override
  String get notifCheckinSub => '"Gimana perasaanmu hari ini?" · 07:00';
  @override
  String get notifAffirmationTitle => 'Afirmasi harian';
  @override
  String get notifAffirmationSub => 'Satu kalimat dari koleksimu · 07:00';
  @override
  String get notifSleepTitle => 'Pengingat tidur';
  @override
  String get notifSleepSub => '30 menit sebelum jam tidurmu';
  @override
  String get notifTicketTitle => 'Tiket serangan';
  @override
  String get notifTicketSub => 'Saat monster sedang lengah';
  @override
  String get notifNewsTitle => 'Kabar dari Riung';
  @override
  String get notifNewsSub => 'Fitur baru dan konten baru, jarang banget';
  @override
  String get notifQuiet => 'Mode hening otomatis 22:30-06:00, mengikuti target tidurmu.';
}

class ProfilStringsEn extends ProfilStrings {
  const ProfilStringsEn();

  @override
  String get title => 'Profile';
  @override
  String get defaultName => 'You';
  @override
  String get levelPremium => 'Riung Premium';
  @override
  String get levelNovice => 'Novice tamer';
  @override
  String joined(String date) => 'Joined $date';
  @override
  String get statStreak => 'day streak';
  @override
  String get statCoins => 'coins';
  @override
  String get statTamed => 'tamed';
  @override
  String get betterMeTitle => 'Better Me';
  @override
  String get betterMeSub => '22-session training program';
  @override
  String get vaultTitle => 'Monster vault';
  @override
  String vaultSub(int tamed) => '$tamed of 7 tamed';
  @override
  String get calendarTitle => 'Practice calendar';
  @override
  String get calendarSub => 'Your check-in & journal history';
  @override
  String get shopTitle => 'Shop';
  @override
  String get shopSub => 'Focus sessions, cosmetics, top up coins';
  @override
  String get shopBadge => 'NEW';
  @override
  String get premiumTitle => 'Riung Premium';
  @override
  String get premiumSubActive => 'Active';
  @override
  String get premiumSubInactive => 'Unlock all taming exercises';
  @override
  String get notifTitle => 'Notifications';
  @override
  String get notifSub => 'Manage daily reminders';
  @override
  String get crisisTitle => 'Need help right now';
  @override
  String get crisisSub => 'Crisis services, always available';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get sectionAccount => 'ACCOUNT';
  @override
  String get sectionApp => 'APP';
  @override
  String get sectionSupport => 'SUPPORT';
  @override
  String get emailTitle => 'Email';
  @override
  String get emailNotLinked => 'Not linked yet, tap to sign up';
  @override
  String alreadySignedIn(String email) => 'You are already signed in as $email';
  @override
  String get changeNameAvatar => 'Change name & avatar';
  @override
  String get journalLock => 'Journal lock & PIN';
  @override
  String get frozenApps => 'Frozen Apps';
  @override
  String get subscriptionRow => 'Riung Premium subscription';
  @override
  String get activeBadge => 'ACTIVE';
  @override
  String get downloadData => 'Download all my data';
  @override
  String get privacyPolicy => 'Privacy policy';
  @override
  String get disclaimer =>
      'Riung is a mental wellbeing tool built on CBT-based exercises. It is not a substitute for diagnosis, therapy, or professional care. If things feel heavy or unsafe, please reach out to a professional or a crisis service on the "Need help right now" page.';
  @override
  String get signOut => 'Sign out';
  @override
  String get deleteAccount => 'Delete account';
  @override
  String get signOutTitle => 'Sign out?';
  @override
  String get signOutBody => 'Your progress is saved. You can sign back in anytime with the same account.';

  @override
  String get crisisScreenTitle => 'Need help right now';
  @override
  String get crisisIntro =>
      'If things feel unbearable, or you are having thoughts of hurting yourself, you deserve help from a real person, as soon as possible. This is not something you have to face alone.';
  @override
  String get crisisEmergencyLabel => 'EMERGENCY · 24 HOURS';
  @override
  String get crisisMinistry => 'Ministry of Health Mental Health Service';
  @override
  String get crisisCallButton => 'Call 119 ext. 8';
  @override
  String get crisisPrivacyNote =>
      'Riung does not record or share that you opened this page. Your streak and data are not affected.';
  @override
  String get sejiwaSub => 'Psychological counseling · 119 ext. 8';
  @override
  String get intoTheLightSub => 'Peer support, chat and email';
  @override
  String get ipkSub => 'Directory of nearby clinical psychologists';
  @override
  String get actionCall => 'Call';
  @override
  String get actionOpenSite => 'Open site';
  @override
  String get actionSearch => 'Search';

  @override
  String get editTitle => 'Profile & avatar';
  @override
  String get nicknameLabel => 'Nickname';
  @override
  String get pickAvatar => 'Choose avatar';
  @override
  String get saving => 'Saving...';

  @override
  String get exportIntro =>
      'A summary of your data in JSON format. Journal entries are not included because they are stored encrypted on your device.';
  @override
  String get exportCopy => 'Copy to clipboard';
  @override
  String get exportCopied => 'Copied.';
  @override
  String get exportNote =>
      'Journal content is not included — it is stored encrypted on your device, open it through Journal in the app.';

  @override
  String get deleteConfirmTitle => 'Are you absolutely sure?';
  @override
  String get deleteConfirmBody =>
      'This is the last step. After this, all your data is gone permanently and cannot be undone.';
  @override
  String get deletePermanent => 'Delete permanently';
  @override
  String get deleteHeading => 'Really delete your account?';
  @override
  String deleteBody(int coins) =>
      'All your journals, monster progress, and $coins coins will be permanently deleted. This cannot be undone.';
  @override
  String get deleteHint =>
      'If cost is the reason, the monthly plan can be paused without losing data. If the app does not feel helpful, we would love to hear it, tell the Riung team.';
  @override
  String get deleteBack => 'Never mind, go back';
  @override
  String get deleting => 'Deleting...';
  @override
  String get deleteYes => 'Yes, delete my account';

  @override
  String get pinChange => 'Change PIN';
  @override
  String get pinBiometric => 'Unlock with biometrics';

  @override
  String get calendarScreenTitle => 'Practice calendar';
  @override
  List<String> get weekdayShort => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  @override
  List<String> get monthNames => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
  @override
  String daysCount(int days) => days == 1 ? '1 day' : '$days days';
  @override
  String get streakNow => 'current streak';
  @override
  String get streakBest => 'best streak';
  @override
  String get thisWeek => 'this week';
  @override
  String get legendFull => 'Full day, check-in + journal';
  @override
  String get legendPracticed => 'Practice done';
  @override
  String get legendEmpty => 'Empty day';
  @override
  String get calendarNote => 'An empty day is not a failure. This calendar is a record, not a report card.';

  @override
  String get privacyJournalTitle => 'Your journal & private notes';
  @override
  String get privacyJournalBody =>
      'Journal entries are stored encrypted right on your device, locked with a PIN/biometrics. We never send or store their content on a server.';
  @override
  String get privacySyncTitle => 'What syncs to the server';
  @override
  String get privacySyncBody =>
      'Only your profile (name, avatar), coin balance, streak, monster progress, and Premium status, so you can continue on another device. All of it is protected by access rules that only your own account can read or write.';
  @override
  String get privacyCrisisTitle => 'Crisis page';
  @override
  String get privacyCrisisBody =>
      'Opening "Need help right now" is never recorded or reported anywhere. Your streak and data are not affected.';
  @override
  String get privacyFrozenTitle => 'Frozen Apps';
  @override
  String get privacyFrozenBody =>
      'Riung uses the "Usage data access" permission to read how long the apps you choose are used. If you turn on the lock, Riung also uses the Accessibility service ONLY to know which of your chosen frozen apps is open, and brings you back to Riung when the limit is passed. Riung does not read screen content, keystrokes, or passwords. Everything is processed on your device, never sent to a server, and can be turned off any time in Accessibility settings.';
  @override
  String get privacyDataTitle => 'Reports, personality & sleep data';
  @override
  String get privacyDataBody =>
      'Your reflection report and personality results are calculated on your device from check-ins and journal metadata (date, mood, tags), without reading journal content, and are not sent to a server. If you connect sleep data, Riung reads sleep duration from Health Connect only for that report, does not store it, and you can revoke access any time.';
  @override
  String get privacyDeleteTitle => 'Delete account';
  @override
  String get privacyDeleteBody =>
      'Deleting your account removes your profile, wallet, and monster progress from the server, plus all data on this device (journal, check-ins, test results). It is permanent and cannot be undone.';

  @override
  String get subTitle => 'My subscription';
  @override
  String get planMonthly => 'Monthly';
  @override
  String get planYearly => 'Yearly';
  @override
  String planTitle(String plan) => 'Riung Premium · $plan';
  @override
  String get activeUntil => 'Active until ';
  @override
  String get autoRenew => ' · renews automatically';
  @override
  String get statusRenewsSoon => 'Waiting for renewal. If it fails, check your payment method in Google Play.';
  @override
  String get expiredTitle => 'Your subscription has ended';
  @override
  String get expiredBody => 'If you already renewed in Google Play, tap Restore purchases. All your notes and progress stay safe.';
  @override
  String get restorePurchases => 'Restore purchases';
  @override
  String get subscribeAgain => 'Subscribe again';
  @override
  String get restoreChecking => 'Checking your purchases on Google Play…';
  @override
  String get dailyCoinsTitle => 'Yearly daily coins';
  @override
  String dailyCoinsBody(int coins) => 'Claim $coins coins every day while your yearly subscription is active. Missed days do not pile up, and there is nothing to chase.';
  @override
  String claimDaily(int coins) => 'Claim +$coins coins';
  @override
  String get claimedToday => 'Claimed today';
  @override
  String get dailyCoinsNote => 'These coins cannot be used to unlock frozen-app time.';
  @override
  String claimedSnack(int coins) => '+$coins coins added. See you tomorrow!';
  @override
  String get switchYearlyTitle => 'Save more with the yearly plan';
  @override
  String switchYearlyBody(int paidMonths, int coins) => 'Pay $paidMonths months for 12, plus $coins coins every day.';
  @override
  String get switchYearly => 'See the yearly plan';
  @override
  String priceVia(String price, bool monthly) => 'Rp$price/${monthly ? 'month' : 'year'} via Google Play';
  @override
  String get whatYouGet => 'WHAT YOU GET';
  @override
  List<String> get subBenefits => const [
        'All meditations & sleep stories (120+)',
        'Complete CBT journal guides',
        'Unlimited offline downloads',
        'Monthly Better Me report',
      ];
  @override
  String get manageSub => 'Manage / cancel renewal';
  @override
  String get cancelNote =>
      'If you cancel, Riung Premium stays active until the end of the period. Your progress, journals, and monsters are not lost.';
  @override
  String get notSubscribed => 'Not subscribed to Riung Premium';
  @override
  String get notSubscribedBody => 'Unlock all taming exercises, meditations, and sleep stories.';
  @override
  String get viewPremium => 'See Riung Premium';

  @override
  String get notifScreenTitle => 'Notifications';
  @override
  String get notifIntro =>
      'Riung will not spam you. Every reminder is at most once a day, and each one can be turned off separately.';
  @override
  String get notifCheckinTitle => 'Morning check-in';
  @override
  String get notifCheckinSub => '"How are you feeling today?" · 07:00';
  @override
  String get notifAffirmationTitle => 'Daily affirmation';
  @override
  String get notifAffirmationSub => 'One line from your collection · 07:00';
  @override
  String get notifSleepTitle => 'Sleep reminder';
  @override
  String get notifSleepSub => '30 minutes before your bedtime';
  @override
  String get notifTicketTitle => 'Attack ticket';
  @override
  String get notifTicketSub => 'When a monster lets its guard down';
  @override
  String get notifNewsTitle => 'News from Riung';
  @override
  String get notifNewsSub => 'New features and content, very rarely';
  @override
  String get notifQuiet => 'Quiet mode automatically 22:30-06:00, following your sleep target.';
}
