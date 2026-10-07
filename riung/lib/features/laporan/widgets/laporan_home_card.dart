import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
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
    return RiungGlassCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LaporanScreen())),
      radius: 28,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const RiungIcon3D(RiungIcon.laporan, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.homeTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 16, color: AppColors.teksUtama)),
                const SizedBox(height: 2),
                Text(ready ? t.homeSubReady : t.homeSubEmpty, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.teksSekunder)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.teksRedup),
        ],
      ),
    );
  }
}
