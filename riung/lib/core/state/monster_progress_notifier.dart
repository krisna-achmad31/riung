import 'package:flutter/foundation.dart';

import '../models/monster_progress.dart';
import '../services/user_repository.dart';
import '../services/wallet_functions_service.dart';

/// Notifier global progres penjinakan ke-7 monster milik user saat ini.
class MonsterProgressNotifier extends ChangeNotifier {
  MonsterProgressNotifier({
    required UserRepository userRepository,
    required WalletFunctionsService walletFunctions,
  })  : _userRepository = userRepository,
        _walletFunctions = walletFunctions;

  final UserRepository _userRepository;
  final WalletFunctionsService _walletFunctions;

  Map<String, MonsterProgress> _progress = {};
  String? _uid;

  Map<String, MonsterProgress> get all => _progress;

  MonsterProgress? progressOf(String saboteurId) => _progress[saboteurId];

  Future<void> load(String uid) async {
    _uid = uid;
    _progress = await _userRepository.getMonsterProgress(uid);
    notifyListeners();
  }

  /// Menjamin setiap id di [saboteurIds] punya entri progres (default liar
  /// 0%) tanpa menimpa yang sudah ada — dipakai sekali setelah asesmen
  /// onboarding selesai (semua 7 monster "ada" sejak awal, CBT: semua orang
  /// punya ketujuh pola pikirnya, lihat docs/assessment-scoring-spec.md).
  void ensureAllSaboteurs(Iterable<String> saboteurIds) {
    final next = Map<String, MonsterProgress>.from(_progress);
    var changed = false;
    for (final id in saboteurIds) {
      if (!next.containsKey(id)) {
        next[id] = MonsterProgress.initial(id);
        changed = true;
      }
    }
    if (changed) {
      _progress = next;
      notifyListeners();
    }
  }

  Future<void> tambahProgres({required String saboteurId, required int delta}) async {
    final uid = _uid;
    if (uid == null) return;
    final updated = await _walletFunctions.tameProgress(
      uid: uid,
      saboteurId: saboteurId,
      delta: delta,
    );
    _progress = {..._progress, saboteurId: updated};
    notifyListeners();
  }
}
