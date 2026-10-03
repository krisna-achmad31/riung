import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/services.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';

enum _Plan { tahunan, bulanan }

/// Penawaran Premium di akhir onboarding — tersambung ke Play Billing
/// sungguhan sejak M6 (lewat [BillingService] yang sama dipakai
/// `PaywallPremiumScreen` di Toko). "Lanjut versi gratis" & tombol X
/// selalu setara mudahnya dengan CTA beli (CLAUDE.md aturan #4: tidak ada
/// dark pattern). Implement persis `design/Onboarding.dc.html` § Paywall
/// onboarding.
class PaywallStep extends StatefulWidget {
  const PaywallStep({super.key, required this.controller, required this.onSelesai});

  final OnboardingController controller;
  final VoidCallback onSelesai;

  @override
  State<PaywallStep> createState() => _PaywallStepState();
}

class _PaywallStepState extends State<PaywallStep> {
  _Plan _plan = _Plan.tahunan;
  bool _processing = false;
  Map<String, ProductDetails> _products = {};
  StreamSubscription<BillingUpdate>? _sub;

  @override
  void initState() {
    super.initState();
    final scope = AppScope.of(context);
    scope.analytics.paywallView(source: 'onboarding');
    final billing = scope.billing;
    _sub = billing.updates.listen(_onUpdate);
    billing.queryProducts().then((res) {
      if (!mounted) return;
      setState(() => _products = {for (final p in res.productDetails) p.id: p});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onUpdate(BillingUpdate update) async {
    if (update.productId != PremiumSku.monthly.productId && update.productId != PremiumSku.yearly.productId) return;
    if (!mounted) return;
    if (update.status == BillingStatus.pending) {
      setState(() => _processing = true);
      return;
    }
    setState(() => _processing = false);
    if (update.status != BillingStatus.success) {
      if (update.status == BillingStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.toko.billingError(update.errorKind, update.detail))),
        );
      }
      return;
    }
    await AppScope.of(context).auth.refreshProfile();
    if (!mounted) return;
    widget.onSelesai();
  }

  Future<void> _mulaiTrial() async {
    final sku = _plan == _Plan.tahunan ? PremiumSku.yearly : PremiumSku.monthly;
    final product = _products[sku.productId];
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.toko.planUnavailable)),
      );
      return;
    }
    // Poin 2 — di titik ini user onboarding lazimnya masih anonim (belum
    // sampai layar Daftar), jadi sheet ini KEMUNGKINAN BESAR sering
    // trigger di sini — itu disengaja. Pilih "Nanti saja" cuma
    // membatalkan pembelian, alur onboarding tetap lanjut seperti biasa
    // (tombol "Lanjut versi gratis" tidak tersentuh oleh early return ini).
    if (!await ensureAccountForPurchase(context)) return;
    if (!mounted) return;
    setState(() => _processing = true);
    await AppScope.of(context).billing.buyPremium(product);
  }

  Future<void> _pulihkanPembelian() async {
    setState(() => _processing = true);
    await AppScope.of(context).billing.restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    final rc = AppScope.of(context).remoteConfig;
    final t = context.s.toko;
    final rupiah = NumberFormat.decimalPattern('id_ID');
    final yearlyProduct = _products[PremiumSku.yearly.productId];
    final monthlyProduct = _products[PremiumSku.monthly.productId];
    final perBulanTahunan = (rc.premiumHargaTahunanIdr / 12).round();
    final nama = widget.controller.nama.trim();

    return RiungGlowBackground(
      glowColor: AppColors.aksenHangat,
      alignment: const Alignment(0, -1),
      opacity: 0.16,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: IconButton(
                  onPressed: _processing ? null : widget.onSelesai,
                  icon: const Icon(Icons.close, color: AppColors.teksRedup),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.aksenHangat.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium, size: 16, color: AppColors.aksenHangat),
                          const SizedBox(width: 6),
                          Text(
                            t.premiumPill,
                            style: AppTextStyles.caption.copyWith(color: AppColors.aksenHangat, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      t.onboardingTitle(nama),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display.copyWith(fontSize: 25, height: 1.28),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.onboardingSub(rc.premiumTrialHari),
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Column(
                      children: [
                        for (final benefit in t.onboardingBenefits)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                const Icon(Icons.check, size: 18, color: AppColors.sukses),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: Text(benefit, style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 14))),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PlanCard(
                      selected: _plan == _Plan.tahunan,
                      badge: t.saveYearly,
                      title: t.planYearly,
                      subtitle: yearlyProduct != null
                          ? t.yearlyPrice(yearlyProduct.price)
                          : t.onboardingYearlyFallback(rupiah.format(rc.premiumHargaTahunanIdr), rupiah.format(perBulanTahunan)),
                      trailing: t.trialTrailing(rc.premiumTrialHari),
                      onTap: () => setState(() => _plan = _Plan.tahunan),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PlanCard(
                      selected: _plan == _Plan.bulanan,
                      title: t.monthlySimple,
                      subtitle: monthlyProduct != null
                          ? t.monthlyPrice(monthlyProduct.price)
                          : t.onboardingMonthlyFallback(rupiah.format(rc.premiumHargaBulananIdr)),
                      onTap: () => setState(() => _plan = _Plan.bulanan),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, AppSpacing.lg),
              child: Column(
                children: [
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processing ? null : _mulaiTrial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.aksenHangat,
                        foregroundColor: AppColors.latar,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      ),
                      child: Text(
                        _processing ? t.processing : t.startTrial(rc.premiumTrialHari),
                        style: AppTextStyles.buttonLabel,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _processing ? null : widget.onSelesai,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Text(t.continueFree, style: AppTextStyles.caption),
                        ),
                      ),
                      Text(' · ', style: AppTextStyles.caption),
                      GestureDetector(
                        onTap: _processing ? null : _pulihkanPembelian,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Text(t.restore, style: AppTextStyles.caption),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.trailing,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: selected ? AppColors.aksenHangat.withValues(alpha: 0.07) : null,
              border: Border.all(color: selected ? AppColors.aksenHangat : AppColors.garis, width: selected ? 2 : 1.5),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? AppColors.aksenHangat : AppColors.teksRedup, width: 2),
                  ),
                  child: selected
                      ? Container(width: 11, height: 11, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.aksenHangat))
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 15)),
                      Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(trailing!, style: AppTextStyles.caption.copyWith(color: AppColors.aksenHangat, fontWeight: FontWeight.w700, fontSize: 11)),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              left: AppSpacing.lg,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(color: AppColors.aksenHangat, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(
                  badge!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.latar, fontWeight: FontWeight.w800, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
