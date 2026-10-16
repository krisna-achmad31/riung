import 'package:flutter/material.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../screens/onboarding_flow_screen.dart';

class AssessmentPendingCard extends StatelessWidget {
  const AssessmentPendingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    return RiungGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const RiungMonster(
                monsterId: 'waswas',
                state: MonsterVisualState.jinak,
                size: 72,
                applyBossScale: false,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(t.pendingTitle, style: AppTextStyles.title)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            t.pendingBody,
            style: AppTextStyles.body.copyWith(color: AppColors.teksSekunder),
          ),
          const SizedBox(height: AppSpacing.lg),
          RiungButton(
            key: const ValueKey('assessment-resume'),
            label: t.resumeAssessment,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const OnboardingFlowScreen(resumeAssessment: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
