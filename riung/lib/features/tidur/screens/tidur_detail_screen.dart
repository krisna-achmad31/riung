import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/sleeping_monster.dart';
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
      body: RiungGlassBackdrop(
        night: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              children: [
                RiungGlassHeader(
                  title: '',
                  night: true,
                  trailing: RiungGlassIconButton(
                    icon: Icons.download_done_rounded,
                    night: true,
                    semanticLabel: t.download,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.alreadyOffline))),
                  ),
                ),
                Expanded(
                  child: RiungBleedListView(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    children: [
                      SleepingMonster(monsterId: story.targetMonsterId, size: 200, glow: 260),
                      const SizedBox(height: AppSpacing.lg),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppNight.aksenLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                          child: Text(t.kicker(story.durationMinutes), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.kabutLavender)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(text.title, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.2, color: AppNight.teks)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(t.readBy(story.reader), style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppNight.teksSekunder)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(text.description, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5, color: AppNight.teksSekunder)),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AppNight.card(radius: 20),
                        child: Row(
                          children: [
                            const Icon(Icons.translate_rounded, size: 16, color: AppNight.aksen),
                            const SizedBox(width: 10),
                            Expanded(child: Text(t.sourceNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppNight.teksSekunder))),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(t.timerTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppNight.teksSekunder)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final minutes in sleepTimerPresets)
                            RiungFilterChip(
                              label: t.minutes(minutes),
                              selected: minutes == _timerMinutes,
                              night: true,
                              onTap: () => setState(() => _timerMinutes = minutes),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                RiungButton(label: t.playStory, icon: Icons.play_arrow_rounded, variant: RiungButtonVariant.night, onPressed: _putar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
