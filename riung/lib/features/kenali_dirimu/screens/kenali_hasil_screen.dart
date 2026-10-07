import 'package:flutter/material.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/kenali_result.dart';
import '../../../core/models/kenali_test.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../monster/logic/habit_monsters.dart';
import '../../monster/screens/habit_stage_map_screen.dart';
import '../../monster/screens/hakim_detail_screen.dart';
import '../../monster/screens/saboteur_detail_screen.dart';
import '../logic/kenali_progress.dart';
import '../logic/kenali_scoring.dart';
import '../widgets/kenali_note_card.dart';
import 'kenali_intro_screen.dart';

/// Hasil Kuis Besar & tes Diri & Relasi (frame `Glass — Kenali Dirimu ·
/// Hasil Kuis`): wujud/kategori, rincian alasan (tes trait), kartu monster
/// yang terbangun / tertaut / lencana, tip, dan disclaimer.
class KenaliHasilScreen extends StatelessWidget {
  const KenaliHasilScreen({super.key, required this.entry, required this.test, required this.result});

  final KenaliEntry entry;
  final KenaliTest test;
  final KenaliResult result;

  KenaliOutcome? get _outcome => KenaliScoring.outcomeOf(test, result);

  void _ulangi(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => KenaliIntroScreen(entry: entry, test: test)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final outcome = _outcome;
    final monster = KenaliProgress.monsterOf(entry, result);
    final trait = result.dominantTrait;
    final awake = entry.wakesMonster && monster != null;
    final title = outcome?.title ?? result.category;
    final alias = entry.wakesMonster && trait != null && monster != null ? t.wujudName(monster, trait) : outcome?.alias;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(
                title: t.resultHeading,
                trailing: RiungGlassIconButton(icon: Icons.refresh_rounded, onTap: () => _ulangi(context)),
              ),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                  children: [
                    Text(t.entryTitle(entry.id).toUpperCase(), style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.aksenHangatGelap)),
                    const SizedBox(height: 4),
                    Text(title, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.2)),
                    if (alias != null && alias.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(alias, style: AppTextStyles.title.copyWith(fontSize: 17, color: AppColors.sekunder)),
                    ],
                    if (result.score != null && result.maxScore != null) ...[
                      const SizedBox(height: 6),
                      Text(t.scoreLine(result.score!, result.maxScore!), style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksSekunder)),
                    ],
                    if (outcome != null) ...[
                      const SizedBox(height: 8),
                      Text(outcome.description, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
                    ],
                    if (result.traitPercents.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _TraitBreakdown(entry: entry, test: test, result: result),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (entry.wakesMonster)
                      _AwakeCard(monsterId: entry.monsterId!, awake: awake)
                    else if (monster != null)
                      _LinkedCard(monsterId: monster)
                    else if (entry.badge)
                      _BadgeCard(category: title),
                    if (trait != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      RiungOwlTip(message: t.traitTip(entry.id, trait)),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(t.disclaimer, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, color: AppColors.teksRedup)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (awake)
                Row(
                  children: [
                    Expanded(child: RiungButton(label: t.save, variant: RiungButtonVariant.secondary, onPressed: () => Navigator.of(context).maybePop())),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RiungButton(
                        label: t.startTaming,
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => HabitStageMapScreen(monsterId: entry.monsterId!)),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: RiungButton(label: t.retake, variant: RiungButtonVariant.secondary, onPressed: () => _ulangi(context))),
                    const SizedBox(width: 10),
                    Expanded(child: RiungButton(label: t.done, onPressed: () => Navigator.of(context).maybePop())),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Alasan kamu menunda": bar persen per trait, trait dominan disorot.
class _TraitBreakdown extends StatelessWidget {
  const _TraitBreakdown({required this.entry, required this.test, required this.result});

  final KenaliEntry entry;
  final KenaliTest test;
  final KenaliResult result;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    final traits = test.traits;
    final perTrait = traits.isEmpty ? 0 : test.questions.where((q) => q.trait == traits.first).length;
    final sorted = [...traits]..sort((a, b) => (result.traitPercents[b] ?? 0).compareTo(result.traitPercents[a] ?? 0));
    return RiungGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.breakdownTitle(entry.id), style: AppTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          for (final trait in sorted) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    test.outcomeForTrait(trait)?.title ?? trait,
                    style: AppTextStyles.chipLabel.copyWith(
                      fontSize: 13,
                      fontWeight: trait == result.dominantTrait ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.teksUtama,
                    ),
                  ),
                ),
                Text('${result.traitPercents[trait] ?? 0}%', style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksSekunder)),
              ],
            ),
            const SizedBox(height: 6),
            RiungProgressBar(
              value: (result.traitPercents[trait] ?? 0) / 100,
              colors: trait == result.dominantTrait ? const [AppColors.emas, AppColors.aksenHangat] : const [AppColors.kabutLavender, AppColors.kabutLavender],
            ),
            const SizedBox(height: 12),
          ],
          Text(t.breakdownNote(perTrait, traits.length), style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}

/// Kartu "Si Nanti terbangun" — atau "tetap tidur" bila pola sehat.
class _AwakeCard extends StatelessWidget {
  const _AwakeCard({required this.monsterId, required this.awake});

  final String monsterId;
  final bool awake;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final name = s.common.monsterName(monsterId);
    final tint = AppColors.monsterLembut[monsterId] ?? AppColors.aksenHangatLembut;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tint, Color.lerp(tint, AppColors.aksenHangat, 0.15)!]),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
        boxShadow: AppGlass.shadow,
      ),
      child: Row(
        children: [
          Opacity(
            opacity: awake ? 1 : 0.5,
            child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.liar, size: 96, applyBossScale: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(awake ? t.awokeTitle(name) : t.stillAsleepTitle(name), style: AppTextStyles.title.copyWith(fontSize: 17)),
                const SizedBox(height: 4),
                Text(awake ? t.awokeBody(monsterId) : t.stillAsleepBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksUtama)),
                if (awake) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text(
                      t.newPractices(HabitMonsters.practicesOf(monsterId).length),
                      style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primer),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tes Diri & Relasi: tautan ke Monster Pikiran yang sudah ada.
class _LinkedCard extends StatelessWidget {
  const _LinkedCard({required this.monsterId});

  final String monsterId;

  Future<void> _lihat(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (monsterId == 'hakim') {
      await navigator.push(MaterialPageRoute(builder: (_) => const HakimDetailScreen()));
      return;
    }
    final list = await AppScope.of(context).contentRepository.getSaboteurs();
    final saboteur = list.where((x) => x.id == monsterId).firstOrNull;
    if (saboteur == null) return;
    await navigator.push(MaterialPageRoute(builder: (_) => SaboteurDetailScreen(saboteur: saboteur)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final name = s.common.monsterName(monsterId);
    return RiungGlassCard(
      radius: 28,
      padding: const EdgeInsets.all(16),
      onTap: () => _lihat(context),
      child: Row(
        children: [
          RiungMonster(monsterId: monsterId, state: MonsterVisualState.liar, size: 84, applyBossScale: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.linkedTitle(name), style: AppTextStyles.title.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(t.linkedBody(name), style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksUtama)),
                const SizedBox(height: 6),
                Text('${t.seeMonster} →', style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.primer)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tes lencana (Kecerdasan Emosi, Orang yang Menyenangkan).
class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    return KenaliNoteCard(
      icon: Icons.workspace_premium_rounded,
      color: AppColors.aksenHangatLembut.withValues(alpha: 0.7),
      text: '${t.badgeTitle(category)}\n${t.badgeBody}',
    );
  }
}
