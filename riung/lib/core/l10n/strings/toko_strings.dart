import '../../services/billing_service.dart';

/// Teks fitur Toko + paywall Premium (dipakai juga oleh paywall onboarding)
/// + gate akun sebelum pembelian uang asli.
abstract class TokoStrings {
  const TokoStrings();

  // ── Toko ──
  String get shopTitle;
  String get shopSubtitle;
  String get sectionRoutine;
  String get focusTitle;
  String get focusSub;
  String get shieldTitle;
  String get shieldSub;
  String get sectionMonster;
  String cosmeticName(String id);
  String get owned;
  String get sectionCoins;
  String coinPackLabel(String id);
  String get coinPackBadge;
  String packBonus(int bonus);
  String get coinUnit;
  String get ethicNote;
  String get coinsAdded;
  String get packUnavailable;
  String get shieldReady;
  String get coinsChanged;

  // ── Konfirmasi & preview kosmetik ──
  String get confirmTitle;
  String get coinsNow;
  String get remainingAfter;
  String remainingCoins(int coins);
  String get confirmYes;
  String get rarityLegendary;
  String get rarityEpic;
  String get rarityCommon;
  String get alreadyOwned;
  String coinsPrice(int price);
  String priceShort(int idr);
  String lemariTitle(String monster);
  String get wardrobe;
  String get slotAll;
  String get slotHead;
  String get slotNeck;
  String get slotBase;
  String get slotFrame;
  String get slotSide;
  String get khasLabel;
  String get worn;
  String exclusiveTo(String monster);
  String get lemariNote;
  String get applyStyle;
  String get styleSaved;
  String buyFor(int price);
  String cosmeticOwnedNow(String name);

  // ── Beli sesi fokus ──
  String get prepaidTitle;
  String get prepaidIntro;
  String get oneSession;
  String get oneSessionSub;
  String bundleTitle(int count);
  String get bundleSub;
  String get bundleBadge;
  String get pointEmergency;
  String get pointOffline;
  String buyBundle(int count, int price);
  String buyOne(int price);
  String get itemOne;
  String itemBundle(int count);
  String sessionsReadyTitle(int count);
  String get sessionsReadySub;
  String get sessionsLabel;

  // ── Koin kurang ──
  String get notEnoughTitle;
  String get needPrefix;
  String needCoins(int coins);
  String get youHave;
  String get needSuffix;
  String get fastestWays;
  String get wayCheckin;
  String get wayJournal;
  String get wayMeditation;
  String streakBonus(int day7, int day30);
  String startCheckin(int coins);
  String get orTopUp;
  String stillMissing(int coins);
  String get enoughNow;

  // ── Pembelian sukses / dipulihkan ──
  String get coinsLeft;
  String get startFirstSession;
  String get welcomeBack;
  String restoredBody(String plan);
  String get premiumActive;
  String premiumActiveUntil(String date);
  String get backToHome;

  // ── Paywall Premium ──
  String get premiumTitle;
  String get premiumPill;
  String get premiumSub;
  List<String> get premiumBenefits;
  String get planYearly;
  String get planMonthly;
  String get saveYearly;
  String annualPerk(int coins);
  String yearlyWithPrice(String price);
  String yearlyFallback(String price, String perMonth);
  String monthlyWithPrice(String price);
  String monthlyFallback(String price);
  String premiumNote(int days);
  String tryFree(int days);
  String get processing;
  String get restore;
  String get terms;
  String get planUnavailable;

  // ── Paywall onboarding ──
  String onboardingTitle(String name);
  String onboardingSub(int days);
  List<String> get onboardingBenefits;
  String trialTrailing(int days);
  String get monthlySimple;
  String startTrial(int days);
  String get continueFree;
  String monthlyPrice(String price);
  String yearlyPrice(String price);
  String onboardingYearlyFallback(String price, String perMonth);
  String onboardingMonthlyFallback(String price);

