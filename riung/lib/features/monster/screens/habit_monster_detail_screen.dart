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
import '../../minigame/screens/minigame_intro_screen.dart';
import '../../toko/logic/monster_loadout.dart';
import '../../toko/screens/lemari_screen.dart';
import '../logic/habit_monsters.dart';
import '../widgets/monster_info_card.dart';
import '../widgets/monster_state_toggle.dart';
import 'habit_stage_map_screen.dart';

/// Detail Monster Kebiasaan (frame `Glass — Monster · Si … · Detail`):
/// hero + toggle Liar/Jinak, "Bangun dari" kuis + wujudnya, apa katanya,
/// faktanya, penangkal. Monster yang masih tidur hanya bisa dibangunkan
/// lewat kuisnya — tidak pernah lewat toko.
class HabitMonsterDetailScreen extends StatefulWidget {
  const HabitMonsterDetailScreen({super.key, required this.monsterId});

  final String monsterId;

  @override
  State<HabitMonsterDetailScreen> createState() => _HabitMonsterDetailScreenState();
}

class _HabitMonsterDetailScreenState extends State<HabitMonsterDetailScreen> {
  /// Pratinjau wujud di hero (toggle Liar/Jinak) — null = ikuti progres.
  MonsterVisualState? _preview;

  String get id => widget.monsterId;

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final m = s.monster;
    final scope = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            scope.monsterProgress,
            scope.wallet,
            scope.prefs.monsterCosmeticsRevision,
            KenaliResultRepository.instance.revision,
          ]),
          builder: (context, _) {
            final progress = scope.monsterProgress.progressOf(id) ?? MonsterProgress.initial(id);
            final isTamed = progress.state == MonsterState.tamed;
            final awake = KenaliProgress.isAwake(id);
            final shown = _preview ?? (isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar);
            final worn = shown == MonsterVisualState.jinak ? MonsterLoadout(scope.prefs).idsOf(id, scope.wallet.ownedCosmetics) : const <String>[];
            final entry = KenaliDirimuConfig.quizForMonster(id);
            final wujud = [for (final trait in entry?.wujudOrder ?? const <String>[]) t.wujudName(id, trait)];

            return Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
              child: Column(
                children: [
                  RiungGlassHeader(
                    title: '',
                    trailing: isTamed ? RiungGlassIconButton(icon: Icons.checkroom_rounded, onTap: () => _push(LemariScreen(monsterId: id))) : null,
                  ),
                  Expanded(
                    child: RiungBleedListView(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                      children: [
                        _HabitHero(
                          monsterId: id,
                          shown: shown,
                          cosmetics: worn,
                          progress: progress,
                          awake: awake,
                          onPreview: (v) => setState(() => _preview = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        MonsterInfoCard(eyebrow: m.realWorld, child: _Body(t.habitRealWorld(id))),
                        const SizedBox(height: AppSpacing.md),
                        MonsterInfoCard(
                          eyebrow: t.wokeFromEyebrow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.quizName(id), style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                              const SizedBox(height: 4),
                              _Body(t.habitWujudList(id, wujud)),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        MonsterInfoCard(
                          eyebrow: m.whatItSays,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [for (final quote in t.habitQuotes(id)) _QuoteRow(quote)],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        MonsterInfoCard(eyebrow: m.theFact, eyebrowColor: AppColors.sekunder, color: AppColors.sekunderLembut.withValues(alpha: 0.7), child: _Body(t.habitFact(id))),
                        const SizedBox(height: AppSpacing.md),
                        MonsterInfoCard(
                          eyebrow: m.antidotes,
                          eyebrowColor: AppColors.primer,
                          color: AppColors.kabutSage.withValues(alpha: 0.7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Body(t.habitTechnique(id)),
                              const SizedBox(height: 8),
                              Text(m.antidoteNote, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primer)),
                            ],
                          ),
                        ),
                        if (!awake) ...[
                          const SizedBox(height: AppSpacing.md),
                          RiungOwlTip(message: t.asleepDetailBody),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (awake)
                    Row(
                      children: [
                        Expanded(child: RiungButton(label: t.stageMapButton, variant: RiungButtonVariant.secondary, onPressed: () => _push(HabitStageMapScreen(monsterId: id)))),
                        const SizedBox(width: 10),
                        Expanded(child: RiungButton(label: m.attack, onPressed: () => _push(MinigameIntroScreen(saboteur: HabitMonsters.saboteurFor(id, s))))),
                      ],
                    )
                  else if (entry != null)
                    SizedBox(width: double.infinity, child: RiungButton(label: t.takeQuiz, onPressed: () => KenaliNavigator.openById(context, entry.id))),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Panggung hero: monster 3D (liar/jinak, kosmetik bila jinak), toggle,
/// nama, pil kebiasaan, progres jinak — atau "Tertidur" bila belum bangun.
class _HabitHero extends StatelessWidget {
  const _HabitHero({
    required this.monsterId,
    required this.shown,
    required this.cosmetics,
    required this.progress,
    required this.awake,
    required this.onPreview,
  });

  final String monsterId;
  final MonsterVisualState shown;
  final List<String> cosmetics;
  final MonsterProgress progress;
  final bool awake;
  final ValueChanged<MonsterVisualState> onPreview;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final m = s.monster;
    final isTamed = progress.state == MonsterState.tamed;
    final tint = AppColors.monsterLembut[monsterId] ?? AppColors.aksenHangatLembut;

    return Container(
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
                Container(
                  width: 180,
                  height: 190,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                ),
                Opacity(
                  opacity: awake ? 1 : 0.55,
                  child: RiungMonster(monsterId: monsterId, state: shown, size: 180, applyBossScale: false, cosmetics: cosmetics),
                ),
                Positioned(
                  left: 0,
                  top: 12,
                  child: MonsterStateToggle(value: shown, wildLabel: m.wild, tamedLabel: m.tamed, onChanged: onPreview),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(s.common.monsterName(monsterId), style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(s.kenali.habitPill(monsterId), style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.aksenHangatGelap)),
          ),
          const SizedBox(height: 12),
          if (awake) ...[
            RiungProgressBar(value: progress.progress / 100, height: 8),
            const SizedBox(height: 8),
            Text(isTamed ? m.tamedBadge : m.progressToTamed(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
          ] else
            Text(s.kenali.asleep, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksRedup)),
        ],
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow(this.quote);

  final String quote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.aksenHangat, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: _Body(quote)),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksUtama));
}
