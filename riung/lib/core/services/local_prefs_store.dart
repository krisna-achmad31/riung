import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/personality_result.dart';
import '../models/sleep_reminder_settings.dart';

/// Wrapper `shared_preferences` bertipe — satu-satunya tempat data ringan
/// (profil, saldo, streak, progres monster) dibaca/ditulis secara
/// permanen di perangkat. Dipakai oleh [LocalUserRepository] &
/// [LocalWalletFunctionsService]. Harus di-`init()` sekali sebelum dipakai
/// (lihat `main.dart`).
class LocalPrefsStore {
  LocalPrefsStore._(this._prefs);

  final SharedPreferences _prefs;

  static LocalPrefsStore? _instance;

  static Future<LocalPrefsStore> init() async {
    final cached = _instance;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final store = LocalPrefsStore._(prefs);
    _instance = store;
    return store;
  }

  static const _kUserId = 'riung_uid';
  static const _kOnboardingDone = 'riung_onboarding_done';
  static const _kCoins = 'riung_coins';
  static const _kLifetimeEarned = 'riung_lifetime_earned';
  static const _kLifetimeSpent = 'riung_lifetime_spent';
  static const _kStreakCurrent = 'riung_streak_current';
  static const _kStreakLongest = 'riung_streak_longest';
  static const _kLastCheckInDate = 'riung_last_checkin_date';
  static const _kMonsterProgressJson = 'riung_monster_progress_json';
  static const _kUserProfileJson = 'riung_user_profile_json';
  static const _kFavoriteAffirmationIds = 'riung_favorite_affirmation_ids';
  static const _kCustomAffirmationsJson = 'riung_custom_affirmations_json';
  static const _kTicketBalance = 'riung_ticket_balance';
  static const _kTicketsEarnedToday = 'riung_tickets_earned_today';
  static const _kFightsToday = 'riung_fights_today';
  static const _kTicketResetDate = 'riung_ticket_reset_date';
  static const _kOwnedCosmetics = 'riung_owned_cosmetics';
  static const _kPrepaidFocusSessions = 'riung_prepaid_focus_sessions';
  static const _kStreakShieldBalance = 'riung_streak_shield_balance';
  static const _kFrozenAppsJson = 'riung_frozen_apps_json';
  static const _kAppBekuDailyJson = 'riung_appbeku_daily_json';
  static const _kAppBekuLockEnabled = 'riung_appbeku_lock_enabled';
  static const _kPurchasedCoinsReserve = 'riung_purchased_coins_reserve';
  static const _kFreeFocusDate = 'riung_free_focus_date';
  static const _kFreeFocusUsed = 'riung_free_focus_used';
  static const _kPremiumDailyClaimDate = 'riung_premium_daily_claim_date';
  static const _kNotifSettingsJson = 'riung_notif_settings_json';
  static const _kBiometricUnlockEnabled = 'riung_biometric_unlock_enabled';
  static const _kBetterMeCompleted = 'riung_betterme_completed';
  static const _kBetterMeReflectionsJson = 'riung_betterme_reflections_json';
  static const _kLanguageCode = 'riung_language_code';
  static const _kMissionsJson = 'riung_missions_json';
  static const _kAfirmasiTime = 'riung_afirmasi_reminder_time';
  static const _kSleepReminderJson = 'riung_sleep_reminder_json';
  static const _kPersonalityJson = 'riung_personality_results_json';
  static const _kCardStyle = 'riung_personality_card_style';
  static const _kSleepSyncEnabled = 'riung_sleep_sync_enabled';
  static const _kAccessoriesJson = 'riung_personality_accessories_json';
  static const _kMonsterCosmeticsJson = 'riung_monster_cosmetics_json';
  static const _kWaswasStageJson = 'riung_waswas_stage_json';

  /// Kode bahasa pilihan user (`id`/`en`); null = belum pernah memilih
  /// (pakai bahasa bawaan, lihat `AppLanguage.defaultLanguage`).
  String? get languageCode => _prefs.getString(_kLanguageCode);
  Future<void> setLanguageCode(String value) => _prefs.setString(_kLanguageCode, value);

