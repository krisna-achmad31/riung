import 'package:flutter/material.dart';

import '../../features/toko/screens/paywall_premium_screen.dart';
import '../config/economy.dart';
import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'riung_button.dart';
import 'riung_glass_icon_button.dart';
import 'riung_icon_3d.dart';
import 'riung_sparkle_hero.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: RiungGlassIconButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).maybePop()),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const RiungSparkleHero(child: RiungIcon3D(RiungIcon.premium, size: 150)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(title, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.s.common.premiumLockedBody(freeTierNote),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      context.s.common.premiumPriceLine(EconomyPremium.hargaBulananIdr, EconomyPremium.trialHari),
                      style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.primer, fontWeight: FontWeight.w700),
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
              const SizedBox(height: 10),
              RiungButton(label: context.s.common.skipForNow, variant: RiungButtonVariant.secondary, onPressed: () => Navigator.of(context).maybePop()),
            ],
          ),
        ),
      ),
    );
  }
}
