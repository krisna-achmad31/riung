import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/state/state.dart';
import '../../../core/services/assessment_draft_store.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../home/screens/root_shell_screen.dart';
import '../../launch/screens/masuk_screen.dart';
import '../logic/onboarding_controller.dart';
import '../logic/onboarding_info_screens.dart';
import '../logic/onboarding_questions.dart';
import '../widgets/analyzing_step.dart';
import '../widgets/free_text_step.dart';
import '../widgets/hasil_asesmen_step.dart';
import '../widgets/info_step.dart';
import '../widgets/nama_step.dart';
import '../widgets/paywall_step.dart';
import '../widgets/question_step.dart';
import '../widgets/welcome_step.dart';

/// Host funnel onboarding — satu [OnboardingController] menyimpan state
/// semua pertanyaan, layar berganti lewat switch atas [OnboardingStepType]
/// (bukan tumpukan Navigator per pertanyaan). Implement persis
/// `design/Onboarding.dc.html`.
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key, this.resumeAssessment = false});
  final bool resumeAssessment;

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen>
    with WidgetsBindingObserver {
  late AppScope _scope;
  int _lastStep = 0;
  OnboardingController? _loadedController;
  OnboardingController get _controller => _loadedController!;
  final _drafts = AssessmentDraftStore();
  String? _uid;
  Timer? _debounce;
  Future<void> _saving = Future.value();
  bool _loadFailed = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _scope = AppScope.of(context);
    WidgetsBinding.instance.addObserver(this);
    _load();
    AppScope.of(context).analytics.onboardingStart();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    _uid = scope.auth.uid;
    try {
      final draft = _uid == null ? null : await _drafts.read(_uid!);
      if (!mounted) return;
      _loadedController = OnboardingController(
        draft: draft,
        resumeAssessment:
            widget.resumeAssessment ||
            (_uid != null && scope.prefs.hasSeenIntroduction(_uid!)),
      )..addListener(_changed);
      setState(() => _loadFailed = false);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _changed() {
    _debounce?.cancel();
    if (_lastStep != _controller.stepIndex) {
      _lastStep = _controller.stepIndex;
      _persist().catchError((Object _) {});
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _persist().catchError((Object _) {});
    });
  }

  Future<void> _persist() {
    final uid = _uid;
    final controller = _loadedController;
    if (uid == null || controller == null || controller.stepIndex == 0) {
      return Future.value();
    }
    final draft = controller.draft;
    final scope = _scope;
    final completed =
        scope.auth.uid == uid &&
        scope.auth.profile?.assessmentCompletedAt != null;
    _saving = _saving.catchError((Object _) {}).then((_) async {
      await scope.prefs.setIntroductionSeen(uid);
      if (completed) {
        await _drafts.clear(uid);
      } else {
        await _drafts.save(uid, draft);
      }
    });
    return _saving;
  }

  Future<void> _pause() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    _debounce?.cancel();
    try {
      await _persist();
      if (mounted) _selesai();
    } catch (_) {
      if (!mounted) return;
      setState(() => _leaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.onboarding.draftSaveError)),
      );
    }
  }

  void _back() {
    if (_controller.stepIndex == 1) {
      _pause();
    } else {
      _controller.back();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    // Capture state before this context is detached. Pending writes stay ordered.
    _persist().catchError((Object _) {});
    _loadedController?.removeListener(_changed);
    _loadedController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _debounce?.cancel();
      _persist().catchError((Object _) {});
    }
  }

  void _goKeMasuk() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MasukScreen()));
  }

  void _selesai() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootShellScreen()),
      (route) => false,
    );
  }

  Widget _buildStep(OnboardingStep step) {
    switch (step.type) {
      case OnboardingStepType.welcome:
        return WelcomeStep(controller: _controller, onMasuk: _goKeMasuk);
      case OnboardingStepType.question:
        return QuestionStep(
          controller: _controller,
          onBack: _back,
          question: onboardingQuestions[step.dataIndex],
        );
      case OnboardingStepType.freeText:
        return FreeTextStep(controller: _controller);
      case OnboardingStepType.nama:
        return NamaStep(controller: _controller);
      case OnboardingStepType.analyzing:
        return AnalyzingStep(controller: _controller);
      case OnboardingStepType.info:
        return InfoStep(
          controller: _controller,
          data: onboardingInfoScreens[step.dataIndex],
        );
      case OnboardingStepType.hasil:
        return HasilAsesmenStep(controller: _controller);
      case OnboardingStepType.paywall:
        return PaywallStep(controller: _controller, onSelesai: _selesai);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadedController == null) {
      return Scaffold(
        body: Center(
          child: _loadFailed
              ? TextButton(
                  onPressed: _load,
                  child: Text(context.s.common.cobaLagi),
                )
              : const CircularProgressIndicator(color: AppColors.primer),
        ),
      );
    }
    return Scaffold(
      bottomNavigationBar: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final type = _controller.currentStep.type;
          if (![
            OnboardingStepType.question,
            OnboardingStepType.freeText,
            OnboardingStepType.nama,
          ].contains(type)) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            top: false,
            child: TextButton(
              key: const ValueKey('assessment-later'),
              onPressed: _leaving ? null : _pause,
              child: Text(context.s.onboarding.fillLater),
            ),
          );
        },
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return PopScope(
            canPop: !_controller.canGoBack,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && _controller.canGoBack) {
                _back();
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_controller.stepIndex),
                child: _buildStep(_controller.currentStep),
              ),
            ),
          );
        },
      ),
    );
  }
}