  String? get userId => _prefs.getString(_kUserId);
  Future<void> setUserId(String value) => _prefs.setString(_kUserId, value);

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool value) => _prefs.setBool(_kOnboardingDone, value);

  int? get coins => _prefs.getInt(_kCoins);
  Future<void> setCoins(int value) => _prefs.setInt(_kCoins, value);

  int get lifetimeEarned => _prefs.getInt(_kLifetimeEarned) ?? 0;
  Future<void> setLifetimeEarned(int value) => _prefs.setInt(_kLifetimeEarned, value);

  int get lifetimeSpent => _prefs.getInt(_kLifetimeSpent) ?? 0;
  Future<void> setLifetimeSpent(int value) => _prefs.setInt(_kLifetimeSpent, value);

  int get streakCurrent => _prefs.getInt(_kStreakCurrent) ?? 0;
  Future<void> setStreakCurrent(int value) => _prefs.setInt(_kStreakCurrent, value);

  int get streakLongest => _prefs.getInt(_kStreakLongest) ?? 0;
  Future<void> setStreakLongest(int value) => _prefs.setInt(_kStreakLongest, value);

  DateTime? get lastCheckInDate {
    final raw = _prefs.getString(_kLastCheckInDate);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastCheckInDate(DateTime value) =>
      _prefs.setString(_kLastCheckInDate, value.toIso8601String());

  Map<String, dynamic>? get monsterProgressJson {
    final raw = _prefs.getString(_kMonsterProgressJson);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setMonsterProgressJson(Map<String, dynamic> value) =>
      _prefs.setString(_kMonsterProgressJson, jsonEncode(value));

  Map<String, dynamic>? get userProfileJson {
    final raw = _prefs.getString(_kUserProfileJson);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setUserProfileJson(Map<String, dynamic> value) =>
      _prefs.setString(_kUserProfileJson, jsonEncode(value));

  List<String> get favoriteAffirmationIds => _prefs.getStringList(_kFavoriteAffirmationIds) ?? const [];
  Future<void> setFavoriteAffirmationIds(List<String> value) =>
      _prefs.setStringList(_kFavoriteAffirmationIds, value);

  List<Map<String, dynamic>> get customAffirmations {
    final raw = _prefs.getString(_kCustomAffirmationsJson);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> setCustomAffirmations(List<Map<String, dynamic>> value) =>
      _prefs.setString(_kCustomAffirmationsJson, jsonEncode(value));

  int get ticketBalance => _prefs.getInt(_kTicketBalance) ?? 0;
  Future<void> setTicketBalance(int value) => _prefs.setInt(_kTicketBalance, value);

  int get ticketsEarnedToday => _prefs.getInt(_kTicketsEarnedToday) ?? 0;
  Future<void> setTicketsEarnedToday(int value) => _prefs.setInt(_kTicketsEarnedToday, value);

  int get fightsToday => _prefs.getInt(_kFightsToday) ?? 0;
  Future<void> setFightsToday(int value) => _prefs.setInt(_kFightsToday, value);

  /// Tanggal (yyyy-MM-dd) terakhir kali gerbang harian tiket (tiket gratis +
  /// reset earned/fights) dijalankan — dipakai [WalletNotifier] mendeteksi
  /// hari baru.
  String? get ticketResetDate => _prefs.getString(_kTicketResetDate);
  Future<void> setTicketResetDate(String value) => _prefs.setString(_kTicketResetDate, value);

  /// Id kosmetik yang sudah dibeli (Toko § "Buat monstermu") — dibeli
  /// dengan koin, jadi lokal-murni seperti tiket (bukan lewat wallet
  /// Firestore), lihat [WalletNotifier.buyCosmetic].
  Set<String> get ownedCosmetics => (_prefs.getStringList(_kOwnedCosmetics) ?? const []).toSet();
  Future<void> setOwnedCosmetics(Set<String> value) => _prefs.setStringList(_kOwnedCosmetics, value.toList());

  /// Sesi Mode Fokus prabayar (Toko § "Beli sesi fokus") — dikonsumsi
  /// duluan sebelum potong koin langsung per sesi, jalan offline seperti
  /// tiket serangan (CLAUDE.md aturan #5).
  int get prepaidFocusSessions => _prefs.getInt(_kPrepaidFocusSessions) ?? 0;
  Future<void> setPrepaidFocusSessions(int value) => _prefs.setInt(_kPrepaidFocusSessions, value);

  /// Pelindung streak tersimpan (Toko § "Buat rutinitasmu") — belum ada
  /// gerbang deteksi streak putus di app ini, jadi nilainya baru
  /// tersimpan/ditampilkan, belum otomatis terpakai.
  int get streakShieldBalance => _prefs.getInt(_kStreakShieldBalance) ?? 0;
  Future<void> setStreakShieldBalance(int value) => _prefs.setInt(_kStreakShieldBalance, value);

  /// Pengaturan Aplikasi Beku per package (`{pkg: {limit, enabled}}`) —
  /// tetap tersimpan lintas hari (bukan direset harian).
  Map<String, dynamic> get frozenAppsJson {
    final raw = _prefs.getString(_kFrozenAppsJson);
    if (raw == null) return const {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setFrozenAppsJson(Map<String, dynamic> value) =>
      _prefs.setString(_kFrozenAppsJson, jsonEncode(value));

  /// Satu blob state harian Aplikasi Beku — napas diambil, koin dipakai
  /// buka waktu, menit ekstra terbeli per app, threshold interstisial
  /// terakhir per app, dan streak "di bawah batas". Semua field yang
  /// per-hari digabung satu key supaya reset hari baru cuma satu
  /// baca+tulis, bukan berpuluh key terpisah. Lihat `AppBekuNotifier`
  /// untuk skema isinya.
  Map<String, dynamic>? get appBekuDailyJson {
    final raw = _prefs.getString(_kAppBekuDailyJson);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Koin yang berasal dari pembelian (paket koin) dan belum terpakai —
  /// dilacak supaya buka-waktu Aplikasi Beku bisa dibatasi ke koin hasil
  /// latihan saja (lihat `WalletNotifier.spend(earnedOnly: true)`).
  int get purchasedCoinsReserve => _prefs.getInt(_kPurchasedCoinsReserve) ?? 0;
  Future<void> setPurchasedCoinsReserve(int value) => _prefs.setInt(_kPurchasedCoinsReserve, value);

  /// Tanggal (yyyy-MM-dd) koin harian Premium tahunan terakhir diambil.
  String? get premiumDailyClaimDate => _prefs.getString(_kPremiumDailyClaimDate);
  Future<void> setPremiumDailyClaimDate(String value) => _prefs.setString(_kPremiumDailyClaimDate, value);

  /// Tanggal (yyyy-MM-dd) sesi Fokus gratis terakhir dipakai.
  String? get freeFocusDate => _prefs.getString(_kFreeFocusDate);
  Future<void> setFreeFocusDate(String value) => _prefs.setString(_kFreeFocusDate, value);

  /// Jumlah sesi Fokus gratis yang sudah dipakai pada [freeFocusDate].
  int get freeFocusUsed => _prefs.getInt(_kFreeFocusUsed) ?? 0;
  Future<void> setFreeFocusUsed(int value) => _prefs.setInt(_kFreeFocusUsed, value);

  /// Mode kunci Aplikasi Beku: aplikasi yang melewati batas benar-benar
  /// ditutup oleh Riung (bukan sekadar diingatkan). Default nyala — user
  /// bisa mematikannya di Pengaturan Aplikasi Beku kapan saja.
  bool get appBekuLockEnabled => _prefs.getBool(_kAppBekuLockEnabled) ?? true;
  Future<void> setAppBekuLockEnabled(bool value) => _prefs.setBool(_kAppBekuLockEnabled, value);

  Future<void> setAppBekuDailyJson(Map<String, dynamic> value) =>
      _prefs.setString(_kAppBekuDailyJson, jsonEncode(value));

  /// Preferensi notifikasi lokal (`{key: bool}`) — cuma menyimpan
  /// pilihan on/off, BELUM tersambung ke pengiriman push FCM sungguhan
  /// (itu butuh scheduler server-side, di luar cakupan M6). Lihat
  /// `NotifikasiScreen`.
  Map<String, dynamic> get notifSettingsJson {
    final raw = _prefs.getString(_kNotifSettingsJson);
    if (raw == null) return const {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setNotifSettingsJson(Map<String, dynamic> value) =>
      _prefs.setString(_kNotifSettingsJson, jsonEncode(value));

  /// Pengaturan pengingat tidur (layar Pengingat tidur). Belum pernah
  /// disimpan → [SleepReminderSettings.defaults].
  SleepReminderSettings get sleepReminder {
    final raw = _prefs.getString(_kSleepReminderJson);
    if (raw == null) return SleepReminderSettings.defaults;
    try {
      return SleepReminderSettings.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return SleepReminderSettings.defaults;
    }
  }

  /// Hasil tes kepribadian per tes (skor saja, tanpa jawaban mentah).
  Map<PersonalityTest, PersonalityResult> get personalityResults {
    final raw = _prefs.getString(_kPersonalityJson);
    if (raw == null) return const {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final test in PersonalityTest.values)
          if (map[test.name] is Map) test: PersonalityResult.fromMap(test, (map[test.name] as Map).cast<String, dynamic>()),
      };
    } catch (_) {
      return const {};
    }
  }

  /// Naik tiap hasil tes / aksesori / gaya kartu berubah, supaya kartu di
  /// Beranda dan hub kepribadian menyegarkan diri tanpa bergantung pada
  /// urutan navigasi (mis. pushReplacement dari kuis ke hasil).
  final ValueNotifier<int> personalityRevision = ValueNotifier<int>(0);

  Future<void> setPersonalityResult(PersonalityResult result) async {
    final all = {for (final e in personalityResults.entries) e.key.name: e.value.toMap(), result.test.name: result.toMap()};
    await _prefs.setString(_kPersonalityJson, jsonEncode(all));
    personalityRevision.value++;
  }

  /// Aksesori yang dipakai per tes: `{jung: {head: beanie, face: ...}}`.
  Map<String, Map<String, String>> get personalityAccessories {
    final raw = _prefs.getString(_kAccessoriesJson);
    if (raw == null) return const {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {for (final e in map.entries) e.key: (e.value as Map).map((k, v) => MapEntry(k.toString(), v.toString()))};
    } catch (_) {
      return const {};
    }
  }

  Future<void> setPersonalityAccessories(Map<String, Map<String, String>> value) async {
    await _prefs.setString(_kAccessoriesJson, jsonEncode(value));
    personalityRevision.value++;
  }

  /// Kosmetik yang dipakai PER monster (Lemari): `{kabut: {head: topi_rajut}}`.
  /// Kepemilikan tetap global di [ownedCosmetics].
  Map<String, Map<String, String>> get monsterCosmetics {
    final raw = _prefs.getString(_kMonsterCosmeticsJson);
    if (raw == null) return const {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {for (final e in map.entries) e.key: (e.value as Map).map((k, v) => MapEntry(k.toString(), v.toString()))};
    } catch (_) {
      return const {};
    }
  }

  /// Naik tiap isi Lemari berubah, supaya layar yang merender monster ikut segar.
  final ValueNotifier<int> monsterCosmeticsRevision = ValueNotifier<int>(0);

  Future<void> setMonsterCosmetics(Map<String, Map<String, String>> value) async {
    await _prefs.setString(_kMonsterCosmeticsJson, jsonEncode(value));
    monsterCosmeticsRevision.value++;
  }

  /// Gaya kartu yang dipilih PER karakter (per tes): `{jung: taman, ...}`.
  /// Kepemilikan gaya tetap global; hanya pilihan pakainya yang per karakter.
  Map<String, String> get personalityCardStyles {
    final raw = _prefs.getString(_kCardStyle);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      // format lama (satu string id) dianggap tidak ada — jatuh ke klasik.
    }
    return const {};
  }

  String personalityCardStyle(PersonalityTest test) => personalityCardStyles[test.name] ?? 'klasik';

  Future<void> setPersonalityCardStyle(PersonalityTest test, String id) async {
    await _prefs.setString(_kCardStyle, jsonEncode({...personalityCardStyles, test.name: id}));
    personalityRevision.value++;
  }

  /// Apakah user sudah pernah menyimpan pengingat tidur.
  bool get hasSleepReminder => _prefs.containsKey(_kSleepReminderJson);

  Future<void> setSleepReminder(SleepReminderSettings value) =>
      _prefs.setString(_kSleepReminderJson, jsonEncode(value.toMap()));

  /// Jam kirim notifikasi afirmasi harian ("HH:mm"), default 07:00.
  String get afirmasiReminderTime => _prefs.getString(_kAfirmasiTime) ?? '07:00';
  Future<void> setAfirmasiReminderTime(String value) => _prefs.setString(_kAfirmasiTime, value);

  /// Misi harian yang sudah dicentang hari ini: `{'date': 'yyyy-MM-dd',
  /// 'done': [indeks...]}`. Tanggalnya dipakai untuk reset otomatis tiap
  /// hari — lihat `BerandaScreen`.
  Map<String, dynamic> get missionsJson {
    final raw = _prefs.getString(_kMissionsJson);
    if (raw == null) return const {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setMissionsJson(Map<String, dynamic> value) =>
      _prefs.setString(_kMissionsJson, jsonEncode(value));

  /// Preferensi user buat tawarkan buka Jurnal pakai biometrik (di atas
  /// PIN) — `JurnalPinUnlockScreen` cek ini SEKALIGUS ketersediaan
  /// perangkat (`JurnalPinService.isBiometricAvailable`) sebelum
  /// menawarkan tombol sidik jari/wajah.
  bool get biometricUnlockEnabled => _prefs.getBool(_kBiometricUnlockEnabled) ?? true;
  Future<void> setBiometricUnlockEnabled(bool value) => _prefs.setBool(_kBiometricUnlockEnabled, value);

  /// Id sesi Better Me yang sudah diselesaikan — lintas hari (tidak
  /// direset), lihat `betterme_content.dart`.
  Set<String> get betterMeCompleted => (_prefs.getStringList(_kBetterMeCompleted) ?? const []).toSet();
  Future<void> setBetterMeCompleted(Set<String> value) => _prefs.setStringList(_kBetterMeCompleted, value.toList());

  /// Jawaban refleksi tiap sesi (`{sessionId: teks}`) — beda dari Jurnal:
  /// bukan catatan pribadi harian, jadi sengaja TIDAK dienkripsi seperti
  /// `JournalCryptoService` (lihat `SesiContentScreen`).
  Map<String, dynamic> get betterMeReflectionsJson {
    final raw = _prefs.getString(_kBetterMeReflectionsJson);
    if (raw == null) return const {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setBetterMeReflectionsJson(Map<String, dynamic> value) =>
      _prefs.setString(_kBetterMeReflectionsJson, jsonEncode(value));

  /// Pengguna memilih menghubungkan data tidur (Health Connect) ke laporan.
  bool get sleepSyncEnabled => _prefs.getBool(_kSleepSyncEnabled) ?? false;
  Future<void> setSleepSyncEnabled(bool value) => _prefs.setBool(_kSleepSyncEnabled, value);

  /// Node peta latihan Si Waswas yang sudah diselesaikan HARI INI
  /// (`{'date': 'yyyy-MM-dd', 'done': [id node...]}`) — pola sama dengan
  /// [missionsJson], reset otomatis tiap hari baru. Node "hadapi" (mini-game)
  /// TIDAK disimpan di sini — statusnya sudah dari `MonsterProgress`.
  Map<String, dynamic> get waswasStageJson {
    final raw = _prefs.getString(_kWaswasStageJson);
    if (raw == null) return const {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setWaswasStageJson(Map<String, dynamic> value) =>
      _prefs.setString(_kWaswasStageJson, jsonEncode(value));

  /// Menghapus semua preferensi & progres tersimpan (hapus akun, dan test).
  Future<void> clearAll() => _prefs.clear();
}
