import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../betterme/data/betterme_content.dart';
import '../../betterme/screens/level_intro_screen.dart';
import '../../minigame/screens/minigame_intro_screen.dart';
import '../logic/saboteur_content.dart';

const _minionIds = ['kabut', 'waswas', 'meronta', 'cermin', 'sempurna', 'mengelak'];

/// Detail khusus Si Hakim (bos) — layout "SANG BOS": ilustrasi lebih besar,
/// strip anak buah, dua CTA. Implement persis `design/Monster.dc.html`
/// § Detail bos — Si Hakim.
class HakimDetailScreen extends StatelessWidget {
  const HakimDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.monster;
    final content = saboteurContentFor('hakim', t)!;

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: FutureBuilder<List<Saboteur>>(
          future: scope.contentRepository.getSaboteurs(),
          builder: (context, snapshot) {
            return ListenableBuilder(
              listenable: scope.monsterProgress,
              builder: (context, _) {
                final progress = scope.monsterProgress.progressOf('hakim') ?? MonsterProgress.initial('hakim');
                final isTamed = progress.state == MonsterState.tamed;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder)),
                          Expanded(child: Text(context.s.common.monsterName('hakim'), style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.monsterHakim), borderRadius: BorderRadius.circular(AppRadius.pill)),
                            child: Text(t.bossPercent(progress.progress), style: AppTextStyles.caption.copyWith(color: AppColors.monsterHakim, fontWeight: FontWeight.w700, fontSize: 10)),
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
                            Column(
                              children: [
                                SizedBox(
                                  width: 172,
                                  height: 181,
                                  child: RiungMonster(
                                    monsterId: 'hakim',
                                    state: isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar,
                                    size: 172,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  t.hakimIntro,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.55),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                      child: LinearProgressIndicator(
                                        value: progress.progress / 100,
                                        minHeight: 9,
                                        backgroundColor: AppColors.permukaan,
                                        valueColor: const AlwaysStoppedAnimation(AppColors.monsterHakim),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(t.wild, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                                        Text('${progress.progress}%', style: AppTextStyles.caption.copyWith(color: AppColors.monsterHakim, fontWeight: FontWeight.w700, fontSize: 10)),
                                        Text(t.tamed, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.xl)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.realWorld, style: AppTextStyles.caption.copyWith(color: AppColors.monsterHakim, fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 12)),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(content.duniaNyata, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.6)),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(color: AppColors.monsterHakim.withValues(alpha: 0.08), border: Border.all(color: AppColors.monsterHakim.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(AppRadius.xl)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.whatItSays, style: AppTextStyles.caption.copyWith(color: AppColors.monsterHakim, fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 11)),
                                        const SizedBox(height: 7),
                                        Text('"${content.apaKatanya}"', style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.55, color: AppColors.teksUtama, fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(color: AppColors.sekunder.withValues(alpha: 0.08), border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(AppRadius.xl)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.theFact, style: AppTextStyles.caption.copyWith(color: AppColors.sekunder, fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 11)),
                                        const SizedBox(height: 7),
                                        Text(content.faktanya, style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.55)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.xl)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.antidotes, style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 12)),
                                  const SizedBox(height: AppSpacing.sm),
                                  for (final teknik in content.techniques)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(color: AppColors.monsterHakim.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
                                            alignment: Alignment.center,
                                            child: Icon(teknik.icon, size: 18, color: AppColors.monsterHakim),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(child: Text(teknik.label, style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.45))),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: AppColors.monsterHakim.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(AppRadius.pill)),
                                            child: Text('${teknik.multiplier}×', style: AppTextStyles.caption.copyWith(color: AppColors.monsterHakim, fontWeight: FontWeight.w800, fontSize: 11)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Divider(color: AppColors.garis, height: 20),
                                  Row(
                                    children: [
                                      const Icon(Icons.bolt, size: 14, color: AppColors.monsterHakim),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(child: Text(t.antidoteNote, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.xl)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.minionsHeading, style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 12)),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      for (final id in _minionIds)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 34,
                                              height: 36,
                                              child: Opacity(
                                                opacity: (scope.monsterProgress.progressOf(id)?.state == MonsterState.tamed) ? 1 : 0.55,
                                                child: RiungMonster(
                                                  monsterId: id,
                                                  state: (scope.monsterProgress.progressOf(id)?.state == MonsterState.tamed)
                                                      ? MonsterVisualState.jinak
                                                      : MonsterVisualState.liar,
                                                  size: 34,
                                                  applyBossScale: false,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(context.s.common.monsterName(id), style: AppTextStyles.caption.copyWith(fontSize: 8)),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    t.minionsNote,
                                    style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: snapshot.data == null
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => MinigameIntroScreen(
                                              saboteur: snapshot.data!.firstWhere((s) => s.id == 'hakim'),
                                            ),
                                          ),
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.monsterHakim,
                                  foregroundColor: AppColors.teksUtama,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                                ),
                                icon: const Icon(Icons.bolt, size: 17),
                                label: Text(t.attack, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 15)),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: OutlinedButton(
                                // Sama dengan tombol "Latihan CBT" di detail monster
                                // lain: Si Hakim punya level Better Me sendiri (Level 1).
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => LevelIntroScreen(level: betterMeLevels.first)),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.garis, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                                ),
                                child: Text(t.cbtPractice, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
