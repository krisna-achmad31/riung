import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../toko/screens/paywall_premium_screen.dart';
import '../widgets/premium_daily_coins_card.dart';

/// Status langganan Riung Premium. Implement persis
/// `design/Profil.dc.html` § "Langganan" untuk user aktif; kalau belum
/// premium, tampilkan upsell ke [PaywallPremiumScreen] (desain cuma
/// menggambarkan state "sudah aktif" — layar ini butuh cabang kedua yang
/// desainnya tidak mockup-kan).
class LanggananScreen extends StatelessWidget {
  const LanggananScreen({super.key});

  Future<void> _kelolaLangganan(String? productId) async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '${productId != null ? '?sku=$productId&package=com.riung.riung' : ''}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.profil;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
                  ),
                  Text(t.subTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: scope.auth,
                builder: (context, _) {
                  final profile = scope.auth.profile;
                  if (profile == null) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primer));
                  }
                  final status = profile.premiumStatus(DateTime.now());
                  if (status == PremiumStatus.expired) {
                    return const _Kedaluwarsa();
                  }
                  if (status == PremiumStatus.none) {
                    return _BelumPremium(onUpgrade: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PaywallPremiumScreen()),
                        ));
                  }
                  final isMonthly = profile.premiumPlan == 'premium_monthly';
                  final planLabel = isMonthly ? t.planMonthly : t.planYearly;
                  final rc = scope.remoteConfig;
                  final rupiah = NumberFormat.decimalPattern('id_ID');
                  final harga = isMonthly ? rc.premiumHargaBulananIdr : rc.premiumHargaTahunanIdr;
                  final tanggal = profile.premiumRenewsAt == null
                      ? ''
                      : DateFormat('d MMMM yyyy', context.s.dateLocale).format(profile.premiumRenewsAt!);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.aksenHangat.withValues(alpha: 0.16), AppColors.kartu.withValues(alpha: 0.9)],
                            ),
                            border: Border.all(color: AppColors.aksenHangat.withValues(alpha: 0.45), width: 1.5),
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.workspace_premium_rounded, size: 21, color: AppColors.aksenHangat),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(t.planTitle(planLabel), style: AppTextStyles.title.copyWith(fontSize: 17)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text.rich(
                                TextSpan(
                                  style: AppTextStyles.body.copyWith(fontSize: 12),
                                  children: [
                                    TextSpan(text: t.activeUntil),
                                    TextSpan(text: tanggal.isEmpty ? '-' : tanggal, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.teksUtama)),
                                    TextSpan(text: t.autoRenew),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(t.priceVia(rupiah.format(harga), isMonthly), style: AppTextStyles.body.copyWith(fontSize: 12)),
                              if (status == PremiumStatus.renewsSoon) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline, size: 14, color: AppColors.peringatan),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(t.statusRenewsSoon, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.peringatan, height: 1.45))),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PremiumDailyCoinsCard(isAnnual: profile.isAnnual),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.permukaan,
                            border: Border.all(color: AppColors.garis),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.whatYouGet, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6)),
                              const SizedBox(height: AppSpacing.sm),
                              for (final benefit in t.subBenefits)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_rounded, size: 15, color: AppColors.sukses),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(child: Text(benefit, style: AppTextStyles.body.copyWith(fontSize: 13))),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        GestureDetector(
                          onTap: () => _kelolaLangganan(profile.premiumPlan),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.permukaan,
                              border: Border.all(color: AppColors.garis),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.close_rounded, size: 18, color: AppColors.teksSekunder),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: Text(t.manageSub, style: AppTextStyles.chipLabel.copyWith(fontSize: 13))),
                                const Icon(Icons.chevron_right_rounded, size: 17, color: AppColors.teksRedup),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          t.cancelNote,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.55),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BelumPremium extends StatelessWidget {
  const _BelumPremium({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 40, color: AppColors.aksenHangat),
            const SizedBox(height: AppSpacing.md),
            Text(t.notSubscribed, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.notSubscribedBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            RiungButton(label: t.viewPremium, onPressed: onUpgrade),
          ],
        ),
      ),
    );
  }
}

/// Langganan lewat masa perpanjangan: tawarkan pulihkan pembelian (kalau
/// sudah diperpanjang di Play) atau berlangganan lagi, tanpa nada menyalahkan.
class _Kedaluwarsa extends StatefulWidget {
  const _Kedaluwarsa();

  @override
  State<_Kedaluwarsa> createState() => _KedaluwarsaState();
}

class _KedaluwarsaState extends State<_Kedaluwarsa> {
  bool _checking = false;

  Future<void> _pulihkan() async {
    final scope = AppScope.of(context);
    setState(() => _checking = true);
    await scope.billing.restorePurchases();
    // Hasilnya masuk lewat stream pembelian; beri waktu sebentar lalu muat ulang profil.
    await Future<void>.delayed(const Duration(seconds: 3));
    await scope.auth.refreshProfile();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 40, color: AppColors.teksRedup),
            const SizedBox(height: AppSpacing.md),
            Text(t.expiredTitle, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
            const SizedBox(height: AppSpacing.sm),
            Text(t.expiredBody, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13)),
            const SizedBox(height: AppSpacing.lg),
            RiungButton(
              label: _checking ? t.restoreChecking : t.restorePurchases,
              variant: RiungButtonVariant.secondary,
              onPressed: _checking ? null : _pulihkan,
            ),
            const SizedBox(height: AppSpacing.sm),
            RiungButton(
              label: t.subscribeAgain,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPremiumScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
