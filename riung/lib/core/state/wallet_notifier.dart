import 'package:flutter/foundation.dart';

import '../config/economy.dart';
import '../models/coin_transaction.dart';
import '../models/wallet.dart';
import '../services/local_prefs_store.dart';
import '../services/user_repository.dart';
import '../services/wallet_functions_service.dart';

/// Notifier global saldo koin & tiket Mode Fokus. Mutasi koin selalu lewat
/// [WalletFunctionsService] (mirror Cloud Functions) — notifier ini tidak
/// pernah mengubah saldo sendiri (CLAUDE.md aturan #5). Tiket serangan
/// PENGECUALIAN sengaja: prabayar & lokal-murni (harus jalan offline, lihat
/// `docs/firebase-architecture.md` §8.1), jadi dimutasi & dipersist
/// langsung di sini lewat [LocalPrefsStore] — bukan lewat Cloud Functions.
class WalletNotifier extends ChangeNotifier {
  WalletNotifier({
    required UserRepository userRepository,
    required WalletFunctionsService walletFunctions,
    required LocalPrefsStore prefs,
  })  : _userRepository = userRepository,
        _walletFunctions = walletFunctions,
        _prefs = prefs;

  final UserRepository _userRepository;
  final WalletFunctionsService _walletFunctions;
  final LocalPrefsStore _prefs;

  Wallet _wallet = Wallet.zero();
  int _tickets = 0;
  int _ticketsEarnedToday = 0;
  int _fightsToday = 0;
  bool _loading = false;
  String? _uid;
  Set<String> _ownedCosmetics = {};
  int _prepaidFocusSessions = 0;
  int _streakShieldBalance = 0;
  int _purchasedReserve = 0;
  String? _freeFocusDate;
  int _freeFocusUsed = 0;
  String? _premiumClaimDate;

  Wallet get wallet => _wallet;
  int get coins => _wallet.coins;
  int get tickets => _tickets;
  bool get loading => _loading;
  Set<String> get ownedCosmetics => _ownedCosmetics;
  int get prepaidFocusSessions => _prepaidFocusSessions;
  int get streakShieldBalance => _streakShieldBalance;

  /// Koin hasil latihan (bukan beli): saldo dikurangi cadangan koin beli.
  /// Buka-waktu Aplikasi Beku hanya boleh memakai ini.
  int get earnedCoins => (coins - _purchasedReserve).clamp(0, coins);

  /// Koin harian Premium tahunan hari ini belum diambil?
  bool get premiumDailyClaimable => _premiumClaimDate != _todayIso();

  /// Ambil koin harian pelanggan tahunan ([EconomyPremium.koinHarianTahunan]).
  /// Hari yang terlewat TIDAK menumpuk (tanpa rasa bersalah, tanpa tekanan
  /// login harian). Koin ini dicatat sebagai koin-beli: tidak bisa dipakai
  /// buka-waktu Aplikasi Beku.
  Future<bool> claimPremiumDaily() async {
    if (!premiumDailyClaimable) return false;
    await earn(amount: EconomyPremium.koinHarianTahunan, reason: 'premium_daily');
    await recordPurchasedCoins(EconomyPremium.koinHarianTahunan);
    _premiumClaimDate = _todayIso();
    await _prefs.setPremiumDailyClaimDate(_premiumClaimDate!);
    notifyListeners();
    return true;
  }

  /// Jatah sesi Fokus gratis per hari: 1 untuk semua, [EconomyPremium.fokusGratisPerHari] untuk Premium.
  static int freeFocusLimit({required bool premium}) => premium ? EconomyPremium.fokusGratisPerHari : EconomyFreeTier.fokusPerHari;

  /// Sesi Fokus gratis yang masih tersisa hari ini.
  int freeFocusRemaining({bool premium = false}) {
    final used = _freeFocusDate == _todayIso() ? _freeFocusUsed : 0;
    return (freeFocusLimit(premium: premium) - used).clamp(0, freeFocusLimit(premium: premium));
  }

  /// Masih ada sesi Fokus gratis hari ini?
  bool freeFocusAvailable({bool premium = false}) => freeFocusRemaining(premium: premium) > 0;

  /// Sisa jatah serangan hari ini (CLAUDE.md §3: maks
  /// [EconomyTiket.maxFightPerHari]/hari) — dipakai membedakan "tiket habis
  /// karena belum latihan" dari "sudah kena limit harian".
  int get fightsRemainingToday => (EconomyTiket.maxFightPerHari - _fightsToday).clamp(0, EconomyTiket.maxFightPerHari);
  bool get dailyFightCapReached => _fightsToday >= EconomyTiket.maxFightPerHari;

