import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../logic/report_config.dart';
import '../logic/report_models.dart';

/// Satu kalimat insight dengan ikon kecil. Teks disusun dari string per
/// bahasa (tidak ada kalimat di mesin).
class ReportInsightTile extends StatelessWidget {
  const ReportInsightTile({super.key, required this.insight});

  final ReportInsight insight;

  @override
  Widget build(BuildContext context) {
    final t = context.s.laporan;
    final s = context.s;
    final (IconData icon, Color color, String text) = switch (insight.kind) {
      InsightKind.moodTrend => switch (insight.direction) {
          1 => (Icons.trending_up_rounded, AppColors.sukses, t.trendUp),
          -1 => (Icons.trending_down_rounded, AppColors.aksenHangat, t.trendDown),
          _ => (Icons.trending_flat_rounded, AppColors.primer, t.trendSteady),
        },
      InsightKind.bestDay => (Icons.wb_sunny_rounded, AppColors.peringatan, t.bestDay(t.weekday(insight.weekday!))),
      InsightKind.hardDay => (Icons.cloud_rounded, AppColors.monsterKabut, t.hardDay(t.weekday(insight.weekday!))),
      InsightKind.topFactor => (Icons.label_rounded, AppColors.sekunder, t.topFactor(s.checkin.factorLabel(insight.id!), insight.count)),
      InsightKind.topMonster => (Icons.edit_note_rounded, AppColors.monsterCermin, t.topMonster(s.common.monsterName(insight.id!), insight.count)),
      InsightKind.sleepAverage => (Icons.bedtime_rounded, AppColors.primer, t.sleepAverage(t.duration(insight.count))),
      InsightKind.sleepMood => (Icons.link_rounded, AppColors.sukses, t.sleepMood(ReportConfig.restedSleepMinutes ~/ 60, ReportConfig.shortSleepMinutes ~/ 60)),
      InsightKind.factorMood => insight.direction < 0
          ? (Icons.link_rounded, AppColors.aksenHangat, t.factorLower(s.checkin.factorLabel(insight.id!)))
          : (Icons.link_rounded, AppColors.sukses, t.factorHigher(s.checkin.factorLabel(insight.id!))),
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }
}
