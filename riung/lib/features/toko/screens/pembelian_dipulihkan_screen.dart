import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Langganan Premium ditemukan lagi lewat "Pulihkan pembelian". Implement
/// persis `design/Toko.dc.html` § "Pembelian dipulihkan".
class PembelianDipulihkanScreen extends StatelessWidget {
  const PembelianDipulihkanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).auth.profile;
    final t = context.s.toko;
    final planLabel = profile?.premiumPlan == 'premium_monthly' ? t.planMonthly : t.planYearly;
    final renewsAt = profile?.premiumRenewsAt;
    final tanggal = renewsAt == null ? '' : DateFormat('d MMM yyyy', context.s.dateLocale).format(renewsAt);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const RiungSparkleHero(child: RiungIcon3D(RiungIcon.premium, size: 160)),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.welcomeBack, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppGlass.card(radius: 24, color: AppColors.permukaan),
                      child: Row(
                        children: [
                          const RiungIcon3D(RiungIcon.premium, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.s.profil.planTitle(planLabel), style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                                const SizedBox(height: 2),
                                Text(
                                  tanggal.isEmpty ? t.premiumActive : t.premiumActiveUntil(tanggal),
                                  style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primer),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              RiungButton(label: t.backToHome, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
            ],
          ),
        ),
      ),
    );
  }
}