  // ── Ketentuan langganan ──
  String get termsTitle;
  String termsTrial(int days);
  String get termsPlay;
  String get termsCancel;
  String get termsFree;
  String get termsPrivacy;

  // ── Gate akun sebelum beli ──
  String get gateTitle;
  String get gateBody;
  String get gateSignUp;

  // ── Error pembelian ──
  String billingError(BillingErrorKind? kind, String? detail);
}

class TokoStringsId extends TokoStrings {
  const TokoStringsId();

  @override
  String get shopTitle => 'Toko';
  @override
  String get shopSubtitle => 'Latihan tetap jalan utamanya — isi koin kalau butuh';
  @override
  String get sectionRoutine => 'Buat rutinitasmu';
  @override
  String get focusTitle => 'Sesi fokus prabayar';
  @override
  String get focusSub => 'Blokir aplikasi lain 25 mnt · jalan tanpa internet';
  @override
  String get shieldTitle => 'Pelindung streak';
  @override
  String get shieldSub => 'Streak aman 1 hari saat kamu benar-benar nggak sempat';
  @override
  String get sectionMonster => 'Buat monstermu';
  @override
  String cosmeticName(String id) {
    switch (id) {
      case 'topi_rajut':
        return 'Topi rajut Si Kabut';
      case 'syal_hangat':
        return 'Syal hangat Si Waswas';
      case 'bantal_mini':
        return 'Bantal mini Si Meronta';
      case 'bingkai_emas':
        return 'Bingkai emas Si Cermin';
      case 'jam_pasir':
        return 'Jam pasir mini';
      case 'kantong_hp':
        return 'Kantong HP rajut';
      case 'topi_tidur':
        return 'Topi tidur bulan';
      case 'pin_berani':
        return 'Pin berani';
      case 'kompas':
        return 'Kompas kuningan';
      case 'cangkir_teh':
        return 'Cangkir teh hangat';
      case 'batu_tenang':
        return 'Batu tenang';
      case 'lentera':
        return 'Lentera kecil';
      case 'bintang_kintsugi':
        return 'Bintang kintsugi';
      case 'senter':
        return 'Senter mungil';
      case 'selimut_peluk':
        return 'Selimut peluk';
      case 'palu_busa':
        return 'Palu busa';
    }
    return id;
  }

  @override
  String get owned => 'Dimiliki';
  @override
  String get sectionCoins => 'Isi koin';
  @override
  String coinPackLabel(String id) {
    switch (id) {
      case 'coins_80':
        return 'Kantong Koin';
      case 'coins_300':
        return 'Peti Koin';
      case 'coins_700':
        return 'Brankas Koin';
    }
    return id;
  }

  @override
  String get coinPackBadge => 'Terpopuler';
  @override
  String packBonus(int bonus) => '+$bonus bonus';
  @override
  String get coinUnit => 'koin';
  @override
  String get ethicNote => 'Progres monstermu nggak bisa dibeli — cuma latihan yang bisa.';
  @override
  String get coinsAdded => 'Koin berhasil ditambahkan.';
  @override
  String get packUnavailable => 'Paket ini belum tersedia di Play Store. Coba lagi nanti.';
  @override
  String get shieldReady => 'Pelindung streak siap dipakai.';
  @override
  String get coinsChanged => 'Koinnya keburu berubah, coba lagi.';

