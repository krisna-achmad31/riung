import 'package:flutter/foundation.dart';

import '../config/appbeku_catalog.dart';
import '../config/economy.dart';
import '../models/frozen_app_setting.dart';
import '../services/app_usage_service.dart';
import '../services/local_prefs_store.dart';
import 'wallet_notifier.dart';

/// Notifier global Aplikasi Beku — domain lintas layar sendiri (Setup,
/// Permission, Interstitial, Rekap, Toko § "Buka Waktu Scroll" semua baca
/// state yang sama), jadi bukan diselipkan ke [WalletNotifier] meski dia
/// juga memutar koin — beda domain dari saldo/tiket. Justifikasi
/// penambahan notifier ke-6 sesuai CLAUDE.md §State management.
///
/// Data harian (napas diambil, koin dipakai buka waktu, menit ekstra
/// terbeli, threshold interstisial, streak "di bawah batas") disimpan
/// satu blob JSON (`LocalPrefsStore.appBekuDailyJson`) yang direset saat
/// tanggalnya berbeda dari hari ini — lihat [_rolloverIfNewDay].
/// Hasil percobaan buka-waktu berbayar.
enum UnlockResult { ok, notEnoughEarnedCoins, dailyCapReached }

class AppBekuNotifier extends ChangeNotifier {
  AppBekuNotifier({required LocalPrefsStore prefs, AppUsageService? usageService})
      : _prefs = prefs,
        _usageService = usageService ?? AppUsageService();

  final LocalPrefsStore _prefs;
  final AppUsageService _usageService;

  Map<String, FrozenAppSetting> _frozenApps = {};
  Map<String, int> _usageMinutesToday = {};
  Map<String, int> _extraUnlockedMinutes = {};
  Map<String, int> _notifiedThreshold = {};
  bool _hasUsageAccess = false;
  bool _hasAccessibilityAccess = false;
  bool _lockEnabled = true;
  int _breathTakenToday = 0;
  int _scrollCoinsToday = 0;
  int _paidUnlocksToday = 0;
  int _streakDays = 0;
  bool _loading = false;

  Map<String, FrozenAppSetting> get frozenApps => _frozenApps;
  List<FrozenAppSetting> get enabledFrozenApps =>
      _frozenApps.values.where((a) => a.enabled).toList();
  bool get hasUsageAccess => _hasUsageAccess;
  bool get hasAccessibilityAccess => _hasAccessibilityAccess;

  /// Pilihan user: kunci aplikasi yang melewati batas (true) atau cuma
  /// diingatkan (false).
  bool get lockEnabled => _lockEnabled;

  /// Kunci dinyalakan & ada aplikasi beku, tapi izin mati (mis. Aksesibilitas
  /// otomatis dimatikan Android setelah Force Stop) — user perlu tahu.
  bool get lockNeedsAttention => _lockEnabled && enabledFrozenApps.isNotEmpty && (!_hasUsageAccess || !_hasAccessibilityAccess);

  /// Kunci benar-benar aktif hanya kalau dinyalakan DAN kedua izin ada.
  bool get lockActive => _lockEnabled && _hasUsageAccess && _hasAccessibilityAccess && enabledFrozenApps.isNotEmpty;

  /// Teks notifikasi service pemantau — diisi `main.dart` supaya ikut
  /// bahasa aktif tanpa notifier ini bergantung ke LanguageNotifier.
  ({String title, String body}) Function() lockNotifText = () => (title: 'Aplikasi Beku', body: '');
  int get breathTakenToday => _breathTakenToday;
  int get scrollCoinsToday => _scrollCoinsToday;

  /// Berapa kali buka-waktu berbayar dipakai hari ini (pengaman etis,
  /// lihat `EconomyScroll.maxPaidUnlocksPerDay`).
  int get paidUnlocksToday => _paidUnlocksToday;
  bool get paidUnlockCapReached => _paidUnlocksToday >= EconomyScroll.maxPaidUnlocksPerDay;

  /// Harga sebenarnya untuk buka-waktu berikutnya: harga dasar naik
  /// [EconomyScroll.escalationPerUnlock] koin tiap kali sudah dipakai hari ini.
  int effectiveUnlockPrice(int basePrice) => basePrice + EconomyScroll.escalationPerUnlock * _paidUnlocksToday;
  int get streakDays => _streakDays;
  bool get loading => _loading;

  int usageMinutesOf(String packageName) => _usageMinutesToday[packageName] ?? 0;
  int extraUnlockedOf(String packageName) => _extraUnlockedMinutes[packageName] ?? 0;