  Future<void> load(String uid) async {
    _uid = uid;
    _loading = true;
    notifyListeners();
    _wallet = await _userRepository.getWallet(uid);
    await _loadTickets();
    _ownedCosmetics = _prefs.ownedCosmetics;
    _prepaidFocusSessions = _prefs.prepaidFocusSessions;
    _streakShieldBalance = _prefs.streakShieldBalance;
    _purchasedReserve = _prefs.purchasedCoinsReserve;
    _freeFocusDate = _prefs.freeFocusDate;
    _freeFocusUsed = _prefs.freeFocusUsed;
    _premiumClaimDate = _prefs.premiumDailyClaimDate;
    _loading = false;
    notifyListeners();
  }

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Gerbang harian: hari baru → reset hitungan latihan/serangan & beri 1
  /// tiket gratis (CLAUDE.md §3 "1 gratis/hari"). Saldo dibatasi maks
  /// [EconomyTiket.maxFightPerHari] supaya tidak menumpuk tak terbatas.
  Future<void> _loadTickets() async {
    final todayIso = _todayIso();
    var balance = _prefs.ticketBalance;
    var earnedToday = _prefs.ticketsEarnedToday;
    var fightsToday = _prefs.fightsToday;
    if (_prefs.ticketResetDate != todayIso) {
      earnedToday = 0;
      fightsToday = 0;
      balance = (balance + 1).clamp(0, EconomyTiket.maxFightPerHari);
      await _prefs.setTicketResetDate(todayIso);
      await _prefs.setTicketBalance(balance);
      await _prefs.setTicketsEarnedToday(earnedToday);
      await _prefs.setFightsToday(fightsToday);
    }
    _tickets = balance;
    _ticketsEarnedToday = earnedToday;
    _fightsToday = fightsToday;
  }

  Future<void> earn({required int amount, required String reason}) async {
    final uid = _uid;
    if (uid == null) return;
    _wallet = await _walletFunctions.earnCoins(uid: uid, amount: amount, reason: reason);
    notifyListeners();
  }

  /// Catat koin yang berasal dari pembelian paket koin (dipanggil setelah
  /// pembelian terverifikasi). Lihat [earnedCoins].
  Future<void> recordPurchasedCoins(int amount) async {
    _purchasedReserve += amount;
    await _prefs.setPurchasedCoinsReserve(_purchasedReserve);
    notifyListeners();
  }

  /// Pakai sesi Fokus gratis hari ini kalau masih ada.
  Future<bool> consumeFreeFocusSession({bool premium = false}) async {
    if (!freeFocusAvailable(premium: premium)) return false;
    final today = _todayIso();
    _freeFocusUsed = (_freeFocusDate == today ? _freeFocusUsed : 0) + 1;
    _freeFocusDate = today;
    await _prefs.setFreeFocusDate(today);
    await _prefs.setFreeFocusUsed(_freeFocusUsed);
    notifyListeners();
    return true;
  }

  /// True bila berhasil dipotong, false bila saldo tidak cukup. Dengan
  /// [earnedOnly] hanya koin hasil latihan yang boleh dipakai (koin beli
  /// tidak). Belanja biasa memakai koin beli lebih dulu.
  Future<bool> spend({required int amount, required String reason, bool earnedOnly = false}) async {
    final uid = _uid;
    if (uid == null) return false;
    if (earnedOnly && earnedCoins < amount) return false;
    try {
      _wallet = await _walletFunctions.spendCoins(uid: uid, amount: amount, reason: reason);
      if (!earnedOnly && _purchasedReserve > 0) {
        _purchasedReserve = (_purchasedReserve - amount).clamp(0, _purchasedReserve);
        await _prefs.setPurchasedCoinsReserve(_purchasedReserve);
      }
      notifyListeners();
      return true;
    } on InsufficientCoinsException {
      return false;
    }
  }

