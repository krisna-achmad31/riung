import 'package:flutter/material.dart';

import '../../../core/state/state.dart';
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
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  late final OnboardingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController();
    AppScope.of(context).analytics.onboardingStart();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goKeMasuk() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MasukScreen()));
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
        return QuestionStep(controller: _controller, question: onboardingQuestions[step.dataIndex]);
      case OnboardingStepType.freeText:
        return FreeTextStep(controller: _controller);
      case OnboardingStepType.nama:
        return NamaStep(controller: _controller);
      case OnboardingStepType.analyzing:
        return AnalyzingStep(controller: _controller);
      case OnboardingStepType.info:
        return InfoStep(controller: _controller, data: onboardingInfoScreens[step.dataIndex]);
      case OnboardingStepType.hasil:
        return HasilAsesmenStep(controller: _controller);
      case OnboardingStepType.paywall:
        return PaywallStep(controller: _controller, onSelesai: _selesai);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return PopScope(
            canPop: !_controller.canGoBack,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && _controller.canGoBack) {
                _controller.back();
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
