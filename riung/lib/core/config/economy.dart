/// Semua angka ekonomi Riung — satu-satunya sumber angka (harga, reward, cap)
/// untuk seluruh app. Mirror dari `CLAUDE.md` §3 Ekonomi dan
/// `docs/dummy-data-seed.json` → `config_economy`. Jangan menulis angka
/// ekonomi lepas di file layar/widget lain.
abstract final class EconomyEarn {
  static const int checkinHarian = 5;
  static const int jurnal = 4;
  static const int meditasi = 3;
  static const int misiHarian = 3;
  static const int menangGame = 8;
  static const int monsterJinak = 50;
  static const int betterMeLesson = 10;
  static const int streak7Hari = 20;
  static const int streak30Hari = 100;

  /// Progres penjinakan (%) yang ditambahkan ke monster aktif per sesi
  /// fokus selesai — lihat `docs/riung-cara-kerja-lengkap.md` §4.
  static const int fokusProgressPercent = 4;

  /// Progres penjinakan (%) dari satu sesi mini-game — menang vs kalah,
  /// lihat `design/Monster.dc.html` § Menang/Kalah. Kalah tetap dapat
  /// progres (CLAUDE.md aturan #4 anti-guilt: "gagal sekali bukan berarti
  /// 'pasti gagal'").
  static const int minigameWinProgressPercent = 5;
  static const int minigameLoseProgressPercent = 2;
}

abstract final class EconomySpend {
  static const int fokus25Menit = 25;
  static const int fokus45Menit = 40;
  static const int fokus60Menit = 50;
  static const int pelindungStreak = 20;
  static const int tiketTambahan = 30;
  static const int skinCommon = 100;

  /// Aksesori kecil karakter kepribadian (syal, kacamata bulat, pita, dst).
  /// Tier lain memakai [skinCommon] dan [skinEpic].
  static const int aksesorisKecil = 60;

  /// Diskon paket (bundel) aksesori dibanding beli satuan, dan pembulatan harga
  /// paket ke kelipatan ini supaya tetap rapi.
  static const int aksesorisBundelDiskonPersen = 20;
  static const int aksesorisBundelPembulatan = 5;
  static const int skinEpic = 300;
  static const int skinLegendary = 500;

  /// Kosmetik khas satu monster (jam pasir Si Nanti, cangkir teh Si Bara, dst):
  /// setara tier epic, hanya dijual di Lemari monster itu.
  static const int skinKhas = skinEpic;

  /// Harga awal buka waktu scroll di Aplikasi Beku (bertingkat, ini nilai awal).
  static const int scrollUnlockMulai = 15;

  /// Paket 5 sesi Mode Fokus prabayar (Toko § "Beli sesi fokus") — lebih
  /// hemat dari 5× [fokus25Menit] satuan ("HEMAT 20%" di desain).
  static const int fokusBundle5Sesi = 100;
}

/// Harga "Buka Waktu Scroll" di Aplikasi Beku (Toko § "Buka Waktu Scroll" /
/// interstisial batas tercapai) — mirror `design/AppBeku.dc.html` props.
abstract final class EconomyScroll {
  static const int unlock10Menit = EconomySpend.scrollUnlockMulai;
  static const int unlock20Menit = 25;
  static const int unlock30Menit = 35;
  static const int unlock60Menit = 60;

  /// Bundel "Sesi santai" — Instagram 15 mnt + TikTok 15 mnt.
  static const int bundleSantai = 35;

  /// Bundel "Semua sosmed" — 30 mnt tiap aplikasi sosmed yang dibekukan.
  static const int bundleSosmed = 75;
  static const int bundleSosmedDiscountPercent = 16;

  /// PENGAMAN ETIS (CLAUDE.md aturan #4, "tidak ada dark pattern"): buka-waktu
  /// berbayar dibatasi per hari, harganya naik tiap kali dipakai, dan tombolnya
  /// baru aktif setelah jeda supaya keputusannya sadar, bukan refleks. Jalur
  /// napas gratis tidak pernah dibatasi.
  static const int maxPaidUnlocksPerDay = 3;
  static const int escalationPerUnlock = 10;
  static const int unlockCooldownSeconds = 60;
}

abstract final class EconomyTiket {
  static const int gratisPerHari = 1;
  static const int maxDariLatihanPerHari = 3;
  static const int maxFightPerHari = 4;

  /// Tiket tidak pernah dijual langsung dengan uang — hanya ditukar dari koin
  /// hasil latihan (lihat [EconomySpend.tiketTambahan]).
  static const bool tiketDijual = false;
}

abstract final class EconomyFreeTier {
  static const int meditasi = 3;
  static const int ceritaTidur = 2;
  static const int jurnalPerHari = 1;
  static const int minigamePerHari = 1;

  /// Satu sesi Mode Fokus gratis tiap hari, supaya progres monster tidak
  /// pernah bergantung pada koin (yang bisa dibeli).
  static const int fokusPerHari = 1;
}

class CoinPack {
  const CoinPack({
    required this.id,
    required this.coins,
    required this.bonus,
    required this.priceIdr,
    required this.label,
    this.badge,
  });

  final String id;
  final int coins;
  final int bonus;
  final int priceIdr;
  final String label;
  final String? badge;

  int get totalCoins => coins + bonus;
}

abstract final class EconomyCoinPacks {
  static const CoinPack kantong = CoinPack(
    id: 'coins_80',
    coins: 80,
    bonus: 0,
    priceIdr: 15000,
    label: 'Kantong Koin',
  );

  static const CoinPack peti = CoinPack(
    id: 'coins_300',
    coins: 300,
    bonus: 30,
    priceIdr: 49000,
    label: 'Peti Koin',
    badge: 'Terpopuler',
  );

  static const CoinPack brankas = CoinPack(
    id: 'coins_700',
    coins: 700,
    bonus: 120,
    priceIdr: 99000,
    label: 'Brankas Koin',
  );

  static const List<CoinPack> all = [kantong, peti, brankas];
}

abstract final class EconomyPremium {
  static const int hargaBulananIdr = 59000;

  /// Tahunan = bayar 10 bulan, gratis 2 bulan (pola langganan Google): harga
  /// tahunan diturunkan dari harga bulanan, bukan angka lepas.
  static const int bulanDibayarPerTahun = 10;
  static const int bulanGratisPerTahun = 2;
  static const int hargaTahunanIdr = hargaBulananIdr * bulanDibayarPerTahun;
  static const int trialHari = 7;

  /// Jatah sesi Fokus gratis per hari untuk Premium (non-Premium: [EconomyFreeTier.fokusPerHari]).
  /// Ini tetap latihan, bukan jalan pintas: progres monster tidak pernah bisa dibeli.
  static const int fokusGratisPerHari = 3;

  /// Keunggulan khusus tahunan: koin harian. Masuk cadangan "koin beli"
  /// (bukan koin latihan), jadi tidak bisa dipakai buka-waktu Aplikasi Beku
  /// (pengaman etis, lihat `EconomyScroll.maxPaidUnlocksPerDay`).
  static const int koinHarianTahunan = 2;

  /// Toleransi setelah tanggal perpanjangan (perpanjangan Play kadang telat
  /// beberapa jam) sebelum status dianggap kedaluwarsa.
  static const int graceHari = 3;
}
