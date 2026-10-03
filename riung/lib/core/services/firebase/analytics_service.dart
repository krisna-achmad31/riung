import 'package:firebase_analytics/firebase_analytics.dart';

/// Wrapper tipis di atas Firebase Analytics — 10 event inti (M5 Task 5):
/// `onboarding_start`, `q_answered`, `assessment_result`, `paywall_view`,
/// `purchase`, `focus_start`, `focus_complete`, `checkin_done`,
/// `monster_tamed`, `minigame_complete`. `FirebaseAnalytics.instance`
/// sengaja ditunda ke tiap panggilan (bukan constructor) dan dibungkus
/// try/catch — aman dipanggil di mana pun (termasuk sebelum
/// `Firebase.initializeApp()`, mis. widget test), gagal diam-diam kalau
/// tidak ada App terdaftar.
class AnalyticsService {
  AnalyticsService();

  FirebaseAnalytics? _instance() {
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> _log(String name, [Map<String, Object>? parameters]) async {
    try {
      await _instance()?.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Analytics tidak boleh pernah menggagalkan alur utama app.
    }
  }

  Future<void> onboardingStart() => _log('onboarding_start');

  Future<void> qAnswered({required int questionNumber}) =>
      _log('q_answered', {'question_number': questionNumber});

  Future<void> assessmentResult({required String bossSaboteur, required List<String> dominantSaboteurs}) =>
      _log('assessment_result', {'boss_saboteur': bossSaboteur, 'dominant_saboteurs': dominantSaboteurs.join(',')});

  Future<void> paywallView({required String source}) => _log('paywall_view', {'source': source});

  Future<void> purchase({required String productId, required num valueIdr, String currency = 'IDR'}) =>
      _log('purchase', {'product_id': productId, 'value': valueIdr, 'currency': currency});

  Future<void> focusStart({required int durationMinutes}) =>
      _log('focus_start', {'duration_minutes': durationMinutes});

  Future<void> focusComplete({required int durationMinutes}) =>
      _log('focus_complete', {'duration_minutes': durationMinutes});

  Future<void> checkinDone({required String mood}) => _log('checkin_done', {'mood': mood});

  Future<void> monsterTamed({required String saboteurId}) => _log('monster_tamed', {'saboteur_id': saboteurId});

  Future<void> minigameComplete({required String saboteurId, required bool won}) =>
      _log('minigame_complete', {'saboteur_id': saboteurId, 'won': won.toString()});
}
