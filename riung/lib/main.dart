import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/firebase_config.dart';
import 'core/l10n/l10n.dart';
import 'core/services/afirmasi_reminder.dart';
import 'core/services/monster_anchor_registry.dart';
import 'core/services/services.dart';
import 'core/services/sleep_reminder.dart';
import 'core/state/state.dart';
import 'core/theme/theme.dart';
import 'core/widgets/widgets.dart';
import 'features/appbeku/screens/appbeku_interstitial_screen.dart';
import 'features/launch/screens/splash_screen.dart';

/// Rute notifikasi lokal ke layar yang sesuai berdasarkan payload — dipakai
/// baik saat notifikasi ditap selagi app berjalan/background
/// (`onDidReceiveNotificationResponse`) maupun saat app baru dibuka lewat
/// tap notifikasi dari kondisi mati total (`getNotificationAppLaunchDetails`
/// di bawah). Cuma payload `appbeku:*` yang butuh navigasi eksplisit —
/// notifikasi pengingat lain cukup membuka app seperti biasa.
void _routeNotificationTap(String? payload) {
  if (payload == null || !payload.startsWith('appbeku:')) return;
  final packageName = payload.substring('appbeku:'.length);
  AppNavigator.key.currentState?.push(
    MaterialPageRoute(builder: (_) => AppBekuInterstitialScreen(packageName: packageName)),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge: latar kaca mengalir sampai belakang status & navigation bar.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);
  // Font dibundel di assets/google_fonts/ (offline-first, CLAUDE.md #5) —
  // jangan unduh saat runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final family in ['PlusJakartaSans', 'BricolageGrotesque']) {
      final text = await rootBundle.loadString('assets/google_fonts/OFL-$family.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
  // Semua desain (`design/*.dc.html`) potret; tanpa kunci ini layar-layar
  // non-scroll overflow begitu HP diputar landscape.
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  // Pre-warm supaya RiungMonster tidak pernah menampilkan frame kosong
  // sebelum anchors.json selesai dibaca.
  await MonsterAnchorRegistry.instance.load();
  for (final language in AppLanguage.values) {
    await initializeDateFormatting(language.intlLocale);
  }
  // shared_preferences aman di-await di sini (cepat, dipakai tiap layar).
  // sqflite (Jurnal/Check-in) sengaja TIDAK dibuka di sini — lazy saat
  // fitur itu benar-benar dipakai, lihat LocalDatabaseService.
  final prefs = await LocalPrefsStore.init();
  // Hasil Kenali Dirimu terenkripsi — didekripsi sekali, lalu dibaca sinkron
  // oleh Beranda/Profil/Brankas (Monster Kebiasaan bangun dari hasil ini).
  await KenaliResultRepository.instance.load(prefs);
  final remoteConfig = RemoteConfigService();
  await remoteConfig.init();
  // Notifikasi lokal bersifat best-effort — dibungkus try/catch supaya
  // kegagalan di sini (mis. platform channel/icon resource bermasalah,
  // pernah benar-benar terjadi & bikin seluruh app gagal render karena
  // exception ini menghentikan `main()` sebelum sempat `runApp`) TIDAK
  // PERNAH mencegah app kebuka sama sekali.
  try {
    final launchPayload = await LocalNotificationService.instance.init(onTap: _routeNotificationTap);
    if (launchPayload != null) {
      // Splash butuh minimal ~2 detik (animasi + load profil, lihat
      // SplashScreen._goNext) sebelum navigator siap menerima push lain —
      // tunggu sedikit lebih lama supaya tidak race dengan navigasi splash.
      Future.delayed(const Duration(seconds: 3), () => _routeNotificationTap(launchPayload));
    }
  } catch (_) {
    // Diam-diam lanjut tanpa notifikasi lokal — lebih baik app kebuka
    // tanpa pengingat daripada app tidak kebuka sama sekali.
  }
  runApp(RiungApp(prefs: prefs, remoteConfig: remoteConfig));
}

/// Root app — merakit layanan Firebase sungguhan (sejak M5: Auth,
/// Firestore, Remote Config, Play Billing — lihat CLAUDE.md M5) dan ke-5
/// notifier global, lalu membagikannya lewat [AppScope]. Jurnal, check-in,
/// dan afirmasi favorit/buatan TETAP lokal murni (di-compose lewat
/// [FirestoreUserRepository] → [LocalUserRepository]) — CLAUDE.md aturan #5.
class RiungApp extends StatefulWidget {
  const RiungApp({
    super.key,
    required this.prefs,
    required this.remoteConfig,
    this.authService,
    this.userRepository,
    this.contentRepository,
    this.walletFunctions,
  });

  final LocalPrefsStore prefs;
  final RemoteConfigService remoteConfig;

  /// Override untuk test/dev — kalau null, dibuat Firebase-backed
  /// sungguhan. Widget test memakai ini untuk suntik Stub/Local supaya
  /// tidak butuh `Firebase.initializeApp()` sungguhan di lingkungan test.
  final AuthService? authService;
  final UserRepository? userRepository;
  final ContentRepository? contentRepository;
  final WalletFunctionsService? walletFunctions;

  @override
  State<RiungApp> createState() => _RiungAppState();
}

class _RiungAppState extends State<RiungApp> {
  late final AuthService _authService;
  late final UserRepository _userRepository;
  late final ContentRepository _contentRepository;
  late final WalletFunctionsService _walletFunctions;
  late final JurnalPinService _pinService;
  late final BillingService _billing;
  late final AnalyticsService _analytics;

  late final AuthNotifier _auth;
  late final WalletNotifier _wallet;
  late final StreakNotifier _streak;
  late final MonsterProgressNotifier _monsterProgress;
  late final SessionNotifier _session;
  late final AppBekuNotifier _appBeku;
  late final LanguageNotifier _language;

  String? _loadedForUid;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? FirebaseAuthService(googleServerClientId: googleServerClientId);
    // Poin 4 — lokal-dulu, cloud-setelah-login: SELAMA ANONIM,
    // wallet/profil/progres monster sepenuhnya lokal (tidak menyentuh
    // Firestore sama sekali), baru mulai sinkron ke cloud begitu
    // user login/link akun. `isAnonymous` di sini dibaca LIVE dari
    // `_authService` tiap dipanggil (bukan snapshot beku), jadi
    // langsung akurat begitu link sukses — lihat AuthNotifier._linkAndMigrate.
    _userRepository = widget.userRepository ??
        FirestoreUserRepository(
          firestore: FirebaseFirestore.instance,
          localDelegate: LocalUserRepository(
            prefs: widget.prefs,
            db: LocalDatabaseService(),
            crypto: JournalCryptoService(),
          ),
          isAnonymous: () => _authService.isAnonymous,
        );
    _contentRepository = widget.contentRepository ?? FirestoreContentRepository(firestore: FirebaseFirestore.instance);
    // LocalWalletFunctionsService dikasih _userRepository yang SAMA
    // (bukan LocalUserRepository baru terpisah) — supaya progres monster
    // yang dibaca/ditulis tameProgress() saat anonim tetap satu sumber
    // kebenaran dengan yang dibaca layar lain lewat _userRepository.
    _walletFunctions = widget.walletFunctions ??
        HybridWalletFunctionsService(
          local: LocalWalletFunctionsService(prefs: widget.prefs, userRepository: _userRepository),
          cloud: FirestoreWalletFunctionsService(firestore: FirebaseFirestore.instance),
          isAnonymous: () => _authService.isAnonymous,
        );
    _pinService = JurnalPinService();

    _auth = AuthNotifier(_authService, userRepository: _userRepository);
    _wallet = WalletNotifier(userRepository: _userRepository, walletFunctions: _walletFunctions, prefs: widget.prefs);
    _streak = StreakNotifier(userRepository: _userRepository);
    _monsterProgress = MonsterProgressNotifier(
      userRepository: _userRepository,
      walletFunctions: _walletFunctions,
    );
    _session = SessionNotifier();
    _appBeku = AppBekuNotifier(prefs: widget.prefs);
    _language = LanguageNotifier(prefs: widget.prefs);
    _appBeku.lockNotifText = () {
      final t = _language.strings.appbeku;
      return (title: t.lockNotifTitle, body: t.lockNotifBody);
    };
    _language.addListener(_appBeku.resyncLock);
    _appBeku.load();
    _analytics = AnalyticsService();
    _billing = BillingService(
      walletFunctions: _walletFunctions,
      userRepository: _userRepository,
      currentUid: () => _auth.uid ?? '',
      analytics: _analytics,
      isAnonymous: () => _authService.isAnonymous,
      onCoinsPurchased: _wallet.recordPurchasedCoins,
    );
    _billing.init();

    _auth.addListener(_onAuthUidChanged);
    _auth.addListener(_maybeRestorePremium);
    _onAuthUidChanged();
    // Fix 3: check-in pagi/misi harian/streak saver — dijadwal ulang tiap
    // kali streak berubah (baik load awal maupun sesudah check-in beneran,
    // lihat StreakNotifier.load & checkInHariIni yang keduanya notifyListeners).
    _streak.addListener(_refreshDailyReminders);
    // Ganti bahasa → teks notifikasi terjadwal ikut diganti.
    _language.addListener(_refreshDailyReminders);
  }

  /// Fix 3: (re)jadwalkan/cancel 3 pengingat harian lokal. Semua di-cancel
  /// begitu user sudah check-in hari itu (sesuai instruksi fix — "semua
  /// notification harus cancel otomatis saat user sudah check-in hari
  /// itu"), lalu otomatis terjadwal lagi besok lewat listener ini saat
  /// [StreakNotifier.load] jalan di hari baru.
  ///
  /// "Misi harian" & "streak saver" tidak punya toggle sendiri di
  /// `NotifikasiScreen` (`design/Profil.dc.html` § Notifikasi cuma
  /// mendefinisikan 5 toggle, tidak ada 2 ini) — selalu aktif, tidak bisa
  /// dimatikan user. "Check-in pagi" toggle asli dihormati di sini & di
  /// `NotifikasiScreen._ubah`.
  Future<void> _refreshDailyReminders() async {
    final notif = _language.strings.notif;
    // Afirmasi harian TIDAK ikut dibatalkan saat user sudah check-in —
    // itu pengingat mandiri dengan jam & toggle-nya sendiri.
    await AfirmasiReminder.refresh(
      prefs: widget.prefs,
      content: _contentRepository,
      users: _userRepository,
      uid: _auth.uid,
      strings: notif,
      afirmasi: _language.strings.afirmasi,
    );
    // Pengingat tidur juga mandiri (jam, hari & switch-nya sendiri).
    await SleepReminder.refresh(prefs: widget.prefs, strings: notif, userName: _auth.profile?.displayName);
    if (_streak.sudahCheckinHariIni) {
      await LocalNotificationService.instance.cancelDailyReminders();
      return;
    }
    final checkinOn = widget.prefs.notifSettingsJson['checkin_pagi'] as bool? ?? true;
    if (checkinOn) {
      await LocalNotificationService.instance.scheduleCheckinPagi(strings: notif);
    } else {
      await LocalNotificationService.instance.cancel(LocalNotificationService.idCheckinPagi);
    }
    final saboteurs = await _contentRepository.getSaboteurs();
    if (saboteurs.isEmpty) return;
    final dominantIds = _auth.profile?.dominantSaboteurs ?? const [];
    final dominant = saboteurs.firstWhere(
      (s) => dominantIds.isNotEmpty && s.id == dominantIds.first,
      orElse: () => saboteurs.first,
    );
    await LocalNotificationService.instance.scheduleMisiHarian(strings: notif, monsterName: dominant.nama);
    await LocalNotificationService.instance.scheduleStreakSaver(strings: notif, streak: _streak.current);
  }

  bool _premiumRestoreTried = false;

  /// Tanpa server, tanggal perpanjangan hanya dicatat saat pembelian. Begitu
  /// lewat tanggal itu, tanya Google Play sekali apakah langganan sudah
  /// diperpanjang (restore memperbarui tanggalnya); kalau tidak, status jadi
  /// kedaluwarsa setelah masa toleransi ([EconomyPremium.graceHari]).
  void _maybeRestorePremium() {
    final profile = _auth.profile;
    if (profile == null || _premiumRestoreTried || !profile.premiumActive) return;
    final renews = profile.premiumRenewsAt;
    if (renews == null || DateTime.now().isBefore(renews)) return;
    _premiumRestoreTried = true;
    _billing.restorePurchases();
  }

  /// Instal baru: uid masih null sampai splash screen memicu sign-in anonim
  /// (lihat `AuthNotifier.ensureProfileLoaded`). Listener ini menunda
  /// pemuatan wallet/streak/progres monster sampai uid itu benar-benar ada,
  /// lalu memuat ulang kalau uid berganti (mis. daftar/masuk akun).
  void _onAuthUidChanged() {
    final uid = _auth.uid;
    if (uid == null || uid == _loadedForUid) return;
    _loadedForUid = uid;
    _wallet.load(uid);
    _streak.load(uid);
    _monsterProgress.load(uid);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthUidChanged);
    _auth.removeListener(_maybeRestorePremium);
    _streak.removeListener(_refreshDailyReminders);
    _language.removeListener(_refreshDailyReminders);
    _language.removeListener(_appBeku.resyncLock);
    _auth.dispose();
    _wallet.dispose();
    _streak.dispose();
    _monsterProgress.dispose();
    _session.dispose();
    _appBeku.dispose();
    _language.dispose();
    _billing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      notifier: _language,
      child: AppScope(
        auth: _auth,
        wallet: _wallet,
        streak: _streak,
        monsterProgress: _monsterProgress,
        session: _session,
        appBeku: _appBeku,
        language: _language,
        contentRepository: _contentRepository,
        userRepository: _userRepository,
        pinService: _pinService,
        prefs: widget.prefs,
        remoteConfig: widget.remoteConfig,
        billing: _billing,
        analytics: _analytics,
        // ListenableBuilder di sini cuma untuk `locale` MaterialApp (widget
        // Material bawaan ikut berganti bahasa). Navigator TIDAK dibuat
        // ulang — `home` const & navigatorKey tetap, jadi stack navigasi utuh.
        child: ListenableBuilder(
          listenable: _language,
          builder: (context, _) => MaterialApp(
            title: 'Riung',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppNavigator.key,
            theme: AppTheme.light,
            locale: Locale(_language.language.code),
            supportedLocales: [for (final language in AppLanguage.values) Locale(language.code)],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const SplashScreen(),
            builder: (context, child) => RiungOfflineBanner(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
