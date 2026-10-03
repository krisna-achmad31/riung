import 'package:flutter/material.dart';

import '../../features/toko/screens/paywall_premium_screen.dart';
import '../config/economy.dart';
import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'riung_button.dart';

/// Konten premium terkunci — upsell ringan, dipakai lintas fitur (Meditasi,
/// Tidur, dsb). Bukan dark pattern (CLAUDE.md aturan #4): tidak ada
/// tekanan, "Lewati dulu" setara bobotnya dengan CTA beli.
class PremiumLockedScreen extends StatelessWidget {
  const PremiumLockedScreen({super.key, required this.title, required this.freeTierNote});

  final String title;
  final String freeTierNote;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: AppColors.teksRedup),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: AppColors.aksenHangat.withValues(alpha: 0.12),
                        border: Border.all(color: AppColors.aksenHangat.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.workspace_premium, size: 32, color: AppColors.aksenHangat),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(title, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 21)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.s.common.premiumLockedBody(freeTierNote),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      context.s.common.premiumPriceLine(EconomyPremium.hargaBulananIdr, EconomyPremium.trialHari),
                      style: AppTextStyles.caption.copyWith(color: AppColors.aksenHangat, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              RiungButton(
                label: context.s.common.seePremium,
                // Dulu cuma menutup layar ini; sekarang benar-benar membuka
                // paywall (menggantikan layar terkunci, jadi "kembali" dari
                // paywall langsung ke layar asal).
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const PaywallPremiumScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(context.s.common.skipForNow, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
