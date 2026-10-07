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
    final selected = checkInMoods.where((m) => m.id == _draft.moodId).firstOrNull;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CheckInStepHeader(step: 1, showClose: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
                children: [
                  Text(t.moodTitle(userName), style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.15)),
                  const SizedBox(height: 8),
                  Text(t.moodSub, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  const SizedBox(height: AppSpacing.xl),
                  _SelectedMoodCard(mood: selected, hint: t.moodHint),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
              child: Column(
                children: [
                  RiungButton(label: context.s.common.lanjut, onPressed: _draft.moodId == null ? null : _lanjut),
                  TextButton(
                    onPressed: _lewati,
                    child: Text(t.skipToday, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.teksSekunder)),
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

/// Kartu mood terpilih (frame `Mood terpilih`): orb gradien besar + label.
class _SelectedMoodCard extends StatelessWidget {
  const _SelectedMoodCard({required this.mood, required this.hint});

  final CheckInMoodOption? mood;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final m = mood;
    final tint = m == null ? AppColors.netralLembut : (AppColors.moodLembut[m.id] ?? AppColors.netralLembut);
    return RiungGlassCard(
      radius: 36,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [AppColors.diAtasTinta, tint]),
              boxShadow: AppGlass.shadow,
            ),
            alignment: Alignment.center,
            child: Text(m?.emoji ?? '🫧', style: const TextStyle(fontSize: 60)),
          ),
          const SizedBox(height: 8),
          Text(m == null ? ' ' : context.s.checkin.moodLabel(m.id), style: AppTextStyles.title.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(hint, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksRedup)),
        ],
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
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.moodLembut[mood.id] ?? AppColors.netralLembut,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: selected ? 2.5 : 1.5),
                ),
                alignment: Alignment.center,
                child: Text(mood.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                context.s.checkin.moodLabel(mood.id),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.primer : AppColors.teksSekunder),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
