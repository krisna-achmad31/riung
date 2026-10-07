import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../checkin/logic/checkin_options.dart';
import '../../checkin/screens/checkin_mood_screen.dart';
import '../../profil/screens/bantuan_krisis_screen.dart';
import '../../toko/screens/paywall_premium_screen.dart';
import '../logic/report_config.dart';
import '../logic/report_models.dart';
import 'mood_sparkline.dart';
import 'report_insight_tile.dart';
import 'report_notice_card.dart';

/// Isi satu laporan (mingguan atau bulanan): ringkasan, grafik, insight,
/// langkah kecil, dan — kalau perlu — dukungan. Bagian Premium tampil
/// sebagai kunci lembut untuk non-Premium.
class ReportBody extends StatelessWidget {
  const ReportBody({super.key, required this.report, required this.premium});

  final Report report;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final t = context.s.laporan;
    if (!report.hasEnoughData) {
      return ReportNoticeCard(
        icon: Icons.spa_rounded,
        accent: AppColors.primer,
        title: t.emptyTitle,
        body: t.emptyBody(ReportConfig.minActiveDays, report.activeDays),
        cta: t.emptyCta,
        filledButton: true,
        onCta: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckInMoodScreen())),
      );
    }

    final visible = [for (final i in report.insights) if (!i.premium || premium) i];
    final trend = report.insights.where((i) => i.kind == InsightKind.moodTrend).firstOrNull;
    final gentle = report.needsSupport || (trend?.direction ?? 0) < 0;
    final next = gentle ? t.nextGentle : ((trend?.direction ?? 0) > 0 ? t.nextUp : t.nextSteady);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Summary(report: report),
        const SizedBox(height: AppSpacing.md),
        _MoodCard(report: report),
        const SizedBox(height: AppSpacing.md),
        if (report.needsSupport) ...[
          ReportNoticeCard(
            icon: Icons.favorite_rounded,
            accent: AppColors.error,
            title: t.supportTitle,
            body: t.supportBody,
            cta: t.supportCta,
            onCta: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BantuanKrisisScreen())),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (visible.isNotEmpty) ...[
          RiungGlassCard(
            radius: 26,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.insightsTitle, style: AppTextStyles.title.copyWith(fontSize: 15)),
                for (final insight in visible) ReportInsightTile(insight: insight),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: AppGlass.card(radius: 24, color: AppColors.kabutSage.withValues(alpha: 0.7)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.nextTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.primer)),
              const SizedBox(height: 6),
              Text(next, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
            ],
          ),
        ),
        if (!premium) ...[
          const SizedBox(height: AppSpacing.md),
          _PremiumLocked(
            title: t.lockedTitle,
            body: t.lockedBody,
            cta: t.lockedCta,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPremiumScreen())),
          ),
        ],
      ],
    );
  }
}

/// Kartu Premium terkunci (frame `Premium terkunci`): gradien ungu malam
/// → primer, ikon premium 3D, CTA emas lembut.
class _PremiumLocked extends StatelessWidget {
  const _PremiumLocked({required this.title, required this.body, required this.cta, required this.onTap});

  final String title;
  final String body;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.tiketAwal, AppColors.primer]),
          borderRadius: BorderRadius.circular(26),
          boxShadow: AppGlass.shadow,
        ),
        child: Row(
          children: [
            const RiungIcon3D(RiungIcon.premium, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.diAtasTinta)),
                  const SizedBox(height: 3),
                  Text(body, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4, color: AppColors.diAtasTinta.withValues(alpha: 0.8))),
                  const SizedBox(height: 6),
                  Text(cta, style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: AppColors.emas)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ringkasan kehadiran (frame `Ringkasan`): gradien biru→lavender + ikon
/// laporan 3D.
class _Summary extends StatelessWidget {
  const _Summary({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final t = context.s.laporan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.langitLembut, AppColors.sekunderLembut]),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
        boxShadow: AppGlass.shadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.activeSummary(report.activeDays, report.windowDays), style: AppTextStyles.title.copyWith(fontSize: 22, height: 1.15)),
                const SizedBox(height: 6),
                Text(t.entriesSummary(report.checkInCount, report.journalCount), style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.teksSekunder)),
              ],
            ),
          ),
          const RiungIcon3D(RiungIcon.laporan, size: 80),
        ],
      ),
    );
  }
}

/// Rata-rata suasana hati + batang per hari (frame `Rata-rata`).
class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final t = context.s.laporan;
    final weekly = report.windowDays == ReportConfig.weekDays;
    final average = report.averageMood!;
    final moodId = checkInMoods[(average.round() - 1).clamp(0, checkInMoods.length - 1)];
    return RiungGlassCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(t.averageLabel, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama))),
              Text(moodId.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(context.s.checkin.moodLabel(moodId.id), style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.primer)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MoodSparkline(
            days: report.days,
            labels: weekly ? [for (final d in report.days) t.weekday(d.date.weekday).substring(0, 3)] : const [],
          ),
        ],
      ),
    );
  }
}
