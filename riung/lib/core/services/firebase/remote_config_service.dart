import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../config/economy.dart';

/// Nilai ekonomi dari Firebase Remote Config — dipakai supaya harga/reward
/// bisa diubah dari Console tanpa rilis ulang app. Default-nya dimuat dari
/// `assets/remote_config_defaults.json` (mirror `economy.dart`), lalu
/// di-fetch ulang dari server maks tiap 1 jam. Kalau fetch gagal (offline,
/// dsb) atau sebuah key belum pernah diisi di Console, tiap getter jatuh
/// balik ke konstanta `economy.dart` — UI tidak pernah tampil kosong/nol
/// gara-gara Remote Config belum sempat termuat.
class RemoteConfigService {
  RemoteConfigService();

  // Sengaja BUKAN diambil di constructor — `FirebaseRemoteConfig.instance`
  // butuh Firebase App yang sudah di-init, yang tidak selalu tersedia (mis.
  // widget test yang boot RiungApp tanpa `Firebase.initializeApp()`).
  // Ditunda ke dalam try/catch di init() supaya RemoteConfigService selalu
  // aman dibuat di mana pun; kalau init() tidak pernah dipanggil/gagal,
  // semua getter di bawah diam-diam jatuh balik ke economy.dart.
  FirebaseRemoteConfig? _rc;
  bool _ready = false;

  Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      final raw = await rootBundle.loadString('assets/remote_config_defaults.json');
      final defaults = (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as Object));
      await rc.setDefaults(defaults);
      await rc.fetchAndActivate();
      _rc = rc;
      _ready = true;
    } catch (_) {
      // Offline saat startup atau proyek belum di-setup — diam-diam pakai
      // default lokal (yang sudah = economy.dart) lewat getter di bawah.
    }
  }

  int _int(String key, int fallback) {
    final rc = _rc;
    if (!_ready || rc == null) return fallback;
    final value = rc.getInt(key);
    return value == 0 && fallback != 0 ? fallback : value;
  }

  // Earn
  int get earnCheckinHarian => _int('earn_checkin_harian', EconomyEarn.checkinHarian);
  int get earnJurnal => _int('earn_jurnal', EconomyEarn.jurnal);
  int get earnMeditasi => _int('earn_meditasi', EconomyEarn.meditasi);
  int get earnMisiHarian => _int('earn_misi_harian', EconomyEarn.misiHarian);
  int get earnMenangGame => _int('earn_menang_game', EconomyEarn.menangGame);
  int get earnMonsterJinak => _int('earn_monster_jinak', EconomyEarn.monsterJinak);
  int get earnBetterMeLesson => _int('earn_betterme_lesson', EconomyEarn.betterMeLesson);
  int get earnStreak7Hari => _int('earn_streak_7_hari', EconomyEarn.streak7Hari);
  int get earnStreak30Hari => _int('earn_streak_30_hari', EconomyEarn.streak30Hari);
  int get earnFokusProgressPercent => _int('earn_fokus_progress_percent', EconomyEarn.fokusProgressPercent);
  int get earnMinigameWinProgressPercent =>
      _int('earn_minigame_win_progress_percent', EconomyEarn.minigameWinProgressPercent);
  int get earnMinigameLoseProgressPercent =>
      _int('earn_minigame_lose_progress_percent', EconomyEarn.minigameLoseProgressPercent);

  // Spend
  int get spendFokus25Menit => _int('spend_fokus_25_menit', EconomySpend.fokus25Menit);
  int get spendFokus45Menit => _int('spend_fokus_45_menit', EconomySpend.fokus45Menit);
  int get spendFokus60Menit => _int('spend_fokus_60_menit', EconomySpend.fokus60Menit);
  int get spendPelindungStreak => _int('spend_pelindung_streak', EconomySpend.pelindungStreak);
  int get spendTiketTambahan => _int('spend_tiket_tambahan', EconomySpend.tiketTambahan);
  int get spendSkinCommon => _int('spend_skin_common', EconomySpend.skinCommon);
  int get spendSkinEpic => _int('spend_skin_epic', EconomySpend.skinEpic);
  int get spendSkinLegendary => _int('spend_skin_legendary', EconomySpend.skinLegendary);
  int get spendScrollUnlockMulai => _int('spend_scroll_unlock_mulai', EconomySpend.scrollUnlockMulai);
  int get spendFokusBundle5Sesi => _int('spend_fokus_bundle_5_sesi', EconomySpend.fokusBundle5Sesi);

  // Aplikasi Beku — Buka Waktu Scroll
  int get scrollUnlock10Menit => spendScrollUnlockMulai;
  int get scrollUnlock20Menit => _int('scroll_unlock_20_menit', EconomyScroll.unlock20Menit);
  int get scrollUnlock30Menit => _int('scroll_unlock_30_menit', EconomyScroll.unlock30Menit);
  int get scrollUnlock60Menit => _int('scroll_unlock_60_menit', EconomyScroll.unlock60Menit);
  int get scrollBundleSantai => _int('scroll_bundle_santai', EconomyScroll.bundleSantai);
  int get scrollBundleSosmed => _int('scroll_bundle_sosmed', EconomyScroll.bundleSosmed);
  int get scrollBundleSosmedDiscountPercent =>
      _int('scroll_bundle_sosmed_discount_percent', EconomyScroll.bundleSosmedDiscountPercent);

  // Tiket
  int get tiketGratisPerHari => _int('tiket_gratis_per_hari', EconomyTiket.gratisPerHari);
  int get tiketMaxDariLatihanPerHari => _int('tiket_max_dari_latihan_per_hari', EconomyTiket.maxDariLatihanPerHari);
  int get tiketMaxFightPerHari => _int('tiket_max_fight_per_hari', EconomyTiket.maxFightPerHari);

  // Free tier
  int get freeTierMeditasi => _int('free_tier_meditasi', EconomyFreeTier.meditasi);
  int get freeTierCeritaTidur => _int('free_tier_cerita_tidur', EconomyFreeTier.ceritaTidur);
  int get freeTierJurnalPerHari => _int('free_tier_jurnal_per_hari', EconomyFreeTier.jurnalPerHari);
  int get freeTierMinigamePerHari => _int('free_tier_minigame_per_hari', EconomyFreeTier.minigamePerHari);

  // Coin packs
  int get coinpackKantongCoins => _int('coinpack_kantong_coins', EconomyCoinPacks.kantong.coins);
  int get coinpackKantongBonus => _int('coinpack_kantong_bonus', EconomyCoinPacks.kantong.bonus);
  int get coinpackKantongPriceIdr => _int('coinpack_kantong_price_idr', EconomyCoinPacks.kantong.priceIdr);
  int get coinpackPetiCoins => _int('coinpack_peti_coins', EconomyCoinPacks.peti.coins);
  int get coinpackPetiBonus => _int('coinpack_peti_bonus', EconomyCoinPacks.peti.bonus);
  int get coinpackPetiPriceIdr => _int('coinpack_peti_price_idr', EconomyCoinPacks.peti.priceIdr);
  int get coinpackBrankasCoins => _int('coinpack_brankas_coins', EconomyCoinPacks.brankas.coins);
  int get coinpackBrankasBonus => _int('coinpack_brankas_bonus', EconomyCoinPacks.brankas.bonus);
  int get coinpackBrankasPriceIdr => _int('coinpack_brankas_price_idr', EconomyCoinPacks.brankas.priceIdr);

  // Premium
  int get premiumHargaBulananIdr => _int('premium_harga_bulanan_idr', EconomyPremium.hargaBulananIdr);
  int get premiumHargaTahunanIdr => _int('premium_harga_tahunan_idr', EconomyPremium.hargaTahunanIdr);
  int get premiumTrialHari => _int('premium_trial_hari', EconomyPremium.trialHari);
}
