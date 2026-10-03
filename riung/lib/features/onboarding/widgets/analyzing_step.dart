import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';

/// Layar "sedang menganalisis" — 3 detik, lalu hitung skor & lanjut ke
/// hasil. Implement persis `design/Onboarding.dc.html` § Menganalisis.
class AnalyzingStep extends StatefulWidget {
  const AnalyzingStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  State<AnalyzingStep> createState() => _AnalyzingStepState();
}

class _AnalyzingStepState extends State<AnalyzingStep> {
  @override
  void initState() {
    super.initState();
    _proceed();
  }

  Future<void> _proceed() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    widget.controller.computeResult();
    final result = widget.controller.result;
    if (result != null) {
      AppScope.of(context).analytics.assessmentResult(
            bossSaboteur: 'hakim',
            dominantSaboteurs: result.dominantSaboteurs,
          );
    }
    widget.controller.next();
  }

  @override
  Widget build(BuildContext context) {
    final nama = widget.controller.nama.trim();
    final t = context.s.onboarding;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        strokeWidth: 5,
                        backgroundColor: AppColors.kartu,
                        valueColor: AlwaysStoppedAnimation(AppColors.primer),
                      ),
                    ),
                    SizedBox(
                      width: 88,
                      height: 92,
                      child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.liar, size: 88, applyBossScale: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                t.analyzingTitle(nama),
                textAlign: TextAlign.center,
                style: AppTextStyles.display.copyWith(fontSize: 21),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ChecklistRow(text: t.analyzingRead, done: true),
              const SizedBox(height: AppSpacing.sm),
              _ChecklistRow(text: t.analyzingMatch, done: true),
              const SizedBox(height: AppSpacing.sm),
              _ChecklistRow(text: t.analyzingPlan, done: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text, required this.done});

  final String text;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 17,
          height: 17,
          child: done
              ? const Icon(Icons.check_circle, size: 17, color: AppColors.sukses)
              : const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  backgroundColor: AppColors.garis,
                  valueColor: AlwaysStoppedAnimation(AppColors.primer),
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: done ? AppColors.teksSekunder : AppColors.teksRedup,
          ),
        ),
      ],
    );
  }
}
