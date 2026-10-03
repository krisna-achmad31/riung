import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../toko/screens/paywall_premium_screen.dart';

/// Panel koin harian di layar Langganan. Pelanggan tahunan: tombol ambil
/// [EconomyPremium.koinHarianTahunan] koin (sekali per hari, hari terlewat
/// tidak menumpuk). Pelanggan bulanan: ajakan lembut ke paket tahunan
/// ("bayar 10 bulan untuk 12") tanpa tekanan.
class PremiumDailyCoinsCard extends StatelessWidget {
  const PremiumDailyCoinsCard({super.key, required this.isAnnual});

  final bool isAnnual;

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    final wallet = AppScope.of(context).wallet;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: isAnnual ? AppColors.aksenHangat.withValues(alpha: 0.5) : AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: isAnnual
          ? ListenableBuilder(
              listenable: wallet,
              builder: (context, _) {
                final claimable = wallet.premiumDailyClaimable;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, size: 18, color: AppColors.aksenHangat),
                        const SizedBox(width: AppSpacing.sm),
                        Text(t.dailyCoinsTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(t.dailyCoinsBody(EconomyPremium.koinHarianTahunan), style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5)),
                    const SizedBox(height: AppSpacing.md),
                    RiungButton(
                      label: claimable ? t.claimDaily(EconomyPremium.koinHarianTahunan) : t.claimedToday,
                      onPressed: claimable
                          ? () async {
                              final ok = await wallet.claimPremiumDaily();
                              if (ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.claimedSnack(EconomyPremium.koinHarianTahunan))));
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(t.dailyCoinsNote, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                  ],
                );
              },
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.switchYearlyTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  t.switchYearlyBody(EconomyPremium.bulanDibayarPerTahun, EconomyPremium.koinHarianTahunan),
                  style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPremiumScreen())),
                  child: Text(t.switchYearly, style: AppTextStyles.chipLabel.copyWith(color: AppColors.primer, fontSize: 13)),
                ),
              ],
            ),
    );
  }
}
