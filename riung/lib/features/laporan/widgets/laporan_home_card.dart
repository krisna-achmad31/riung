import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../logic/report_config.dart';
import '../screens/laporan_screen.dart';

/// Kartu Beranda menuju laporan refleksi mingguan. Teks pendukungnya
/// menyesuaikan: sudah cukup hari check-in atau belum.
class LaporanHomeCard extends StatelessWidget {
  const LaporanHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.s.laporan;
    final ready = AppScope.of(context).streak.current >= ReportConfig.minActiveDays;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LaporanScreen())),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.primer.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.insights_rounded, size: 22, color: AppColors.primer),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.homeTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                  const SizedBox(height: 2),
                  Text(ready ? t.homeSubReady : t.homeSubEmpty, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.primer),
          ],
        ),
      ),
    );
  }
}
