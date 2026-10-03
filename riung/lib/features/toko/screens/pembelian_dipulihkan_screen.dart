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
    final tanggal = renewsAt == null ? '' : DateFormat('d MMMM yyyy', context.s.dateLocale).format(renewsAt);

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: AppColors.aksenHangat,
        alignment: const Alignment(0, -0.6),
        opacity: 0.16,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.aksenHangat.withValues(alpha: 0.14),
                          border: Border.all(color: AppColors.aksenHangat, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.workspace_premium, size: 36, color: AppColors.aksenHangat),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(t.welcomeBack, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 23)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.restoredBody(planLabel),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.permukaan,
                          border: Border.all(color: AppColors.garis),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.s.profil.planTitle(planLabel), style: AppTextStyles.caption),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              tanggal.isEmpty ? t.premiumActive : t.premiumActiveUntil(tanggal),
                              style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
                child: RiungButton(
                  label: t.backToHome,
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