  @override
  String get confirmTitle => 'Konfirmasi pembelian';
  @override
  String get coinsNow => 'Koinmu sekarang';
  @override
  String get remainingAfter => 'Sisa setelah beli';
  @override
  String remainingCoins(int coins) => '$coins koin';
  @override
  String get confirmYes => 'Ya, beli sekarang';
  @override
  String get rarityLegendary => 'Legendaris';
  @override
  String get rarityEpic => 'Epic';
  @override
  String get rarityCommon => 'Umum';
  @override
  String get alreadyOwned => 'Sudah dimiliki';
  @override
  String coinsPrice(int price) => '$price koin';
  @override
  String priceShort(int idr) => 'Rp${idr ~/ 1000}rb';
  @override
  String lemariTitle(String monster) => 'Lemari $monster';
  @override
  String get wardrobe => 'Lemari';
  @override
  String get slotAll => 'Semua';
  @override
  String get slotHead => 'Kepala';
  @override
  String get slotNeck => 'Leher';
  @override
  String get slotBase => 'Alas';
  @override
  String get slotFrame => 'Bingkai';
  @override
  String get slotSide => 'Khas';
  @override
  String get khasLabel => 'Khas';
  @override
  String get worn => 'Dipakai';
  @override
  String exclusiveTo(String monster) => 'Khusus $monster';
  @override
  String get lemariNote => 'Kosmetik cuma tampilan. Progres monstermu nggak bisa dibeli — cuma latihan yang bisa.';
  @override
  String get applyStyle => 'Pakai gaya ini';
  @override
  String get styleSaved => 'Gayanya tersimpan';
  @override
  String buyFor(int price) => 'Beli · $price koin';
  @override
  String cosmeticOwnedNow(String name) => '$name sudah jadi milikmu.';

  @override
  String get prepaidTitle => 'Sesi fokus prabayar';
  @override
  String get prepaidIntro =>
      'Bayar di depan biar niatnya nempel — Si Mengelak paling jago bikin kamu "nanti aja". Sesi tersimpan di perangkat dan jalan tanpa internet.';
  @override
  String get oneSession => '1 sesi';
  @override
  String get oneSessionSub => '25 menit fokus';
  @override
  String bundleTitle(int count) => 'Paket $count sesi';
  @override
  String get bundleSub => 'Buat seminggu kerja / kuliah';
  @override
  String get bundleBadge => 'HEMAT 20%';
  @override
  String get pointEmergency => 'Keluar darurat: streak tetap aman, sesi tidak dihitung';
  @override
  String get pointOffline => 'Sekali dibeli, bisa dipakai kapan pun — offline sekalipun';
  @override
  String buyBundle(int count, int price) => 'Beli paket $count sesi · $price koin';
  @override
  String buyOne(int price) => 'Beli 1 sesi · $price koin';
  @override
  String get itemOne => '1 sesi fokus';
  @override
  String itemBundle(int count) => 'Paket $count sesi fokus';
  @override
  String sessionsReadyTitle(int count) => '$count sesi fokus siap dipakai';
  @override
  String get sessionsReadySub =>
      'Tersimpan di perangkatmu — mulai kapan pun, bahkan tanpa internet. Niat baik hari ini, tinggal dijalankan.';
  @override
  String get sessionsLabel => 'sesi fokus';

  @override
  String get notEnoughTitle => 'Koinmu belum cukup';
  @override
  String get needPrefix => 'Butuh ';
  @override
  String needCoins(int coins) => '$coins koin';
  @override
  String get youHave => ', kamu punya ';
  @override
  String get needSuffix => '. Paling cepat nutupnya: latihan kecil hari ini.';
  @override
  String get fastestWays => 'CARA TERCEPAT DAPAT KOIN';
  @override
  String get wayCheckin => 'Check-in pagi (1 menit)';
  @override
  String get wayJournal => 'Entri jurnal (3 kalimat)';
  @override
  String get wayMeditation => 'Meditasi 5 menit';
  @override
  String streakBonus(int day7, int day30) => 'Bonus streak: +$day7 di hari ke-7 · +$day30 di hari ke-30';
  @override
  String startCheckin(int coins) => 'Mulai check-in · +$coins koin';
  @override
  String get orTopUp => 'Atau isi koin di Toko';
  @override
  String stillMissing(int coins) => 'Masih kurang $coins koin.';
  @override
  String get enoughNow => 'Koinmu sudah cukup sekarang — coba lagi.';

