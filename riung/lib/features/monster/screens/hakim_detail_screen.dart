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
      body: SafeArea(
        child: FutureBuilder<List<Saboteur>>(
          future: scope.contentRepository.getSaboteurs(),
          builder: (context, snapshot) {
            return ListenableBuilder(
              listenable: scope.monsterProgress,
              builder: (context, _) {
                final progress = scope.monsterProgress.progressOf('hakim') ?? MonsterProgress.initial('hakim');
                final isTamed = progress.state == MonsterState.tamed;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
                  child: Column(
                    children: [
                      const RiungGlassHeader(title: ''),
                      Expanded(
                        child: RiungBleedListView(
                          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.sekunderLembut, AppColors.kabutLavender]),
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                                boxShadow: AppGlass.shadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 230,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 220,
                                          height: 220,
                                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                                        ),
                                        RiungMonster(monsterId: 'hakim', state: isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar, size: 224, applyBossScale: false),
                                        Positioned(
                                          left: 0,
                                          top: 16,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(color: AppColors.sekunder, borderRadius: BorderRadius.circular(AppRadius.pill)),
                                            child: Text(t.bossPercent(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.diAtasTinta)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(context.s.common.monsterName('hakim'), style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                                  const SizedBox(height: 8),
                                  Text(t.hakimIntro, style: AppTextStyles.caption.copyWith(fontSize: 13, height: 1.45, color: AppColors.teksSekunder)),
                                  const SizedBox(height: 10),
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(4)),
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      heightFactor: 1,
                                      widthFactor: (progress.progress / 100).clamp(0.0, 1.0),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.kabutLavender, AppColors.sekunder]), borderRadius: BorderRadius.circular(4)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(t.progressToTamed(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(t.minionsHeading, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup)),
                            const SizedBox(height: AppSpacing.md),
                            RiungGlassCard(
                              radius: 26,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      for (final id in _minionIds) _MinionThumb(id: id, tamed: scope.monsterProgress.progressOf(id)?.state == MonsterState.tamed),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(t.minionsNote, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, color: AppColors.teksSekunder)),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _HakimInfo(eyebrow: t.realWorld, text: content.duniaNyata),
                            const SizedBox(height: AppSpacing.md),
                            _HakimInfo(eyebrow: t.whatItSays, text: '"${content.apaKatanya}"'),
                            const SizedBox(height: AppSpacing.md),
                            _HakimInfo(eyebrow: t.theFact, text: content.faktanya, eyebrowColor: AppColors.sekunder, color: AppColors.sekunderLembut.withValues(alpha: 0.7)),
                            const SizedBox(height: AppSpacing.md),
                            RiungGlassCard(
                              radius: 24,
                              color: AppColors.kabutSage.withValues(alpha: 0.7),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.antidotes, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.primer)),
                                  const SizedBox(height: 8),
                                  for (final teknik in content.techniques)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(11)),
                                            child: Icon(teknik.icon, size: 17, color: AppColors.primer),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(teknik.label, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksUtama))),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                                            child: Text('${teknik.multiplier}×', style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primer)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Text(t.antidoteNote, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primer)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: RiungButton(
                              label: t.cbtPractice,
                              variant: RiungButtonVariant.secondary,
                              // Si Hakim punya level Better Me sendiri (Level 1).
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LevelIntroScreen(level: betterMeLevels.first))),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RiungButton(
                              label: t.attack,
                              onPressed: snapshot.data == null
                                  ? null
                                  : () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => MinigameIntroScreen(saboteur: snapshot.data!.firstWhere((s) => s.id == 'hakim'))),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Thumbnail anak buah 46dp (frame `Anak buah`): jinak = sage bertepi primer.
class _MinionThumb extends StatelessWidget {
  const _MinionThumb({required this.id, required this.tamed});

  final String id;
  final bool tamed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: tamed ? AppColors.primerLembut : AppColors.permukaan,
            shape: BoxShape.circle,
            border: Border.all(color: tamed ? AppColors.primer : AppColors.garis, width: 1.5),
          ),
          alignment: Alignment.center,
          child: RiungMonster(monsterId: id, state: tamed ? MonsterVisualState.jinak : MonsterVisualState.liar, size: 42, applyBossScale: false),
        ),
        const SizedBox(height: 4),
        Text(
          context.s.common.monsterName(id).replaceFirst('Si ', ''),
          style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w600, color: tamed ? AppColors.primer : AppColors.teksSekunder),
        ),
      ],
    );
  }
}

class _HakimInfo extends StatelessWidget {
  const _HakimInfo({required this.eyebrow, required this.text, this.eyebrowColor = AppColors.teksRedup, this.color = AppColors.kartu});

  final String eyebrow;
  final String text;
  final Color eyebrowColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      radius: 24,
      color: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: eyebrowColor)),
          const SizedBox(height: 8),
          Text(text, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
        ],
      ),
    );
  }
}
