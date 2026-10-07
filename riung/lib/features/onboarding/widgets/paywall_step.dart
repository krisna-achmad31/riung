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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, AppSpacing.sm, 20, AppSpacing.md),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _processing ? null : widget.onSelesai,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(t.continueFree, style: AppTextStyles.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teksSekunder)),
                ),
              ),
            ),
            Expanded(
              child: RiungBleedListView(
                padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
                children: [
                  const _PaywallHero(),
                  const SizedBox(height: AppSpacing.md),
                  Text(t.onboardingTitle(nama), style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                  const SizedBox(height: AppSpacing.md),
                  Text(t.onboardingSub(rc.premiumTrialHari), style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  const SizedBox(height: AppSpacing.md),
                  RiungRadioOption(
                    selected: _plan == _Plan.tahunan,
                    title: t.planYearly,
                    subtitle: yearlyProduct != null
                        ? t.yearlyPrice(yearlyProduct.price)
                        : t.onboardingYearlyFallback(rupiah.format(rc.premiumHargaTahunanIdr), rupiah.format(perBulanTahunan)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primerLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(t.trialTrailing(rc.premiumTrialHari), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primer)),
                    ),
                    onTap: () => setState(() => _plan = _Plan.tahunan),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RiungRadioOption(
                    selected: _plan == _Plan.bulanan,
                    title: t.monthlySimple,
                    subtitle: monthlyProduct != null ? t.monthlyPrice(monthlyProduct.price) : t.onboardingMonthlyFallback(rupiah.format(rc.premiumHargaBulananIdr)),
                    onTap: () => setState(() => _plan = _Plan.bulanan),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            RiungButton(label: _processing ? t.processing : t.startTrial(rc.premiumTrialHari), onPressed: _processing ? null : _mulaiTrial),
            const SizedBox(height: AppSpacing.md),
            Text(t.termsPlay, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
            GestureDetector(
              onTap: _processing ? null : _pulihkanPembelian,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(t.restore, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksSekunder)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero paywall onboarding (frame `Hero`): Si Hakim besar diapit empat
/// anak buahnya.
class _PaywallHero extends StatelessWidget {
  const _PaywallHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 230,
            height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
          ),
          const Positioned(left: 0, top: 120, child: RiungMonster(monsterId: 'meronta', state: MonsterVisualState.jinak, size: 74, applyBossScale: false)),
          const Positioned(left: 50, top: 60, child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 80, applyBossScale: false)),
          const Positioned(right: 30, top: 62, child: RiungMonster(monsterId: 'cermin', state: MonsterVisualState.jinak, size: 80, applyBossScale: false)),
          const Positioned(right: 0, top: 124, child: RiungMonster(monsterId: 'mengelak', state: MonsterVisualState.jinak, size: 74, applyBossScale: false)),
          const Positioned(top: 30, child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 170, applyBossScale: false)),
        ],
      ),
    );
  }
}
