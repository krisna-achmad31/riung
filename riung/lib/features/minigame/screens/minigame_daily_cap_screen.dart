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
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close, color: AppColors.teksRedup)),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: AppColors.sekunder.withValues(alpha: 0.12),
                        border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.confirmation_number_outlined, size: 32, color: AppColors.sekunder),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.capTitle, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 21)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.capBody(EconomyTiket.maxFightPerHari),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.capHowTo, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 13)),
                          const SizedBox(height: AppSpacing.sm),
                          _Baris(t.capWayCheckin),
                          _Baris(t.capWayMeditation),
                          _Baris(t.capWayJournal),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              RiungButton(label: t.capBack, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 15, color: AppColors.sekunder),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppTextStyles.caption.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