  @override
  String get coinsLeft => 'sisa koin';
  @override
  String get startFirstSession => 'Mulai sesi pertama sekarang';
  @override
  String get welcomeBack => 'Selamat datang kembali!';
  @override
  String restoredBody(String plan) =>
      'Riung Premium $plan-mu ditemukan dan sudah aktif lagi di perangkat ini. Jurnal, progres monster, dan koinmu ikut tersinkron.';
  @override
  String get premiumActive => 'Aktif';
  @override
  String premiumActiveUntil(String date) => 'Aktif sampai $date';
  @override
  String get backToHome => 'Lanjut ke beranda';

  @override
  String get premiumTitle => 'Riung Premium';
  @override
  String get premiumPill => 'Riung Premium';
  @override
  String get premiumSub => 'Buka semua latihan buat menjinakkan ketujuh monstermu.';
  @override
  List<String> get premiumBenefits => const [
        'Semua meditasi & cerita tidur',
        'Semua panduan jurnal CBT, tanpa batas per hari',
        'Semua level Better Me',
        '3 sesi Fokus gratis per hari (biasanya 1)',
        'Semua gaya kartu karakter terbuka',
        'Laporan bulanan & pola faktor dengan suasana hatimu',
      ];
  @override
  String get planYearly => 'Tahunan';
  @override
  String get planMonthly => 'Bulanan';
  @override
  String get saveYearly => 'HEMAT 2 BULAN';
  @override
  String annualPerk(int coins) => 'Tahunan: bayar 10 bulan untuk 12 bulan, plus +$coins koin setiap hari.';
  @override
  String yearlyWithPrice(String price) => '$price/tahun';
  @override
  String yearlyFallback(String price, String perMonth) => 'Rp$price/tahun · ≈ Rp$perMonth/bulan';
  @override
  String monthlyWithPrice(String price) => '$price/bulan · berhenti kapan saja';
  @override
  String monthlyFallback(String price) => 'Rp$price/bulan · berhenti kapan saja';
  @override
  String premiumNote(int days) =>
      'Gratis $days hari dulu — diingatkan sebelum tagihan pertama. Fitur inti (check-in, jurnal, monster) tetap gratis selamanya.';
  @override
  String tryFree(int days) => 'Coba gratis $days hari';
  @override
  String get processing => 'Memproses...';
  @override
  String get restore => 'Pulihkan pembelian';
  @override
  String get terms => 'Ketentuan';
  @override
  String get planUnavailable => 'Paket belum tersedia di Play Store. Coba lagi nanti.';

  @override
  String onboardingTitle(String name) => 'Rencana penjinakanmu sudah siap${name.isEmpty ? '' : ', $name'}';
  @override
  String onboardingSub(int days) => 'Coba gratis $days hari, batalkan kapan saja';
  @override
  List<String> get onboardingBenefits => const [
        'Semua meditasi, cerita tidur & jurnal tanpa batas',
        'Program "Better me" lengkap (22 sesi)',
        'Semua 7 monster & latihan penjinakannya',
        'Konten kerja: Jeda di Tengah Kerja & anti-burnout',
      ];
  @override
  String trialTrailing(int days) => 'Trial $days hari';
  @override
  String get monthlySimple => 'Bulanan';
  @override
  String startTrial(int days) => 'Mulai trial gratis $days hari';
  @override
  String get continueFree => 'Lanjut versi gratis';
  @override
  String monthlyPrice(String price) => '$price/bulan';
  @override
  String yearlyPrice(String price) => '$price/tahun';
  @override
  String onboardingYearlyFallback(String price, String perMonth) => 'Rp$price/tahun · ≈Rp$perMonth/bulan';
  @override
  String onboardingMonthlyFallback(String price) => 'Rp$price/bulan';

  @override
  String get termsTitle => 'Ketentuan langganan';
  @override
  String termsTrial(int days) =>
      'Coba gratis $days hari, lalu berlangganan otomatis sesuai paket yang kamu pilih kalau tidak dibatalkan sebelum masa coba habis.';
  @override
  String get termsPlay => 'Pembayaran dan perpanjangan diproses lewat akun Google Play kamu.';
  @override
  String get termsCancel =>
      'Batalkan kapan saja lewat Google Play (menu Langganan) paling lambat 24 jam sebelum periode berakhir. Premium tetap aktif sampai akhir periode.';
  @override
  String get termsFree => 'Fitur inti (check-in, jurnal, monster) tetap gratis selamanya.';
  @override
  String get termsPrivacy => 'Baca kebijakan privasi';

