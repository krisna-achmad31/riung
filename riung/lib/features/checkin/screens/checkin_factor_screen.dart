import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/checkin_draft.dart';
import '../logic/checkin_options.dart';
import '../widgets/checkin_step_header.dart';
import 'checkin_note_screen.dart';

/// Langkah 2/3 — pilih maksimal 3 faktor. Implement persis
/// `design/Checkin.dc.html` § Pilih faktor.
class CheckInFactorScreen extends StatefulWidget {
  const CheckInFactorScreen({super.key, required this.draft});

  final CheckInDraft draft;

  @override
  State<CheckInFactorScreen> createState() => _CheckInFactorScreenState();
}

class _CheckInFactorScreenState extends State<CheckInFactorScreen> {
  static const _maxFactors = 3;

  void _toggle(String id) {
    setState(() {
      if (widget.draft.factorIds.contains(id)) {
        widget.draft.factorIds.remove(id);
      } else if (widget.draft.factorIds.length < _maxFactors) {
        widget.draft.factorIds.add(id);
      }
    });
  }

  void _lanjut() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CheckInNoteScreen(draft: widget.draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.checkin;
    CheckInMoodOption? mood;
    for (final m in checkInMoods) {
      if (m.id == widget.draft.moodId) {
        mood = m;
        break;
      }
    }
    final showHakimInsight =
        widget.draft.factorIds.contains('kerjaan') && widget.draft.factorIds.contains('takut_gagal');

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            CheckInStepHeader(step: 2, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (mood != null) Text(mood.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            t.factorTitle,
                            style: AppTextStyles.display.copyWith(fontSize: 20, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.factorSub,
                      style: AppTextStyles.caption.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final factor in checkInFactors)
                          _FactorChip(
                            factor: factor,
                            selected: widget.draft.factorIds.contains(factor.id),
                            onTap: () => _toggle(factor.id),
                          ),
                      ],
                    ),
                    if (showHakimInsight) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.monsterHakim.withValues(alpha: 0.08),
                          border: Border.all(color: AppColors.monsterHakim.withValues(alpha: 0.25)),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 40,
                              height: 42,
                              child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.liar, size: 40, applyBossScale: false),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                t.hakimInsight,
                                style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontSize: 12, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: RiungButton(
                label: context.s.common.lanjut,
                onPressed: widget.draft.factorIds.isEmpty ? null : _lanjut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactorChip extends StatelessWidget {
  const _FactorChip({required this.factor, required this.selected, required this.onTap});

  final CheckInFactorOption factor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: 1.5),
          color: selected ? AppColors.primer.withValues(alpha: 0.14) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(factor.icon, size: 15, color: selected ? AppColors.primer : AppColors.teksSekunder),
            const SizedBox(width: 7),
            Text(
              context.s.checkin.factorLabel(factor.id),
              style: AppTextStyles.chipLabel.copyWith(
                fontSize: 13,
                color: selected ? AppColors.primer : AppColors.teksSekunder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
