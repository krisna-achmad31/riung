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
    final t = context.s.tidur;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
          children: [
            RiungGlassHeader(title: t.reportTitle),
            const SizedBox(height: AppSpacing.lg),
            RiungGlassCard(
              radius: 32,
              color: AppColors.permukaan,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                      ),
                      const RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 150, cosmetics: ['bantal_mini']),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(t.reportEmptyTitle, textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 20)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(t.reportEmptyBody, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
                  const SizedBox(height: AppSpacing.lg),
                  RiungButton(label: t.tryTonightStory, onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 10),
                  RiungButton(
                    label: t.setReminder,
                    variant: RiungButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TidurPengingatScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.kartu, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.teksSekunder),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.noSensorNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.teksSekunder))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
