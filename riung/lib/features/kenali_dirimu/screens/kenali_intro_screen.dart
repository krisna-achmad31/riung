import 'package:flutter/material.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/kenali_test.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/kenali_note_card.dart';
import 'kenali_quiz_screen.dart';

/// Intro satu tes/kuis (frame `Glass — Kenali Dirimu · Intro Kuis`):
/// judul, chip soal/menit/privat, wujud monster yang mungkin (Kuis Besar),
/// tip menjawab, sumber teori, lalu "Mulai kuis".
class KenaliIntroScreen extends StatelessWidget {
  const KenaliIntroScreen({super.key, required this.entry, required this.test});

  final KenaliEntry entry;
  final KenaliTest test;

  void _mulai(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => KenaliQuizScreen(entry: entry, test: test)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final n = test.questions.length;
    final health = entry.section == KenaliSection.kesehatan;
    final monster = entry.monsterId;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              const RiungGlassHeader(title: ''),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                  children: [
                    if (entry.wakesMonster) ...[
                      Center(child: RiungMonster(monsterId: monster!, state: MonsterVisualState.liar, size: 150, applyBossScale: false)),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(t.introKicker(entry.section).toUpperCase(), style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.aksenHangatGelap)),
                    const SizedBox(height: 4),
                    Text(t.entryTitle(entry.id), style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.2)),
                    const SizedBox(height: 8),
                    Text(t.entryBlurb(entry.id, test.description), style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(icon: Icons.help_outline_rounded, label: t.chipQuestions(n)),
                        _MetaChip(icon: Icons.schedule_rounded, label: t.chipMinutes(KenaliDirimuConfig.menitUntuk(n))),
                        _MetaChip(icon: Icons.lock_outline_rounded, label: t.chipPrivate),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (entry.wakesMonster && monster != 'bara') ...[
                      _WujudList(entry: entry, test: test),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (entry.wakesMonster)
                      KenaliNoteCard(
                        icon: Icons.auto_awesome_rounded,
                        color: AppColors.sekunderLembut.withValues(alpha: 0.7),
                        text: monster == 'bara' ? t.introBaraNote : t.introWakeNote(s.common.monsterName(monster!)),
                      )
                    else if (health)
                      KenaliNoteCard(text: t.introHealthNote)
                    else if (monster != null)
                      KenaliNoteCard(icon: Icons.link_rounded, text: t.introLinkedNote(s.common.monsterName(monster)))
                    else if (entry.badge)
                      KenaliNoteCard(icon: Icons.workspace_premium_outlined, text: t.introBadgeNote),
                    const SizedBox(height: AppSpacing.md),
                    RiungOwlTip(message: t.introTip),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      health ? t.healthSourceLine(test.theoryReference) : t.sourceLine(test.theoryReference),
                      style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, color: AppColors.teksRedup),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: RiungButton(label: t.startButton(entry.section), onPressed: () => _mulai(context))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: AppGlass.pill(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.teksSekunder),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: AppColors.teksUtama)),
        ],
      ),
    );
  }
}

/// "WUJUD SI NANTI YANG MUNGKIN" — satu baris per trait (tanpa trait sehat).
class _WujudList extends StatelessWidget {
  const _WujudList({required this.entry, required this.test});

  final KenaliEntry entry;
  final KenaliTest test;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final monster = entry.monsterId!;
    final traits = (entry.wujudOrder.isNotEmpty ? entry.wujudOrder : test.traits).where((tr) => !entry.healthyTraits.contains(tr)).toList();
    return RiungGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.wujudHeading(s.common.monsterName(monster)), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup)),
          const SizedBox(height: 10),
          for (final trait in traits)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: AppColors.monsterColors[monster] ?? AppColors.aksenHangat, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.wujudName(monster, trait), style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                        Text(t.wujudLine(monster, trait), style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.teksSekunder)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
