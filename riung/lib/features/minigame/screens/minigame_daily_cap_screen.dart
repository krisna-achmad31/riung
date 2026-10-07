import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Tiket/serangan harian habis. Bukan layar di `design/Monster.dc.html`
/// (yang cuma menyebut batasnya lewat teks kecil di layar Intro), tapi
/// diperlukan supaya "Mulai serangan" tanpa tiket punya tujuan yang jelas
/// alih-alih diam saja.
class MinigameDailyCapScreen extends StatelessWidget {
  const MinigameDailyCapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.s.minigame;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: RiungGlassIconButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).maybePop()),
              ),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  children: [
                    Center(
                      child: SizedBox(
                        width: 240,
                        height: 200,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 20,
                              top: 0,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                              ),
                            ),
                            const Positioned(left: 39, top: 40, child: RiungIcon3D(RiungIcon.tiket, size: 139)),
                            const Positioned(left: 170, top: 30, child: Icon(Icons.bedtime_outlined, size: 36, color: AppColors.sekunder)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.capTitle, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.capBody(EconomyTiket.maxFightPerHari), textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.lg),
                    RiungGlassCard(
                      radius: 26,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.capHowTo, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksUtama)),
                          const SizedBox(height: 10),
                          _Baris(icon: RiungIcon.checkin, text: t.capWayCheckin),
                          _Baris(icon: RiungIcon.meditasi, text: t.capWayMeditation),
                          _Baris(icon: RiungIcon.jurnal, text: t.capWayJournal),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RiungButton(label: t.capBack, variant: RiungButtonVariant.secondary, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({required this.icon, required this.text});

  final RiungIcon icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          RiungIcon3D(icon, size: 36),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.teksUtama))),
        ],
      ),
    );
  }
}
