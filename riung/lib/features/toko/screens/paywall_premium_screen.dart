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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: RiungGlassIconButton(icon: Icons.close_rounded, onTap: () { if (!_processing) Navigator.of(context).maybePop(); }),
              ),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                  children: [
                    const _PaywallHero(),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.sekunderLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(t.premiumTitle, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sekunder)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.premiumSub, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.25)),
                    const SizedBox(height: AppSpacing.md),
                    for (final benefit in t.premiumBenefits)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.check_rounded, size: 16, color: AppColors.primer)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(benefit, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksUtama))),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    RiungRadioOption(
                      selected: _plan == _Plan.tahunan,
                      title: t.planYearly,
                      badge: t.saveYearly,
                      badgeColor: AppColors.primerLembut,
                      badgeTextColor: AppColors.primer,
                      subtitle: yearlyProduct != null
                          ? t.yearlyWithPrice(yearlyProduct.price)
                          : t.yearlyFallback(rupiah.format(rc.premiumHargaTahunanIdr), rupiah.format(perBulanTahunan)),
                      onTap: () => setState(() => _plan = _Plan.tahunan),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    RiungRadioOption(
                      selected: _plan == _Plan.bulanan,
                      title: t.planMonthly,
                      subtitle: monthlyProduct != null ? t.monthlyWithPrice(monthlyProduct.price) : t.monthlyFallback(rupiah.format(rc.premiumHargaBulananIdr)),
                      onTap: () => setState(() => _plan = _Plan.bulanan),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      t.annualPerk(EconomyPremium.koinHarianTahunan),
                      style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.35, fontWeight: FontWeight.w600, color: AppColors.primer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RiungButton(
                label: _processing ? t.processing : t.tryFree(rc.premiumTrialHari),
                onPressed: _processing ? null : _mulaiTrial,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _processing ? null : _pulihkanPembelian,
                    behavior: HitTestBehavior.opaque,
                    child: Text(t.restore, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksSekunder)),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  GestureDetector(
                    onTap: () => showKetentuanSheet(context),
                    behavior: HitTestBehavior.opaque,
                    child: Text(t.terms, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksSekunder)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(t.premiumNote(rc.premiumTrialHari), textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero paywall (frame `Hero`): permata premium 3D diapit dua monster jinak.
class _PaywallHero extends StatelessWidget {
  const _PaywallHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 230,
            height: 210,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
          ),
          const Positioned(top: 10, child: RiungIcon3D(RiungIcon.premium, size: 120)),
          const Positioned(left: 20, top: 90, child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 100, applyBossScale: false)),
          const Positioned(right: 10, top: 84, child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 110, applyBossScale: false)),
        ],
      ),
    );
  }
}
