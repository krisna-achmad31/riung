import 'package:flutter/foundation.dart';

import '../../../core/state/app_scope.dart';
import 'onboarding_info_screens.dart';
import 'onboarding_questions.dart';
import 'scoring_engine.dart';

enum OnboardingStepType { welcome, question, freeText, nama, analyzing, info, hasil, paywall }

class OnboardingStep {
  const OnboardingStep(this.type, [this.dataIndex = 0]);
  final OnboardingStepType type;

  /// Indeks 0-based ke [onboardingQuestions] (type=question) atau
  /// [onboardingInfoScreens] (type=info). Diabaikan untuk step lain.
  final int dataIndex;
}

/// Urutan lengkap funnel onboarding — RateUs sengaja TIDAK ada di sini
/// (dipicu di momen nilai lain, lihat `design/Onboarding.dc.html` catatan
/// "bukan mid-onboarding"; widget-nya tetap dibangun di
/// `widgets/rate_us_step.dart` untuk dipakai nanti).
final List<OnboardingStep> onboardingSteps = [
  const OnboardingStep(OnboardingStepType.welcome),
  for (var i = 0; i < onboardingQuestions.length; i++) OnboardingStep(OnboardingStepType.question, i),
  const OnboardingStep(OnboardingStepType.freeText),
  const OnboardingStep(OnboardingStepType.nama),
  const OnboardingStep(OnboardingStepType.analyzing),
  for (var i = 0; i < onboardingInfoScreens.length; i++) OnboardingStep(OnboardingStepType.info, i),
  const OnboardingStep(OnboardingStepType.hasil),
  const OnboardingStep(OnboardingStepType.paywall),
];

/// Controller state machine funnel onboarding — satu instance per sesi
/// onboarding, dipegang [OnboardingFlowScreen]. Menyimpan semua jawaban,
/// menghitung skor lewat [ScoringEngine], dan mempersist hasilnya ke
/// [AuthNotifier] + [MonsterProgressNotifier] saat asesmen selesai.
class OnboardingController extends ChangeNotifier {
  int _stepIndex = 0;
  final Map<int, Set<int>> _answers = {};
  String _freeText = '';
  String _nama = '';
  AssessmentResult? _result;

  int get stepIndex => _stepIndex;
  int get totalSteps => onboardingSteps.length;
  OnboardingStep get currentStep => onboardingSteps[_stepIndex];
  String get freeText => _freeText;
  String get nama => _nama;
  AssessmentResult? get result => _result;

  Set<int> answersFor(int questionNumber) => _answers[questionNumber] ?? const <int>{};

  bool isSelected(int questionNumber, int optionIndex) =>
      answersFor(questionNumber).contains(optionIndex);

  void toggleAnswer(OnboardingQuestion question, int optionIndex) {
    final current = Set<int>.from(_answers[question.number] ?? const <int>{});
    if (question.isMulti) {
      if (!current.remove(optionIndex)) current.add(optionIndex);
    } else {
      current
        ..clear()
        ..add(optionIndex);
    }
    _answers[question.number] = current;
    notifyListeners();
  }

  bool get canProceed {
    final step = currentStep;
    switch (step.type) {
      case OnboardingStepType.question:
        final question = onboardingQuestions[step.dataIndex];
        return answersFor(question.number).isNotEmpty;
      case OnboardingStepType.freeText:
        return _freeText.trim().isNotEmpty;
      case OnboardingStepType.nama:
        return _nama.trim().isNotEmpty;
      default:
        return true;
    }
  }

  void setFreeText(String value) {
    _freeText = value;
    notifyListeners();
  }

  void setNama(String value) {
    _nama = value;
    notifyListeners();
  }

  void next() {
    if (_stepIndex < onboardingSteps.length - 1) {
      _stepIndex++;
      notifyListeners();
    }
  }

  bool get canGoBack => _stepIndex > 0;

  void back() {
    if (canGoBack) {
      _stepIndex--;
      notifyListeners();
    }
  }

  /// Lompat langsung dari layar info manapun ke Hasil asesmen ("Lewati").
  void skipToHasil() {
    final index = onboardingSteps.indexWhere((s) => s.type == OnboardingStepType.hasil);
    if (index != -1) {
      _stepIndex = index;
      notifyListeners();
    }
  }

  void computeResult() {
    _result = const ScoringEngine().score(_answers);
    notifyListeners();
  }

  static const _personaByQ1 = ['pelajar', 'mahasiswa', 'pekerja', 'lainnya'];

  String? get _persona {
    final selected = _answers[1];
    if (selected == null || selected.isEmpty) return null;
    final index = selected.first;
    return index >= 0 && index < _personaByQ1.length ? _personaByQ1[index] : null;
  }

  /// Mempersist hasil asesmen: profil (nama, persona, skor, anak buah
  /// dominan, onboardingDone) + inisialisasi 7 slot monster. Dipanggil
  /// sekali dari CTA "Mulai jinakkan Si Hakim" di [HasilAsesmenStep].
  Future<void> completeOnboarding(AppScope scope) async {
    final result = _result ?? const ScoringEngine().score(_answers);
    _result = result;

    await scope.auth.updateProfile((current) => current.copyWith(
          displayName: _nama.trim().isEmpty ? current.displayName : _nama.trim(),
          persona: _persona ?? current.persona,
          onboardingDone: true,
          dominantSaboteurs: result.dominantSaboteurs,
          assessmentScores: result.scores,
          assessmentCompletedAt: DateTime.now(),
        ));
    scope.monsterProgress.ensureAllSaboteurs(ScoringEngine.allSaboteurs);
  }
}
