import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/sleep_catalog.dart';

/// Cerita tidur selesai / timer habis — audio & wakelock sudah berhenti,
/// layar ini menutup sesi dengan tenang sebelum kembali.
class TidurSelesaiScreen extends StatelessWidget {
  const TidurSelesaiScreen({super.key, required this.story});

  final SleepStory story;

  @override
  Widget build(BuildContext context) {
    final t = context.s.tidur;
    return Scaffold(
      body: RiungGlassBackdrop(
        night: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [AppNight.cahayaBulan, AppNight.cahayaBulan.withValues(alpha: 0)]),
                            ),
                          ),
                          const RiungIcon3D(RiungIcon.tidur, size: 170),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(t.doneTitle, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 28, color: AppNight.teks)),
                      const SizedBox(height: AppSpacing.md),
                      Text(t.doneBody, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppNight.teksSekunder)),
                    ],
                  ),
                ),
                RiungButton(
                  label: context.s.common.selesai,
                  variant: RiungButtonVariant.night,
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