  @override
  String get gateTitle => 'Simpan pembelianmu';
  @override
  String get gateBody => 'Masuk atau buat akun dulu supaya pembelian ini aman kalau kamu ganti HP.';
  @override
  String get gateSignUp => 'Daftar/Hubungkan akun';

  @override
  String billingError(BillingErrorKind? kind, String? detail) {
    if (kind == BillingErrorKind.deliveryFailed) {
      return 'Pembayaran berhasil tapi koin/Premium gagal masuk. Coba "Pulihkan pembelian".';
    }
    return (detail == null || detail.isEmpty) ? 'Pembelian gagal.' : detail;
  }
}

class TokoStringsEn extends TokoStrings {
  const TokoStringsEn();

  @override
  String get shopTitle => 'Shop';
  @override
  String get shopSubtitle => 'Practice stays the main thing — top up coins if you need';
  @override
  String get sectionRoutine => 'For your routine';
  @override
  String get focusTitle => 'Prepaid focus sessions';
  @override
  String get focusSub => 'Blocks other apps for 25 min · works without internet';
  @override
  String get shieldTitle => 'Streak shield';
  @override
  String get shieldSub => 'Keeps your streak safe for 1 day when you truly cannot make it';
  @override
  String get sectionMonster => 'For your monsters';
  @override
  String cosmeticName(String id) {
    switch (id) {
      case 'topi_rajut':
        return "Si Kabut's knit hat";
      case 'syal_hangat':
        return "Si Waswas's warm scarf";
      case 'bantal_mini':
        return "Si Meronta's mini pillow";
      case 'bingkai_emas':
        return "Si Cermin's golden frame";
      case 'jam_pasir':
        return "Mini hourglass";
      case 'kantong_hp':
        return "Knitted phone pouch";
      case 'topi_tidur':
        return "Moon nightcap";
      case 'pin_berani':
        return "Brave pin";
      case 'kompas':
        return "Brass compass";
      case 'cangkir_teh':
        return "Warm cup of tea";
      case 'batu_tenang':
        return "Calm stone";
      case 'lentera':
        return "Little lantern";
      case 'bintang_kintsugi':
        return "Kintsugi star";
      case 'senter':
        return "Tiny flashlight";
      case 'selimut_peluk':
        return "Hug blanket";
      case 'palu_busa':
        return "Foam gavel";
    }
    return id;
  }

  @override
  String get owned => 'Owned';
  @override
  String get sectionCoins => 'Top up coins';
  @override
  String coinPackLabel(String id) {
    switch (id) {
      case 'coins_80':
        return 'Coin Pouch';
      case 'coins_300':
        return 'Coin Chest';
      case 'coins_700':
        return 'Coin Vault';
    }
    return id;
  }

  @override
  String get coinPackBadge => 'Most popular';
  @override
  String packBonus(int bonus) => '+$bonus bonus';
  @override
  String get coinUnit => 'coins';
  @override
  String get ethicNote => "Your monster progress can't be bought — only practice can.";
  @override
  String get coinsAdded => 'Coins added successfully.';
  @override
  String get packUnavailable => 'This pack is not available on the Play Store yet. Please try again later.';
  @override
  String get shieldReady => 'Streak shield is ready to use.';
  @override
  String get coinsChanged => 'Your coins changed in the meantime, please try again.';