  int effectiveLimitOf(String packageName) {
    final setting = _frozenApps[packageName];
    if (setting == null) return 0;
    return setting.dailyLimitMinutes + extraUnlockedOf(packageName);
  }

  bool isOverLimit(String packageName) => usageMinutesOf(packageName) >= effectiveLimitOf(packageName);

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _frozenApps = _prefs.frozenAppsJson.map(
      (pkg, raw) => MapEntry(pkg, FrozenAppSetting.fromMap(pkg, (raw as Map).cast<String, dynamic>())),
    );
    _hasUsageAccess = await _usageService.hasUsageAccess();
    _hasAccessibilityAccess = await _usageService.hasAccessibilityAccess();
    _lockEnabled = _prefs.appBekuLockEnabled;
    await _rolloverIfNewDay();
    await _syncLock();

    _loading = false;
    notifyListeners();
  }

  Future<void> _rolloverIfNewDay() async {
    final today = _todayIso();
    final daily = _prefs.appBekuDailyJson;
    if (daily != null && daily['date'] == today) {
      _breathTakenToday = daily['breathCount'] as int? ?? 0;
      _scrollCoinsToday = daily['scrollCoins'] as int? ?? 0;
      _paidUnlocksToday = daily['paidUnlocks'] as int? ?? 0;
      _streakDays = daily['streakDays'] as int? ?? 0;
      _extraUnlockedMinutes = ((daily['extraUnlocked'] as Map?) ?? {}).map(
        (k, v) => MapEntry(k as String, v as int),
      );
      _notifiedThreshold = ((daily['notifiedThreshold'] as Map?) ?? {}).map(
        (k, v) => MapEntry(k as String, v as int),
      );
      return;
    }

    // Hari baru (atau instal pertama): evaluasi streak dari snapshot
    // terakhir kemarin sebelum direset — kalau total pemakaian kemarin
    // masih di bawah total batas, streak lanjut; kalau lewat, putus.
    var streak = daily?['streakDays'] as int? ?? 0;
    final lastTotalUsed = daily?['lastSnapshotUsed'] as int?;
    final lastTotalLimit = daily?['lastSnapshotLimit'] as int?;
    if (daily != null && lastTotalUsed != null && lastTotalLimit != null) {
      streak = lastTotalUsed <= lastTotalLimit ? streak + 1 : 0;
    }

    _breathTakenToday = 0;
    _scrollCoinsToday = 0;
    _paidUnlocksToday = 0;
    _extraUnlockedMinutes = {};
    _notifiedThreshold = {};
    _streakDays = streak;
    await _persistDaily();
  }

  Future<void> _persistDaily({int? lastSnapshotUsed, int? lastSnapshotLimit}) async {
    await _prefs.setAppBekuDailyJson({
      'date': _todayIso(),
      'breathCount': _breathTakenToday,
      'scrollCoins': _scrollCoinsToday,
      'paidUnlocks': _paidUnlocksToday,
      'streakDays': _streakDays,
      'extraUnlocked': _extraUnlockedMinutes,
      'notifiedThreshold': _notifiedThreshold,
      'lastSnapshotUsed': lastSnapshotUsed,
      'lastSnapshotLimit': lastSnapshotLimit,
    });
  }

  Future<void> refreshUsageAccess() async {
    _hasUsageAccess = await _usageService.hasUsageAccess();
    _hasAccessibilityAccess = await _usageService.hasAccessibilityAccess();
    await _syncLock();
    notifyListeners();
  }

  Future<void> openAccessibilitySettings() => _usageService.openAccessibilitySettings();

  /// Nyalakan/matikan mode kunci (opsi "kunci / buka" di Pengaturan).
  Future<void> setLockEnabled(bool value) async {
    _lockEnabled = value;
    await _prefs.setAppBekuLockEnabled(value);
    await _syncLock();
    notifyListeners();
  }

  /// Sinkron ulang konfigurasi ke service native (mis. saat bahasa berganti
  /// supaya teks notifikasinya ikut).
  Future<void> resyncLock() => _syncLock();

  Future<void> _syncLock() async {
    final text = lockNotifText();
    await _usageService.syncLockConfig(
      enabled: lockActive,
      date: _todayIso(),
      entries: [
        for (final app in enabledFrozenApps)
          (package: app.packageName, base: app.dailyLimitMinutes, extra: extraUnlockedOf(app.packageName)),
      ],
      notifTitle: text.title,
      notifBody: text.body,
    );
  }

  /// Package yang barusan dikunci service native, atau null.
  Future<String?> consumeLockedPackage() => _usageService.consumeLockPackage();

  Future<void> goHome() => _usageService.goHome();
  Future<void> moveToBack() => _usageService.moveToBack();

  Future<void> openUsageAccessSettings() => _usageService.openUsageAccessSettings();

  Future<void> setFrozenApp(AppBekuCatalogEntry entry, {required int limitMinutes, required bool enabled}) async {
    _frozenApps = {
      ..._frozenApps,
      entry.packageName: FrozenAppSetting(
        packageName: entry.packageName,
        dailyLimitMinutes: limitMinutes,
        enabled: enabled,
      ),
    };
    await _prefs.setFrozenAppsJson(_frozenApps.map((pkg, s) => MapEntry(pkg, s.toMap())));
    await _syncLock();
    notifyListeners();
  }

  /// Cek pemakaian semua app yang dibekukan & aktif — kembalikan package
  /// name pertama yang baru saja melewati batas efektifnya (buat
  /// dinavigasi ke interstitial), atau null kalau tidak ada. Dipanggil
  /// tiap RootShellScreen kembali ke foreground (lihat catatan CLAUDE.md
  /// M6: WorkManager background nggak bisa munculkan UI tanpa
  /// SYSTEM_ALERT_WINDOW, jadi gerbangnya di sini).
  Future<String?> checkUsageAndMaybeTrigger() async {
    if (!_hasUsageAccess || enabledFrozenApps.isEmpty) return null;
    final packages = enabledFrozenApps.map((a) => a.packageName).toList();
    _usageMinutesToday = await _usageService.getUsageMinutesToday(packages);

    var totalUsed = 0;
    var totalLimit = 0;
    String? triggered;
    for (final setting in enabledFrozenApps) {
      final used = _usageMinutesToday[setting.packageName] ?? 0;
      final limit = effectiveLimitOf(setting.packageName);
      totalUsed += used;
      totalLimit += limit;
      final lastNotified = _notifiedThreshold[setting.packageName] ?? 0;
      if (triggered == null && used >= limit && used > lastNotified) {
        triggered = setting.packageName;
      }
    }
    if (triggered != null) {
      _notifiedThreshold = {..._notifiedThreshold, triggered: _usageMinutesToday[triggered] ?? 0};
    }
    await _persistDaily(lastSnapshotUsed: totalUsed, lastSnapshotLimit: totalLimit);
    notifyListeners();
    return triggered;
  }

  Future<void> recordBreath() async {
    _breathTakenToday += 1;
    await _persistDaily();
    notifyListeners();
  }

  /// Beli menit ekstra dengan koin (interstitial "Buka 10 menit lagi" atau
  /// Toko § "Buka Waktu Scroll"). Koinnya lewat [WalletNotifier.spend]
  /// (tunduk validasi delta `firestore.rules`); menit ekstranya lokal.
  ///
  /// PENGAMAN ETIS: dibatasi [EconomyScroll.maxPaidUnlocksPerDay] kali per
  /// hari, harga bertingkat ([effectiveUnlockPrice]), dan hanya boleh
  /// memakai koin hasil latihan (bukan koin beli). [countsAsUnlock] false
  /// untuk sub-langkah bundel supaya satu bundel dihitung sekali.
  Future<UnlockResult> unlockMinutes({
    required WalletNotifier wallet,
    required String packageName,
    required int minutes,
    required int price,
    bool countsAsUnlock = true,
  }) async {
    if (countsAsUnlock && paidUnlockCapReached) return UnlockResult.dailyCapReached;
    final charged = countsAsUnlock && price > 0 ? effectiveUnlockPrice(price) : price;
    final berhasil = await wallet.spend(amount: charged, reason: 'scroll_unlock:$packageName:$minutes', earnedOnly: charged > 0);
    if (!berhasil) return UnlockResult.notEnoughEarnedCoins;
    if (countsAsUnlock) _paidUnlocksToday += 1;
    _extraUnlockedMinutes = {
      ..._extraUnlockedMinutes,
      packageName: (_extraUnlockedMinutes[packageName] ?? 0) + minutes,
    };
    // Buka waktu = pengakuan sadar, bukan pelanggaran — angkat threshold
    // supaya interstitial tidak langsung muncul lagi di menit yang sama.
    _notifiedThreshold = {..._notifiedThreshold, packageName: effectiveLimitOf(packageName)};
    _scrollCoinsToday += charged;
    await _persistDaily();
    await _syncLock();
    notifyListeners();
    return UnlockResult.ok;
  }
}
