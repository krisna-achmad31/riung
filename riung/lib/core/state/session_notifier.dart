import 'dart:async';

import 'package:flutter/foundation.dart';

/// Kenapa sesi terakhir berhenti — dipakai layar Mode Fokus untuk
/// membedakan "selesai penuh" (tampilkan reward) dari "keluar darurat"
/// (netral, tidak dihitung) tanpa duplikasi state timer.
enum SessionEndReason { none, completed, cancelled }

/// Notifier global sesi Mode Fokus yang sedang berjalan (timer countdown).
/// Integrasi tiket prabayar & blokir aplikasi diimplementasikan di M2+.
class SessionNotifier extends ChangeNotifier {
  Duration? _totalDuration;
  Duration _remaining = Duration.zero;
  Timer? _ticker;
  bool _isActive = false;
  bool _isPaused = false;
  SessionEndReason _endReason = SessionEndReason.none;

  bool get isActive => _isActive;
  bool get isPaused => _isPaused;
  Duration get remaining => _remaining;
  Duration? get totalDuration => _totalDuration;
  SessionEndReason get endReason => _endReason;

  void start(Duration duration) {
    _ticker?.cancel();
    _totalDuration = duration;
    _remaining = duration;
    _isActive = true;
    _isPaused = false;
    _endReason = SessionEndReason.none;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    if (_remaining <= const Duration(seconds: 1)) {
      complete();
      return;
    }
    _remaining -= const Duration(seconds: 1);
    notifyListeners();
  }

  void pause() {
    if (!_isActive || _isPaused) return;
    _ticker?.cancel();
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    if (!_isActive || !_isPaused) return;
    _isPaused = false;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void complete() {
    _ticker?.cancel();
    _remaining = Duration.zero;
    _isActive = false;
    _isPaused = false;
    _endReason = SessionEndReason.completed;
    notifyListeners();
  }

  void cancel() {
    _ticker?.cancel();
    _totalDuration = null;
    _remaining = Duration.zero;
    _isActive = false;
    _isPaused = false;
    _endReason = SessionEndReason.cancelled;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
