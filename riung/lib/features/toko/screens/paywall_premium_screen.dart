import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/services.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/ketentuan_sheet.dart';
import 'pembelian_dipulihkan_screen.dart';

enum _Plan { tahunan, bulanan }

/// Paywall Riung Premium dari Toko/Profil — beda dari `PaywallStep`
/// onboarding (yang masih UI saja): CTA di sini memicu pembelian Play
/// Billing sungguhan lewat [BillingService]. Implement persis
/// `design/Toko.dc.html` § "Paywall Riung Premium".
class PaywallPremiumScreen extends StatefulWidget {
  const PaywallPremiumScreen({super.key});

  @override
  State<PaywallPremiumScreen> createState() => _PaywallPremiumScreenState();
}

class _PaywallPremiumScreenState extends State<PaywallPremiumScreen> {
  _Plan _plan = _Plan.tahunan;
  bool _processing = false;
  bool _restoring = false;
  Map<String, ProductDetails> _products = {};
  StreamSubscription<BillingUpdate>? _sub;

  @override
  void initState() {
    super.initState();
    final scope = AppScope.of(context);
    scope.analytics.paywallView(source: 'toko');
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
    setState(() {
      _processing = false;
    });
    if (update.status != BillingStatus.success) {
      if (update.status == BillingStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.toko.billingError(update.errorKind, update.detail))),
        );
      }
      _restoring = false;
      return;
    }
    final wasRestoring = _restoring;
    _restoring = false;
    await AppScope.of(context).auth.refreshProfile();
    if (!mounted) return;
    if (wasRestoring) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PembelianDipulihkanScreen()));
    } else {
      Navigator.of(context).maybePop();
    }
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
    if (!await ensureAccountForPurchase(context)) return;
    if (!mounted) return;
    setState(() => _processing = true);
    await AppScope.of(context).billing.buyPremium(product);
  }

  Future<void> _pulihkanPembelian() async {
    setState(() {
      _restoring = true;
      _processing = true;
    });
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

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: AppColors.aksenHangat,
        alignment: const Alignment(0, -1),
        opacity: 0.1,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _processing ? null : () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: AppColors.teksRedup),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          SizedBox(width: 52, height: 55, child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 52, applyBossScale: false)),
                          SizedBox(width: 76, height: 80, child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 76, applyBossScale: false)),
                          SizedBox(width: 52, height: 55, child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 52, applyBossScale: false)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium, size: 20, color: AppColors.aksenHangat),
                          const SizedBox(width: AppSpacing.sm),
                          Text(t.premiumTitle, style: AppTextStyles.title.copyWith(fontSize: 22)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.premiumSub,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.permukaan,
                          border: Border.all(color: AppColors.garis),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Column(
                          children: [
                            for (final benefit in t.premiumBenefits)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check, size: 15, color: AppColors.sukses),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(child: Text(benefit, style: AppTextStyles.body.copyWith(fontSize: 13))),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PlanRow(
                        selected: _plan == _Plan.tahunan,
                        badge: t.saveYearly,
                        title: t.planYearly,
                        subtitle: yearlyProduct != null
                            ? t.yearlyWithPrice(yearlyProduct.price)
                            : t.yearlyFallback(rupiah.format(rc.premiumHargaTahunanIdr), rupiah.format(perBulanTahunan)),
                        onTap: () => setState(() => _plan = _Plan.tahunan),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PlanRow(
                        selected: _plan == _Plan.bulanan,
                        title: t.planMonthly,
                        subtitle: monthlyProduct != null
                            ? t.monthlyWithPrice(monthlyProduct.price)
                            : t.monthlyFallback(rupiah.format(rc.premiumHargaBulananIdr)),
                        onTap: () => setState(() => _plan = _Plan.bulanan),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.annualPerk(EconomyPremium.koinHarianTahunan),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.aksenHangat, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        t.premiumNote(rc.premiumTrialHari),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
                child: Column(
                  children: [
                    RiungButton(
                      label: _processing ? t.processing : t.tryFree(rc.premiumTrialHari),
                      onPressed: _processing ? null : _mulaiTrial,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _processing ? null : _pulihkanPembelian,
                          child: Text(t.restore, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        // Dulu teks biasa (tidak bisa diketuk) — sekarang membuka
                        // lembar ketentuan langganan.
                        GestureDetector(
                          onTap: () => showKetentuanSheet(context),
                          behavior: HitTestBehavior.opaque,
                          child: Text(t.terms, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.selected, required this.title, required this.subtitle, required this.onTap, this.badge});

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: selected ? AppColors.aksenHangat.withValues(alpha: 0.1) : AppColors.permukaan,
              border: Border.all(color: selected ? AppColors.aksenHangat : AppColors.garis, width: selected ? 1.5 : 1),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? AppColors.aksenHangat : AppColors.garis, width: selected ? 5 : 1.5),
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -9,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.aksenHangat, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(badge!, style: AppTextStyles.caption.copyWith(color: AppColors.latar, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
        ],
      ),
    );
  }
}