  /// Tiket hasil latihan (check-in/meditasi/jurnal, dsb) — dibatasi maks
  /// [EconomyTiket.maxDariLatihanPerHari]/hari (CLAUDE.md §3 "max 3 dari
  /// latihan"). Diam-diam tidak menambah apa pun setelah limit tercapai,
  /// supaya pemanggil (layar selesai check-in/meditasi/jurnal) tidak perlu
  /// tahu soal cap ini.
  Future<void> addTickets(int count) async {
    final grant = count.clamp(0, EconomyTiket.maxDariLatihanPerHari - _ticketsEarnedToday);
    if (grant <= 0) return;
    _ticketsEarnedToday += grant;
    _tickets = (_tickets + grant).clamp(0, EconomyTiket.maxFightPerHari);
    await _prefs.setTicketsEarnedToday(_ticketsEarnedToday);
    await _prefs.setTicketBalance(_tickets);
    notifyListeners();
  }

  /// true kalau berhasil dipakai — false kalau tiket habis ATAU sudah kena
  /// limit [EconomyTiket.maxFightPerHari] serangan hari ini.
  Future<bool> useTicket() async {
    if (_tickets <= 0 || dailyFightCapReached) return false;
    _tickets -= 1;
    _fightsToday += 1;
    await _prefs.setTicketBalance(_tickets);
    await _prefs.setFightsToday(_fightsToday);
    notifyListeners();
    return true;
  }

  /// Riwayat transaksi koin buat [KoinHistoriScreen] — baca langsung dari
  /// [WalletFunctionsService], tidak dicache di notifier (dibuka jarang,
  /// tidak perlu ikut rebuild tiap [notifyListeners]).
  Future<List<CoinTransaction>> getTransactions() {
    final uid = _uid;
    if (uid == null) return Future.value(const []);
    return _walletFunctions.getTransactions(uid: uid);
  }

  bool ownsCosmetic(String id) => _ownedCosmetics.contains(id);

  /// Beli kosmetik dengan koin (Toko § "Buat monstermu"). Koinnya lewat
  /// [spend] (jadi tetap tunduk validasi delta `firestore.rules`);
  /// kepemilikannya sendiri lokal-murni, mirror pola tiket.
  Future<bool> buyCosmetic({required String id, required int price}) async {
    if (_ownedCosmetics.contains(id)) return true;
    final berhasil = await spend(amount: price, reason: 'cosmetic:$id');
    if (!berhasil) return false;
    _ownedCosmetics = {..._ownedCosmetics, id};
    await _prefs.setOwnedCosmetics(_ownedCosmetics);
    notifyListeners();
    return true;
  }

  /// Beli beberapa kosmetik sekaligus (paket aksesori) dengan SATU potongan
  /// koin [price]. Item yang sudah dimiliki dilewati.
  Future<bool> buyCosmeticBundle({required String bundleId, required List<String> ids, required int price}) async {
    final baru = ids.where((id) => !_ownedCosmetics.contains(id)).toList();
    if (baru.isEmpty) return true;
    final berhasil = await spend(amount: price, reason: 'cosmetic_bundle:$bundleId');
    if (!berhasil) return false;
    _ownedCosmetics = {..._ownedCosmetics, ...baru};
    await _prefs.setOwnedCosmetics(_ownedCosmetics);
    notifyListeners();
    return true;
  }

  /// Beli sesi Mode Fokus prabayar (Toko § "Beli sesi fokus") — dikonsumsi
  /// lewat [consumePrepaidFocusSession] duluan sebelum layar Fokus potong
  /// koin langsung per sesi.
  Future<bool> buyPrepaidFocusSessions({required int count, required int price}) async {
    final berhasil = await spend(amount: price, reason: 'prepaid_focus_sessions:$count');
    if (!berhasil) return false;
    _prepaidFocusSessions += count;
    await _prefs.setPrepaidFocusSessions(_prepaidFocusSessions);
    notifyListeners();
    return true;
  }

  /// true kalau ada sesi prabayar yang terpakai (dan saldo dikurangi) —
  /// false kalau kosong, pemanggil lalu jatuh balik ke potong koin langsung.
  Future<bool> consumePrepaidFocusSession() async {
    if (_prepaidFocusSessions <= 0) return false;
    _prepaidFocusSessions -= 1;
    await _prefs.setPrepaidFocusSessions(_prepaidFocusSessions);
    notifyListeners();
    return true;
  }

  Future<bool> buyStreakShield({required int price}) async {
    final berhasil = await spend(amount: price, reason: 'streak_shield');
    if (!berhasil) return false;
    _streakShieldBalance += 1;
    await _prefs.setStreakShieldBalance(_streakShieldBalance);
    notifyListeners();
    return true;
  }
}
