import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Ajakan opsional menghubungkan data tidur jam tangan (Health Connect).
/// Sesudah terhubung, berubah jadi baris ringkas dengan tombol putus.
class SleepConnectCard extends StatelessWidget {
  const SleepConnectCard({super.key, required this.connected, required this.busy, required this.noData, required this.onConnect, required this.onDisconnect});

  final bool connected;
  final bool busy;

  /// Terhubung, tetapi belum ada malam tidur yang terbaca.
  final bool noData;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final t = context.s.laporan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: connected
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.watch_rounded, size: 18, color: AppColors.sukses),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(t.sleepConnected, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksUtama))),
                    TextButton(onPressed: busy ? null : onDisconnect, child: Text(t.sleepDisconnect, style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: AppColors.teksRedup))),
                  ],
                ),
                if (noData) Text(t.sleepNoData, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.5)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.watch_rounded, size: 18, color: AppColors.primer),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(t.sleepConnectTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama))),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(t.sleepConnectBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5)),
                const SizedBox(height: AppSpacing.md),
                RiungButton(label: t.sleepConnectCta, variant: RiungButtonVariant.secondary, onPressed: busy ? null : onConnect),
              ],
            ),
    );
  }
}
