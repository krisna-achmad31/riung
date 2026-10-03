import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';

/// Layar pembuka funnel — intro konsep monster + CTA mulai. Implement
/// persis `design/Onboarding.dc.html` § Welcome.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.controller, required this.onMasuk});

  final OnboardingController controller;
  final VoidCallback onMasuk;

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    return RiungGlowBackground(
      alignment: const Alignment(0, -0.65),
      opacity: 0.22,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: TextButton.icon(
                  onPressed: () => showBahasaSheet(context),
                  icon: const Icon(Icons.language_rounded, size: 16, color: AppColors.teksSekunder),
                  label: Text(
                    context.s.language.nativeName,
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 74,
                          height: 78,
                          child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 74),
                        ),
                        SizedBox(width: 4),
                        SizedBox(
                          width: 120,
                          height: 126,
                          child: RiungMonster(
                            monsterId: 'hakim',
                            state: MonsterVisualState.jinak,
                            size: 120,
                            applyBossScale: false,
                          ),
                        ),
                        SizedBox(width: 4),
                        SizedBox(
                          width: 74,
                          height: 78,
                          child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 74),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      t.welcomeTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.25),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.welcomeBody,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
              child: Column(
                children: [
                  RiungButton(label: t.welcomeStart, onPressed: controller.next),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: onMasuk,
                    behavior: HitTestBehavior.opaque,
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.caption.copyWith(fontSize: 13),
                        children: [
                          TextSpan(text: t.haveAccountPrefix),
                          TextSpan(text: t.signInLink, style: const TextStyle(color: AppColors.primer, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
