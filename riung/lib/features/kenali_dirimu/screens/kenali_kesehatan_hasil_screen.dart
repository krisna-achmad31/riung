import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/kenali_result.dart';
import '../../../core/models/kenali_test.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../profil/screens/bantuan_krisis_screen.dart';
import '../logic/kenali_feature_route.dart';
import '../logic/kenali_navigator.dart';
import '../logic/kenali_scoring.dart';
import '../widgets/kenali_note_card.dart';
import 'kenali_intro_screen.dart';

/// Hasil tes kesehatan mental (frame `Glass — Kenali Dirimu · Hasil Tes
/// Kesehatan`). TIDAK ada monster, koin, atau peringkat — hanya gambaran
/// skor, langkah kecil, kapan ke profesional, dan akses krisis.
class KenaliKesehatanHasilScreen extends StatelessWidget {
  const KenaliKesehatanHasilScreen({super.key, required this.entry, required this.test, required this.result});

  final KenaliEntry entry;
  final KenaliTest test;
  final KenaliResult result;

  void _bantuan(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BantuanKrisisScreen()));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final outcome = KenaliScoring.outcomeOf(test, result);
    final score = result.score ?? 0;
    final max = result.maxScore ?? score;
    final retakeDate = result.completedAt.add(const Duration(days: KenaliDirimuConfig.ulangiKesehatanHari));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(title: t.testHeader(t.entryTitle(entry.id))),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                  children: [
                    Text(
                      t.resultDateKicker(DateFormat('d MMMM', s.dateLocale).format(result.completedAt)),
                      style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(kenaliResultTitle(test, result), style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2))),
                        const SizedBox(width: 12),
                        _ScorePill(score: score),
                      ],
                    ),
                    if (outcome != null) ...[
                      const SizedBox(height: 8),
                      Text(outcome.description, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _BandBar(test: test, score: score, current: outcome),
                    const SizedBox(height: 8),
                    Text(t.healthScoreLine(entry.id, score, max), style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.lg),
                    _StepsCard(testId: entry.id),
                    const SizedBox(height: AppSpacing.md),
                    _ProfessionalCard(testId: entry.id, onHelp: () => _bantuan(context)),
                    const SizedBox(height: AppSpacing.md),
                    _CrisisCard(onTap: () => _bantuan(context)),
                    const SizedBox(height: AppSpacing.md),
                    KenaliNoteCard(text: t.healthPrivacy),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.healthSourceLine(test.theoryReference), style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, color: AppColors.teksRedup)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: RiungButton(
                      label: t.retakeOn(DateFormat('d MMM', s.dateLocale).format(retakeDate)),
                      variant: RiungButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => KenaliIntroScreen(entry: entry, test: test))),
                    ),
                  ),
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

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.sekunderLembut, border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth)),
      alignment: Alignment.center,
      child: Text('$score', style: AppTextStyles.display.copyWith(fontSize: 22, color: AppColors.sekunder)),
    );
  }
}

/// Pita rentang hasil (Normal → Berat) dengan penanda posisi skor.
class _BandBar extends StatelessWidget {
  const _BandBar({required this.test, required this.score, required this.current});

  final KenaliTest test;
  final int score;
  final KenaliOutcome? current;

  @override
  Widget build(BuildContext context) {
    final bands = test.outcomes.where((o) => o.minScore != null && o.maxScore != null).toList();
    if (bands.isEmpty) return const SizedBox.shrink();
    final lo = bands.first.minScore!;
    final hi = bands.last.maxScore!;
    final span = (hi - lo).clamp(1, 1 << 30);
    const colors = [AppColors.primerLembut, AppColors.kabutLavender, AppColors.aksenHangatLembut, AppColors.aksenHangat];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final x = ((score - lo) / span).clamp(0.0, 1.0) * c.maxWidth;
            return SizedBox(
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 7,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: [
                          for (var i = 0; i < bands.length; i++)
                            Expanded(
                              flex: (bands[i].maxScore! - bands[i].minScore! + 1).clamp(1, 1 << 20),
                              child: Container(height: 8, color: colors[(i * (colors.length - 1) / (bands.length - 1).clamp(1, 99)).round()]),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (x - 11).clamp(0.0, c.maxWidth - 22),
                    top: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.permukaanPadat, border: Border.all(color: AppColors.sekunder, width: 3)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final b in bands)
              Expanded(
                flex: (b.maxScore! - b.minScore! + 1).clamp(1, 1 << 20),
                child: Text(
                  kenaliCategoryTitle(b.category),
                  maxLines: 2,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9,
                    height: 1.3,
                    fontWeight: identical(b, current) ? FontWeight.w800 : FontWeight.w500,
                    color: identical(b, current) ? AppColors.teksUtama : AppColors.teksRedup,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// "Langkah kecil yang bisa membantu" — tiga pintasan ke fitur app.
class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.testId});

  final String testId;

  static RiungIcon _icon(KenaliStep step) => switch (step) {
        KenaliStep.napas || KenaliStep.meditasi => RiungIcon.meditasi,
        KenaliStep.cekPikiran || KenaliStep.jurnalRasa => RiungIcon.jurnal,
        KenaliStep.checkin => RiungIcon.checkin,
        KenaliStep.tidurTenang => RiungIcon.tidur,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    return RiungGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.stepsTitle, style: AppTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          for (final step in KenaliDirimuConfig.stepsFor(testId))
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => openKenaliFeature(context, KenaliDirimuConfig.featureForStep(step)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    RiungIcon3D(_icon(step), size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.stepTitle(step), style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                          Text(t.stepSub(step), style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.teksRedup),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({required this.testId, required this.onHelp});

  final String testId;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    return RiungGlassCard(
      radius: 24,
      color: AppColors.sekunderLembut.withValues(alpha: 0.7),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.proTitle, style: AppTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: 6),
          Text(t.proBody(testId), style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onHelp,
            child: Text('${t.proCta} →', style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.sekunder)),
          ),
        ],
      ),
    );
  }
}

/// "Butuh bantuan sekarang" — layar krisis selalu bisa diakses.
class _CrisisCard extends StatelessWidget {
  const _CrisisCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    return RiungGlassCard(
      radius: 24,
      color: AppColors.aksenHangatLembut.withValues(alpha: 0.8),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          const RiungIcon3D(RiungIcon.bantuan, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.crisisTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                Text(t.crisisSub, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.teksRedup),
        ],
      ),
    );
  }
}