  @override
  String get confirmTitle => 'Confirm purchase';
  @override
  String get coinsNow => 'Your coins now';
  @override
  String get remainingAfter => 'Left after buying';
  @override
  String remainingCoins(int coins) => '$coins coins';
  @override
  String get confirmYes => 'Yes, buy now';
  @override
  String get rarityLegendary => 'Legendary';
  @override
  String get rarityEpic => 'Epic';
  @override
  String get rarityCommon => 'Common';
  @override
  String get alreadyOwned => 'Already owned';
  @override
  String coinsPrice(int price) => '$price coins';
  @override
  String priceShort(int idr) => 'Rp${idr ~/ 1000}k';
  @override
  String lemariTitle(String monster) => "$monster's wardrobe";
  @override
  String get wardrobe => 'Wardrobe';
  @override
  String get slotAll => 'All';
  @override
  String get slotHead => 'Head';
  @override
  String get slotNeck => 'Neck';
  @override
  String get slotBase => 'Base';
  @override
  String get slotFrame => 'Frame';
  @override
  String get slotSide => 'Signature';
  @override
  String get khasLabel => 'Signature';
  @override
  String get worn => 'Wearing';
  @override
  String exclusiveTo(String monster) => '$monster only';
  @override
  String get lemariNote => "Cosmetics are just for looks. Your monster's progress can't be bought — only practice can.";
  @override
  String get applyStyle => 'Use this look';
  @override
  String get styleSaved => 'Look saved';
  @override
  String buyFor(int price) => 'Buy · $price coins';
  @override
  String cosmeticOwnedNow(String name) => '$name is now yours.';

  @override
  String get prepaidTitle => 'Prepaid focus sessions';
  @override
  String get prepaidIntro =>
      'Pay up front so the intention sticks — Si Mengelak is the best at making you say "later". Sessions are stored on your device and work without internet.';
  @override
  String get oneSession => '1 session';
  @override
  String get oneSessionSub => '25 minutes of focus';
  @override
  String bundleTitle(int count) => '$count-session pack';
  @override
  String get bundleSub => 'For a week of work / college';
  @override
  String get bundleBadge => 'SAVE 20%';
  @override
  String get pointEmergency => 'Emergency exit: your streak stays safe, the session is not counted';
  @override
  String get pointOffline => 'Once bought, use it anytime — even offline';
  @override
  String buyBundle(int count, int price) => 'Buy $count-session pack · $price coins';
  @override
  String buyOne(int price) => 'Buy 1 session · $price coins';
  @override
  String get itemOne => '1 focus session';
  @override
  String itemBundle(int count) => '$count focus sessions pack';
  @override
  String sessionsReadyTitle(int count) => count == 1 ? '1 focus session ready to use' : '$count focus sessions ready to use';
  @override
  String get sessionsReadySub =>
      'Stored on your device — start anytime, even without internet. A good intention today, just waiting to be carried out.';
  @override
  String get sessionsLabel => 'focus sessions';

  @override
  String get notEnoughTitle => 'Not enough coins yet';
  @override
  String get needPrefix => 'You need ';
  @override
  String needCoins(int coins) => '$coins coins';
  @override
  String get youHave => ', you have ';
  @override
  String get needSuffix => '. The quickest way to close the gap: a small exercise today.';
  @override
  String get fastestWays => 'FASTEST WAYS TO EARN COINS';
  @override
  String get wayCheckin => 'Morning check-in (1 minute)';
  @override
  String get wayJournal => 'Journal entry (3 sentences)';
  @override
  String get wayMeditation => '5-minute meditation';
  @override
  String streakBonus(int day7, int day30) => 'Streak bonus: +$day7 on day 7 · +$day30 on day 30';
  @override
  String startCheckin(int coins) => 'Start check-in · +$coins coins';
  @override
  String get orTopUp => 'Or top up coins in the Shop';
  @override
  String stillMissing(int coins) => 'Still $coins coins short.';
  @override
  String get enoughNow => 'You have enough coins now — try again.';

  @override
  String get coinsLeft => 'coins left';
  @override
  String get startFirstSession => 'Start your first session now';
  @override
  String get welcomeBack => 'Welcome back!';
  @override
  String restoredBody(String plan) =>
      'Your Riung Premium $plan was found and is active again on this device. Your journals, monster progress, and coins are synced too.';
  @override
  String get premiumActive => 'Active';
  @override
  String premiumActiveUntil(String date) => 'Active until $date';
  @override
  String get backToHome => 'Continue to home';

