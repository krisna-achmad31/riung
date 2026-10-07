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
    return RiungGlassCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: isAnnual
          ? ListenableBuilder(
              listenable: wallet,
              builder: (context, _) {
                final claimable = wallet.premiumDailyClaimable;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Atas(title: t.dailyCoinsTitle, body: t.dailyCoinsBody(EconomyPremium.koinHarianTahunan)),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 10),
                    Text(t.dailyCoinsNote, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
                  ],
                );
              },
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Atas(title: t.switchYearlyTitle, body: t.switchYearlyBody(EconomyPremium.bulanDibayarPerTahun, EconomyPremium.koinHarianTahunan)),
                const SizedBox(height: 10),
                RiungButton(
                  label: t.switchYearly,
                  variant: RiungButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPremiumScreen())),
                ),
              ],
            ),
    );
  }
}

/// Baris atas (frame `Atas`): koin 3D + judul + isi.
class _Atas extends StatelessWidget {
  const _Atas({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const RiungIcon3D(RiungIcon.koin, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
              const SizedBox(height: 2),
              Text(body, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.35, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
            ],
          ),
        ),
      ],
    );
  }
}
