import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';
import '../logic/onboarding_info_screens.dart';
import 'onboarding_tag.dart';

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, AppSpacing.sm, 24, AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                if (controller.canGoBack) RiungGlassIconButton(icon: Icons.chevron_left_rounded, onTap: controller.back) else const SizedBox(width: 44),
                const Spacer(),
                GestureDetector(
                  onTap: controller.skipToHasil,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(t.skip, style: AppTextStyles.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teksSekunder)),
                  ),
                ),
              ],
            ),
            Expanded(
              child: RiungBleedListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  Align(alignment: Alignment.centerLeft, child: OnboardingTag(text.kicker, color: data.accentColor)),
                  if (text.big != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(text.big!, style: AppTextStyles.display.copyWith(fontSize: 58, color: data.accentColor, height: 1, letterSpacing: -1)),
                  ],
                  if (data.monsterId != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: (data.monsterWidth ?? 120) * 1.15,
                            height: (data.monsterWidth ?? 120) * 1.15,
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                          ),
                          RiungMonster(monsterId: data.monsterId!, state: data.monsterState, size: data.monsterWidth!, applyBossScale: false),
                        ],
                      ),
                    ),
                  ],
                  if (data.monsterRow != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final id in data.monsterRow!)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.kartu, border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth)),
                            alignment: Alignment.center,
                            child: RiungMonster(monsterId: id, state: MonsterVisualState.liar, size: 54, applyBossScale: false),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(text.title, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
                  const SizedBox(height: AppSpacing.md),
                  Text(text.body, style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.55, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  if (text.src != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(text.src!, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < data.dotTotal; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == data.dotIndex ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(color: i == data.dotIndex ? AppColors.primer : AppColors.permukaan, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            RiungButton(label: text.cta, onPressed: controller.next),
          ],
        ),
      ),
    );
  }
}
