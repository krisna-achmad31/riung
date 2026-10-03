import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/checkin_draft.dart';
import '../logic/checkin_options.dart';
import '../widgets/checkin_step_header.dart';
import 'checkin_factor_screen.dart';

/// Langkah 1/3 — pilih mood. Implement persis `design/Checkin.dc.html`
/// § Pilih mood.
class CheckInMoodScreen extends StatefulWidget {
  const CheckInMoodScreen({super.key});

  @override
  State<CheckInMoodScreen> createState() => _CheckInMoodScreenState();
}

class _CheckInMoodScreenState extends State<CheckInMoodScreen> {
  final _draft = CheckInDraft();

  void _lanjut() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CheckInFactorScreen(draft: _draft)),
    );
  }

  void _lewati() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.checkin;
    final userName = AppScope.of(context).auth.profile?.displayName ?? context.s.home.defaultUserName;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        alignment: const Alignment(0, -1.1),
        opacity: 0.16,
        child: SafeArea(
          child: Column(
            children: [
              const CheckInStepHeader(step: 1, showClose: true),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 96,
                        height: 100,
                        child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 96),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        t.moodTitle(userName),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display.copyWith(fontSize: 23, height: 1.3),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.moodSub,
                        style: AppTextStyles.caption.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final mood in checkInMoods)
                            _MoodOption(
                              mood: mood,
                              selected: _draft.moodId == mood.id,
                              onTap: () => setState(() => _draft.moodId = mood.id),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
                child: Column(
                  children: [
                    RiungButton(label: context.s.common.lanjut, onPressed: _draft.moodId == null ? null : _lanjut),
                    TextButton(
                      onPressed: _lewati,
                      child: Text(
                        t.skipToday,
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({required this.mood, required this.selected, required this.onTap});

  final CheckInMoodOption mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: 1.5),
          color: selected ? AppColors.primer.withValues(alpha: 0.14) : AppColors.permukaan,
        ),
        child: Column(
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 7),
            Text(
              context.s.checkin.moodLabel(mood.id),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primer : AppColors.teksSekunder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
