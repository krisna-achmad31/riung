import 'package:flutter/foundation.dart';

import '../services/user_repository.dart';

/// Notifier global streak check-in harian. Hanya mengurus state streak —
/// mutasi koin check-in dilakukan lewat [WalletNotifier.earn] oleh
/// pemanggil (lihat `BerandaScreen`), supaya saldo koin selalu punya SATU
/// sumber kebenaran (WalletNotifier) yang bisa dipercaya UI mana pun.
class StreakNotifier extends ChangeNotifier {
  StreakNotifier({required UserRepository userRepository}) : _userRepository = userRepository;

  final UserRepository _userRepository;

  int _current = 0;
  int _longest = 0;
  DateTime? _lastCheckinDate;
  String? _uid;

  int get current => _current;
  int get longest => _longest;
  DateTime? get lastCheckinDate => _lastCheckinDate;

  bool get sudahCheckinHariIni {
    final last = _lastCheckinDate;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  Future<void> load(String uid) async {
    _uid = uid;
    final profile = await _userRepository.getUserProfile(uid);
    _current = profile.streakCurrent;
    _longest = profile.streakLongest;
    _lastCheckinDate = profile.lastCheckinDate;
    notifyListeners();
  }

  /// Menandai check-in hari ini selesai. Koin check-in TIDAK ditambahkan
  /// di sini — pemanggil bertanggung jawab memanggil
  /// `WalletNotifier.earn(...)` juga (lihat [sudahCheckinHariIni] untuk
  /// mencegah panggil dobel).
  void checkInHariIni() {
    if (_uid == null || sudahCheckinHariIni) return;
    _current += 1;
    if (_current > _longest) _longest = _current;
    _lastCheckinDate = DateTime.now();
    notifyListeners();
  }
}
