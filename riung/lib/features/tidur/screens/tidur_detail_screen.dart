import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/sleep_catalog.dart';
import 'tidur_player_screen.dart';

/// Detail cerita tidur. Implement persis `design/Tidur.dc.html`
/// § Detail cerita.
class TidurDetailScreen extends StatefulWidget {
  const TidurDetailScreen({super.key, required this.story});

  final SleepStory story;

  @override
  State<TidurDetailScreen> createState() => _TidurDetailScreenState();
}

class _TidurDetailScreenState extends State<TidurDetailScreen> {
  int _timerMinutes = sleepTimerPresets.first;

  void _putar() {
    final scope = AppScope.of(context);
    final premiumActive = scope.auth.profile?.premiumNow ?? false;
    if (!SleepCatalog.isStoryFree(widget.story.id) && !premiumActive) {
      final t = scope.language.strings.tidur;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PremiumLockedScreen(
            title: t.story(widget.story.id).title,
            freeTierNote: t.freeTierNote(EconomyFreeTier.ceritaTidur),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TidurPlayerScreen(story: widget.story, timerMinutes: _timerMinutes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final t = context.s.tidur;
    final text = t.story(story.id);
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        alignment: const Alignment(0, -1.2),
        opacity: 0.12,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder)),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.alreadyOffline))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.kartu, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.download_done_rounded, size: 14, color: AppColors.teksSekunder),
                            const SizedBox(width: 6),
                            Text(t.download, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
                      SizedBox(width: 118, height: 124, child: RiungMonster(monsterId: story.targetMonsterId, state: MonsterVisualState.jinak, size: 118)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.kicker(story.durationMinutes),
                        style: AppTextStyles.caption.copyWith(color: AppColors.monsterCermin, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 10),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(text.title, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 23, height: 1.3)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(text.description, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.6)),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.lg)),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.primer, AppColors.sekunder])),
                              alignment: Alignment.center,
                              child: Text(
                                story.reader.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join(),
                                style: AppTextStyles.chipLabel.copyWith(color: AppColors.latar, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.readBy(story.reader), style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 13)),
                                  Text(t.sourceNote, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(t.timerTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          for (final minutes in sleepTimerPresets)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: minutes == sleepTimerPresets.last ? 0 : AppSpacing.sm),
                                child: GestureDetector(
                                  onTap: () => setState(() => _timerMinutes = minutes),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: minutes == _timerMinutes ? AppColors.primer : AppColors.garis, width: 1.5),
                                      color: minutes == _timerMinutes ? AppColors.primer.withValues(alpha: 0.12) : Colors.transparent,
                                    ),
                                    child: Text(
                                      t.minutes(minutes),
                                      style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: minutes == _timerMinutes ? AppColors.primer : AppColors.teksSekunder),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
                child: RiungButton(label: t.playStory, onPressed: _putar),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
