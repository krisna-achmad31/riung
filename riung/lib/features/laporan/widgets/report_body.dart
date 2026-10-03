import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
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
        const SizedBox(height: AppSpacing.lg),
        if (report.needsSupport) ...[
          ReportNoticeCard(
            icon: Icons.favorite_rounded,
            accent: AppColors.error,
            title: t.supportTitle,
            body: t.supportBody,
            cta: t.supportCta,
            onCta: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BantuanKrisisScreen())),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (visible.isNotEmpty) ...[
          Text(t.insightsTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
          for (final insight in visible) ReportInsightTile(insight: insight),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(t.nextTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.xs),
        Text(next, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
        if (!premium) ...[
          const SizedBox(height: AppSpacing.lg),
          ReportNoticeCard(
            icon: Icons.workspace_premium,
            accent: AppColors.aksenHangat,
            title: t.lockedTitle,
            body: t.lockedBody,
            cta: t.lockedCta,
            onCta: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPremiumScreen())),
          ),
        ],
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final t = context.s.laporan;
    final weekly = report.windowDays == ReportConfig.weekDays;
    final average = report.averageMood!;
    final moodId = checkInMoods[(average.round() - 1).clamp(0, checkInMoods.length - 1)];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.activeSummary(report.activeDays, report.windowDays), style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
          const SizedBox(height: 2),
          Text(t.entriesSummary(report.checkInCount, report.journalCount), style: AppTextStyles.caption.copyWith(fontSize: 12)),
          const SizedBox(height: AppSpacing.md),
          MoodSparkline(
            days: report.days,
            labels: weekly ? [for (final d in report.days) t.weekday(d.date.weekday).substring(0, 3)] : const [],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(moodId.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${t.averageLabel}: ${context.s.checkin.moodLabel(moodId.id)}',
                  style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
