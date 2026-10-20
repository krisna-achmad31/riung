import 'package:flutter/material.dart';

import '../../features/toko/logic/premium_offer.dart';
import '../../features/toko/screens/paywall_premium_screen.dart';
import '../l10n/l10n.dart';
import '../services/billing_service.dart';
import '../state/state.dart';
import '../theme/theme.dart';
import 'riung_button.dart';
import 'riung_glass_icon_button.dart';
import 'riung_icon_3d.dart';
import 'riung_skeleton.dart';
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
                    const _HargaPremium(),
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

/// Harga bulanan & trial dari Play (bukan Rupiah dari config) — user di luar
/// Indonesia melihat mata uangnya sendiri; trial hanya disebut bila offer
/// trial memang tersedia untuknya.
class _HargaPremium extends StatefulWidget {
  const _HargaPremium();

  @override
  State<_HargaPremium> createState() => _HargaPremiumState();
}

class _HargaPremiumState extends State<_HargaPremium> {
  late final Future<Map<String, PremiumOffer>> _offers = PremiumOffer.load(AppScope.of(context).billing);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, PremiumOffer>>(
      future: _offers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const RiungSkeleton(width: 160, height: 14);
        final monthly = snapshot.data![PremiumSku.monthly.productId];
        return Text(
          monthly == null ? context.s.toko.priceOnPlay : context.s.common.premiumPriceLine(monthly.recurringPrice, monthly.trialDays),
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.primer, fontWeight: FontWeight.w700),
        );
      },
    );
  }
}
