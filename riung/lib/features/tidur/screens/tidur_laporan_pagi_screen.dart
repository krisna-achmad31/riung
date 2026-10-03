import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'tidur_pengingat_screen.dart';

/// Laporan tidur pagi — belum ada pelacakan durasi tidur otomatis (tidak
/// ada sensor, sesuai CLAUDE.md "semua catatan berasal dari yang kamu isi
/// sendiri"), jadi selalu menampilkan state pertama kali persis
/// `design/Tidur.dc.html` § Pertama kali — belum ada data.
class TidurLaporanPagiScreen extends StatelessWidget {
  const TidurLaporanPagiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder)),
                  Text(context.s.tidur.reportTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Opacity(
                      opacity: 0.85,
                      child: SizedBox(
                        width: 116,
                        height: 122,
                        child: RiungMonster(monsterId: 'meronta', state: MonsterVisualState.jinak, size: 116),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(context.s.tidur.reportEmptyTitle, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 19)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.s.tidur.reportEmptyBody,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.6),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RiungButton(label: context.s.tidur.tryTonightStory, onPressed: () => Navigator.of(context).maybePop()),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TidurPengingatScreen())),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.garis, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                        icon: const Icon(Icons.notifications_outlined, size: 15, color: AppColors.teksSekunder),
                        label: Text(context.s.tidur.setReminder, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      context.s.tidur.noSensorNote,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
