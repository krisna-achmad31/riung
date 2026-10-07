import 'package:flutter/material.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/services/kenali_result_repository.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../kenali_dirimu/logic/kenali_navigator.dart';
import '../../kenali_dirimu/logic/kenali_progress.dart';
import '../../kenali_dirimu/screens/kenali_hub_screen.dart';
import '../../minigame/screens/minigame_intro_screen.dart';
import '../logic/habit_monsters.dart';
import '../screens/habit_monster_detail_screen.dart';
import '../screens/habit_stage_map_screen.dart';

/// Tab "Kebiasaan" di brankas (frame `Glass — Monster · Brankas ·
/// Kebiasaan`): sorotan monster yang paling baru bangun, grid monster
/// kebiasaan lainnya (Liar / Jinak / Tertidur), lalu ajakan ke Kenali
/// Dirimu. Monster kebiasaan hanya bangun lewat kuis — bukan dari toko.
class HabitVaultTab extends StatelessWidget {
  const HabitVaultTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([KenaliResultRepository.instance.revision, scope.prefs.habitStageRevision]),
      builder: (context, _) {
        final awake = KenaliProgress.awakeHabitMonsters();
        final spotlight = awake.isEmpty ? null : awake.first;
        final others = [
          for (final id in KenaliDirimuConfig.habitMonsters)
            if (id != spotlight) id,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (spotlight != null) _SpotlightCard(monsterId: spotlight) else const _NoneAwakeCard(),
            const SizedBox(height: AppSpacing.xl),
            Text(context.s.kenali.otherHabits, style: AppTextStyles.title.copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < others.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _HabitCard(monsterId: others[i])),
                      const SizedBox(width: 12),
                      Expanded(child: i + 1 < others.length ? _HabitCard(monsterId: others[i + 1]) : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
            const _KenaliCta(),
          ],
        );
      },
    );
  }
}

void _push(BuildContext context, Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

/// Sorotan "BARU BANGUN · n%": monster 3D besar, asal kuis, progres
/// latihan, tombol Serang & Peta latihan.
class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({required this.monsterId});

  final String monsterId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final scope = AppScope.of(context);
    final progress = scope.monsterProgress.progressOf(monsterId) ?? MonsterProgress.initial(monsterId);
    final isTamed = progress.state == MonsterState.tamed;
    final total = HabitMonsters.practicesOf(monsterId).length;
    final done = (scope.prefs.habitStageDone[monsterId] ?? 0).clamp(0, total);
    final tint = AppColors.monsterLembut[monsterId] ?? AppColors.aksenHangatLembut;

    return GestureDetector(
      onTap: () => _push(context, HabitMonsterDetailScreen(monsterId: monsterId)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tint, Color.lerp(tint, AppColors.aksenHangat, 0.15)!]),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
          boxShadow: AppGlass.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RiungMonster(monsterId: monsterId, state: isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar, size: 190, applyBossScale: false),
                  Positioned(
                    left: 0,
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.aksenHangat, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(t.spotlightKicker(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.diAtasTinta)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(s.common.monsterName(monsterId), style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
            const SizedBox(height: 6),
            Text('${t.habitSpotlight(monsterId)} ${t.wokeFrom(monsterId)}', style: AppTextStyles.caption.copyWith(fontSize: 13, height: 1.45, color: AppColors.teksSekunder)),
            const SizedBox(height: 10),
            RiungProgressBar(value: progress.progress / 100),
            const SizedBox(height: 8),
            Text(t.spotlightProgress(progress.progress, done, total), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: RiungButton(label: s.monster.attack, onPressed: () => _push(context, MinigameIntroScreen(saboteur: HabitMonsters.saboteurFor(monsterId, s))))),
                const SizedBox(width: 10),
                Expanded(child: RiungButton(label: t.stageMapButton, variant: RiungButtonVariant.secondary, onPressed: () => _push(context, HabitStageMapScreen(monsterId: monsterId)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Belum ada monster kebiasaan yang bangun.
class _NoneAwakeCard extends StatelessWidget {
  const _NoneAwakeCard();

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    return RiungGlassCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.noneAwakeTitle, style: AppTextStyles.title.copyWith(fontSize: 17)),
          const SizedBox(height: 6),
          Text(t.noneAwakeBody, style: AppTextStyles.caption.copyWith(fontSize: 13, height: 1.45, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}

/// Kartu grid: Liar (progres), JINAK ("Sekarang temanmu"), atau Tertidur
/// ("Bangun lewat Kuis …" + "Mulai kuis →").
class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.monsterId});

  final String monsterId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final m = s.monster;
    final progress = AppScope.of(context).monsterProgress.progressOf(monsterId) ?? MonsterProgress.initial(monsterId);
    final awake = KenaliProgress.isAwake(monsterId);
    final isTamed = awake && progress.state == MonsterState.tamed;
    final entry = KenaliDirimuConfig.quizForMonster(monsterId);

    return RiungGlassCard(
      onTap: () => _push(context, HabitMonsterDetailScreen(monsterId: monsterId)),
      radius: 28,
      color: isTamed ? AppColors.permukaan : AppColors.kartu,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: awake ? 1 : 0.45,
                  child: RiungMonster(monsterId: monsterId, state: isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar, size: 118, applyBossScale: false),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: isTamed ? AppColors.primer : AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text(
                      isTamed ? m.tamedBadge : (awake ? m.wild : t.asleep),
                      style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: isTamed ? AppColors.diAtasTinta : AppColors.teksSekunder),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(s.common.monsterName(monsterId), style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
          const SizedBox(height: 6),
          if (isTamed)
            Text(m.friendShort, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primer))
          else if (awake) ...[
            RiungProgressBar(value: progress.progress / 100, colors: const [AppColors.aksenHangat, AppColors.aksenHangat]),
            const SizedBox(height: 6),
            Text(m.progressToTamed(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
          ] else ...[
            Text(t.wakeVia(monsterId), style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.35, color: AppColors.teksSekunder)),
            const Spacer(),
            if (entry != null)
              GestureDetector(
                onTap: () => KenaliNavigator.openById(context, entry.id),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(t.startArrow(monsterId), style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primer)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// "Kenali Dirimu — Monster kebiasaan bangun dari kuis — bukan dari toko."
class _KenaliCta extends StatelessWidget {
  const _KenaliCta();

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    return RiungGlassCard(
      onTap: () => _push(context, const KenaliHubScreen()),
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const RiungIcon3D(RiungIcon.kepribadian, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                const SizedBox(height: 2),
                Text(t.ctaBody, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(t.ctaOpen, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primer)),
        ],
      ),
    );
  }
}