  @override
  String get premiumTitle => 'Riung Premium';
  @override
  String get premiumPill => 'Riung Premium';
  @override
  String get premiumSub => 'Unlock all exercises to tame your seven monsters.';
  @override
  List<String> get premiumBenefits => const [
        'All meditations & sleep stories',
        'All CBT journal guides, no daily limit',
        'All Better Me levels',
        '3 free Focus sessions a day (usually 1)',
        'All character card styles unlocked',
        'Monthly report & patterns between what you mention and your mood',
      ];
  @override
  String get planYearly => 'Yearly';
  @override
  String get planMonthly => 'Monthly';
  @override
  String get saveYearly => 'SAVE 2 MONTHS';
  @override
  String annualPerk(int coins) => 'Yearly: pay 10 months for 12, plus +$coins coins every day.';
  @override
  String yearlyWithPrice(String price) => '$price/year';
  @override
  String yearlyFallback(String price, String perMonth) => 'Rp$price/year · ≈ Rp$perMonth/month';
  @override
  String monthlyWithPrice(String price) => '$price/month · cancel anytime';
  @override
  String monthlyFallback(String price) => 'Rp$price/month · cancel anytime';
  @override
  String premiumNote(int days) =>
      'Free for $days days first — you will be reminded before the first charge. Core features (check-in, journal, monsters) stay free forever.';
  @override
  String tryFree(int days) => 'Try free for $days days';
  @override
  String get processing => 'Processing...';
  @override
  String get restore => 'Restore purchases';
  @override
  String get terms => 'Terms';
  @override
  String get planUnavailable => 'This plan is not available on the Play Store yet. Please try again later.';

  @override
  String onboardingTitle(String name) => 'Your taming plan is ready${name.isEmpty ? '' : ', $name'}';
  @override
  String onboardingSub(int days) => 'Try free for $days days, cancel anytime';
  @override
  List<String> get onboardingBenefits => const [
        'All meditations, sleep stories & journals, unlimited',
        'Complete "Better me" program (22 sessions)',
        'All 7 monsters & their taming exercises',
        'Work content: Break in the Middle of Work & anti-burnout',
      ];
  @override
  String trialTrailing(int days) => '$days-day trial';
  @override
  String get monthlySimple => 'Monthly';
  @override
  String startTrial(int days) => 'Start $days-day free trial';
  @override
  String get continueFree => 'Continue with the free version';
  @override
  String monthlyPrice(String price) => '$price/month';
  @override
  String yearlyPrice(String price) => '$price/year';
  @override
  String onboardingYearlyFallback(String price, String perMonth) => 'Rp$price/year · ≈Rp$perMonth/month';
  @override
  String onboardingMonthlyFallback(String price) => 'Rp$price/month';

  @override
  String get termsTitle => 'Subscription terms';
  @override
  String termsTrial(int days) =>
      'Free for $days days, then it renews automatically on the plan you chose unless you cancel before the trial ends.';
  @override
  String get termsPlay => 'Payments and renewals are processed through your Google Play account.';
  @override
  String get termsCancel =>
      'Cancel anytime in Google Play (Subscriptions menu) at least 24 hours before the period ends. Premium stays active until the end of the period.';
  @override
  String get termsFree => 'Core features (check-in, journal, monsters) stay free forever.';
  @override
  String get termsPrivacy => 'Read the privacy policy';

  @override
  String get gateTitle => 'Keep your purchase';
  @override
  String get gateBody => 'Sign in or create an account first so this purchase stays safe if you switch phones.';
  @override
  String get gateSignUp => 'Sign up / link account';

  @override
  String billingError(BillingErrorKind? kind, String? detail) {
    if (kind == BillingErrorKind.deliveryFailed) {
      return 'Payment succeeded but the coins/Premium did not come through. Try "Restore purchases".';
    }
    return (detail == null || detail.isEmpty) ? 'Purchase failed.' : detail;
  }
}
