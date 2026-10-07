import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';
import '../logic/onboarding_questions.dart';
import 'onboarding_header.dart';
import 'onboarding_tag.dart';

/// Renderer generik Q1–Q17 — satu template dipakai untuk semua pertanyaan
/// (single & multi-select), termasuk varian scrollable (Q3/Q7/Q11 dengan
/// banyak opsi menggulir wajar lewat `SingleChildScrollView`).
/// Implement persis `design/Onboarding.dc.html` § Asesmen.
class QuestionStep extends StatelessWidget {
  const QuestionStep({super.key, required this.controller, required this.question});

  final OnboardingController controller;
  final OnboardingQuestion question;

  @override
  Widget build(BuildContext context) {
    final text = context.s.onboarding.questions[question.number - 1];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, AppSpacing.sm, 24, AppSpacing.md),
        child: Column(
          children: [
            OnboardingHeader(
              progress: question.number / onboardingQuestions.length,
              onBack: controller.canGoBack ? controller.back : null,
              trailing: '${question.number}/${onboardingQuestions.length}',
            ),
            Expanded(
              child: RiungBleedListView(
                padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                children: [
                  Align(alignment: Alignment.centerLeft, child: OnboardingTag(text.tag)),
                  const SizedBox(height: AppSpacing.md),
                  Text(text.question, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.15)),
                  const SizedBox(height: 6),
                  Text(text.sub, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  const SizedBox(height: AppSpacing.md),
                  if (!question.isMulti) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RiungMonster(monsterId: _monsterFor(question.number), state: MonsterVisualState.jinak, size: 110, applyBossScale: false),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  for (var i = 0; i < question.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _OptionRow(
                        label: text.options[i],
                        selected: controller.isSelected(question.number, i),
                        multi: question.isMulti,
                        onTap: () => controller.toggleAnswer(question, i),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            RiungButton(
              label: context.s.common.lanjut,
              onPressed: controller.canProceed
                  ? () {
                      AppScope.of(context).analytics.qAnswered(questionNumber: question.number);
                      controller.next();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Monster penemani pertanyaan pilihan tunggal — bergilir supaya tiap
  /// pertanyaan terasa berbeda (frame Kuis pilihan memakai Si Waswas).
  static String _monsterFor(int number) => const ['waswas', 'kabut', 'cermin', 'meronta', 'sempurna', 'mengelak'][(number - 1) % 6];
}

/// Opsi jawaban (frame `Opsi …`): kaca, tebal + bingkai primer saat dipilih;
/// tanda bulat (pilihan tunggal) atau kotak (multi).
class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.selected, required this.multi, required this.onTap});

  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.permukaanPadat.withValues(alpha: 0.9) : AppColors.kartu,
          border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: selected ? 2 : AppGlass.edgeWidth),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 15, height: 1.3, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? AppColors.primer : Colors.transparent,
                border: Border.all(color: selected ? AppColors.primer : AppColors.teksRedup, width: 1.5),
                borderRadius: BorderRadius.circular(multi ? 8 : 12),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 14, color: AppColors.diAtasTinta) : null,
            ),
          ],
        ),
      ),
    );
  }
}
