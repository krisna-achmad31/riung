import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../minigame/screens/minigame_intro_screen.dart';
import '../logic/habit_monsters.dart';
import '../widgets/waswas_stage_path.dart';
import 'habit_practice_screen.dart';

/// Peta latihan Monster Kebiasaan (frame `Glass — Monster · Si … · Peta`):
/// tiga latihan BERURUTAN (level berikutnya terbuka setelah yang sebelumnya
/// selesai, tersimpan lintas hari di `prefs.habitStageDone`), lalu node bos
/// yang membuka alur serangan biasa.
class HabitStageMapScreen extends StatelessWidget {
  const HabitStageMapScreen({super.key, required this.monsterId});

  final String monsterId;

  Future<void> _buka(BuildContext context, int index) async {
    final prefs = AppScope.of(context).prefs;
    final selesai = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => HabitPracticeScreen(monsterId: monsterId, index: index)),
    );
    final done = prefs.habitStageDone[monsterId] ?? 0;
    if (selesai == true && index >= done) await prefs.setHabitStageDone(monsterId, index + 1);
  }

  void _hadapi(BuildContext context) {
    final saboteur = HabitMonsters.saboteurFor(monsterId, context.s);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MinigameIntroScreen(saboteur: saboteur)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final m = s.monster;
    final scope = AppScope.of(context);
    final name = s.common.monsterName(monsterId);
    final practices = HabitMonsters.practicesOf(monsterId);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([scope.monsterProgress, scope.prefs.habitStageRevision]),
          builder: (context, _) {
            final progress = scope.monsterProgress.progressOf(monsterId) ?? MonsterProgress.initial(monsterId);
            final done = (scope.prefs.habitStageDone[monsterId] ?? 0).clamp(0, practices.length);
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
              children: [
                RiungGlassHeader(title: t.stageTitle(name)),
                const SizedBox(height: AppSpacing.md),
                Text(m.stageMapIntro, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSpacing.md),
                RiungOwlTip(message: t.habitOwl(monsterId)),
                const SizedBox(height: AppSpacing.md),
                WaswasStagePath(
                  steps: [
                    for (var i = 0; i < practices.length; i++)
                      StageStep(
                        icon: practices[i].icon,
                        caption: i < done ? '${m.stageLevelLabel(i + 1)} · ${m.stageNodeLabelDone}' : m.stageLevelLabel(i + 1),
                        title: t.practiceTitle(monsterId, i),
                        subtitle: i < done ? t.stepDone : (i == done ? m.stageNodeStartHere : t.lockedAfter(i)),
                        status: i < done ? StageNodeStatus.done : (i == done ? StageNodeStatus.current : StageNodeStatus.upcoming),
                        // Level berikutnya terkunci sampai level sebelumnya selesai.
                        onTap: i <= done ? () => _buka(context, i) : () {},
                      ),
                  ],
                  boss: StageBoss(
                    monsterId: monsterId,
                    caption: m.stageNodeBossLabel(progress.progress),
                    title: t.faceMonster(name),
                    subtitle: m.stageNodeBossSub(progress.progress),
                    onTap: () => _hadapi(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
