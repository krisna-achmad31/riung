import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';
import '../logic/onboarding_info_screens.dart';

/// Renderer generik untuk 11 layar info (reality check, masalahmu, dampak,
/// cara Riung membantu) — satu template, beda konten/aksen per [data].
/// Implement persis `design/Onboarding.dc.html` §§ tersebut.
class InfoStep extends StatelessWidget {
  const InfoStep({super.key, required this.controller, required this.data});

  final OnboardingController controller;
  final OnboardingInfoScreen data;

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    final text = t.infoScreens[onboardingInfoScreens.indexOf(data)];
    return RiungGlowBackground(
      glowColor: data.glowColor,
      alignment: const Alignment(0, -0.7),
      opacity: 0.2,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                child: GestureDetector(
                  onTap: controller.skipToHasil,
                  behavior: HitTestBehavior.opaque,
                  child: Text(t.skip, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text.kicker.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: data.accentColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                    if (text.big != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        text.big!,
                        style: AppTextStyles.display.copyWith(fontSize: 58, color: data.accentColor, height: 1, letterSpacing: -1),
                      ),
                    ],
                    if (data.monsterId != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: data.monsterWidth,
                        height: data.monsterHeight,
                        child: RiungMonster(
                          monsterId: data.monsterId!,
                          state: data.monsterState,
                          size: data.monsterWidth!,
                          applyBossScale: false,
                        ),
                      ),
                    ],
                    if (data.monsterRow != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          for (final id in data.monsterRow!)
                            SizedBox(
                              width: 62,
                              height: 65,
                              child: RiungMonster(monsterId: id, state: MonsterVisualState.liar, size: 62, applyBossScale: false),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(text.title, style: AppTextStyles.display.copyWith(fontSize: 22, height: 1.32)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(text.body, style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.6)),
                    if (text.src != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.garis),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(text.src!, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < data.dotTotal; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == data.dotIndex ? AppColors.primer : AppColors.garis,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RiungButton(label: text.cta, onPressed: controller.next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
