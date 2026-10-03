import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';
import '../logic/onboarding_questions.dart';

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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                if (controller.canGoBack)
                  IconButton(
                    onPressed: controller.back,
                    icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: question.number / onboardingQuestions.length,
                      minHeight: 8,
                      backgroundColor: AppColors.kartu,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primer),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${question.number}/${onboardingQuestions.length}',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.question,
                    style: AppTextStyles.display.copyWith(fontSize: 23, height: 1.3),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(text.sub, style: AppTextStyles.caption.copyWith(fontSize: 13.5)),
                  const SizedBox(height: AppSpacing.lg),
                  for (var i = 0; i < question.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _OptionRow(
                        option: question.options[i],
                        label: text.options[i],
                        selected: controller.isSelected(question.number, i),
                        multi: question.isMulti,
                        onTap: () => controller.toggleAnswer(question, i),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
            child: RiungButton(
              label: context.s.common.lanjut,
              onPressed: controller.canProceed
                  ? () {
                      AppScope.of(context).analytics.qAnswered(questionNumber: question.number);
                      controller.next();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.option, required this.label, required this.selected, required this.multi, required this.onTap});

  final QuestionOption option;
  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primer.withValues(alpha: 0.12) : AppColors.permukaan,
          border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: 1.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(option.emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14.5, height: 1.4),
              ),
            ),
            if (multi) _CheckBox(selected: selected) else _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.primer : Colors.transparent,
        border: Border.all(color: selected ? AppColors.primer : AppColors.teksRedup, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: selected ? const Icon(Icons.check, size: 14, color: AppColors.latar) : null,
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.primer : AppColors.teksRedup, width: 2),
      ),
      child: selected
          ? Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primer),
            )
          : null,
    );
  }
}
