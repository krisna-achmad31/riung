import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/services.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/premium_offer.dart';
import '../logic/restore_feedback.dart';
import '../widgets/ketentuan_sheet.dart';
import 'pembelian_dipulihkan_screen.dart';

enum _Plan { tahunan, bulanan }

/// Paywall Riung Premium dari Toko/Profil — beda dari `PaywallStep`
/// onboarding (yang masih UI saja): CTA di sini memicu pembelian Play
/// Billing sungguhan lewat [BillingService]. Implement persis
/// `design/Toko.dc.html` § "Paywall Riung Premium" & frame
/// `Glass — Toko · Paywall Premium` di `design/riung.pen`.
class PaywallPremiumScreen extends StatefulWidget {
  const PaywallPremiumScreen({super.key});

  @override
  State<PaywallPremiumScreen> createState() => _PaywallPremiumScreenState();
}

class _PaywallPremiumScreenState extends State<PaywallPremiumScreen> {
  _Plan _plan = _Plan.tahunan;
  bool _processing = false;
  bool _restoring = false;

  /// Pembayaran tertunda (VA/minimarket): layar tetap bisa ditutup.
  bool _pending = false;

  /// null = masih memuat dari Play; plan yang tidak ada = Play gagal.
  Map<String, PremiumOffer>? _offers;
  StreamSubscription<BillingUpdate>? _sub;

  @override
  void initState() {
    super.initState();
    final scope = AppScope.of(context);
    scope.analytics.paywallView(source: 'toko');
    _sub = scope.billing.updates.listen(_onUpdate);
    _loadOffers();
  }

  void _loadOffers() {
    if (_offers != null) setState(() => _offers = null);
    AppScope.of(context).billing.queryProducts().then((res) {
      if (!mounted) return;
      setState(() => _offers = PremiumOffer.fromProducts(res.productDetails));
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
      setState(() {
        _processing = false;
        _pending = true;
      });
      return;
    }
    setState(() {
      _processing = false;
      if (update.status == BillingStatus.success) _pending = false;
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
    final offer = _offers?[sku.productId];
    if (offer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.toko.planUnavailable)),
      );
      return;
    }
    if (!await ensureAccountForPurchase(context)) return;
    if (!mounted) return;
    setState(() => _processing = true);
    try {
      await AppScope.of(context).billing.buyPremium(offer.purchase);
    } catch (_) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.toko.billingError(BillingErrorKind.purchaseFailed, null))),
      );
    }
  }

  Future<void> _pulihkanPembelian() async {
    setState(() {
      _restoring = true;
      _processing = true;
    });
    final outcome = await AppScope.of(context).billing.restorePurchases();
    if (!mounted) return;
    // _onUpdate sudah menangani hasil Premium (pindah layar / pesan error).
    final handled = !_restoring;
    setState(() {
      _restoring = false;
      _processing = false;
    });
    if (!handled) showRestoreOutcome(context, outcome);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.toko;
    final offers = _offers;
    final sku = _plan == _Plan.tahunan ? PremiumSku.yearly : PremiumSku.monthly;
    final pricesFailed = offers != null && PremiumSku.values.any((p) => offers[p.productId] == null);
    String? priceLine(PremiumSku plan, String Function(String) format) {
      if (offers == null) return null; // skeleton
      final offer = offers[plan.productId];
      return offer == null ? t.priceOnPlay : format(offer.recurringPrice);
    }

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
                  padding: const EdgeInsets.only(top: AppSpacing.konten, bottom: AppSpacing.konten),
                  children: [
                    const _PaywallHero(),
                    const SizedBox(height: AppSpacing.konten),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.sekunderLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(t.premiumTitle, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sekunderTerang)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.konten),
                    Text(t.premiumSub, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
                    const SizedBox(height: AppSpacing.konten),
                    for (final (i, benefit) in t.premiumBenefits.indexed)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.check_rounded, size: 16, color: AppColors.primer)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(benefit, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksUtama))),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.konten),
                    RiungRadioOption(
                      selected: _plan == _Plan.tahunan,
                      title: t.planYearly,
                      badge: t.saveYearly,
                      badgeColor: AppColors.primerLembut,
                      badgeTextColor: AppColors.primer,
                      subtitle: priceLine(PremiumSku.yearly, t.yearlyWithPrice),
                      onTap: () => setState(() => _plan = _Plan.tahunan),
                    ),
                    const SizedBox(height: AppSpacing.konten),
                    RiungRadioOption(
                      selected: _plan == _Plan.bulanan,
                      title: t.planMonthly,
                      subtitle: priceLine(PremiumSku.monthly, t.monthlyWithPrice),
                      onTap: () => setState(() => _plan = _Plan.bulanan),
                    ),
                    if (pricesFailed) RiungRetryLink(onTap: _loadOffers),
                    const SizedBox(height: AppSpacing.konten),
                    Text(
                      t.annualPerk(EconomyPremium.koinHarianTahunan),
                      style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.35, fontWeight: FontWeight.w600, color: AppColors.primer),
                    ),
                  ],
                ),
              ),
              if (_pending) ...[
                Text(t.pendingPayment, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600, color: AppColors.primer)),
                const SizedBox(height: AppSpacing.sm),
              ],
              ListenableBuilder(
                listenable: scope.auth,
                builder: (context, _) {
                  final profile = scope.auth.profile;
                  if (profile != null && profile.premiumNow && profile.premiumPlan == sku.productId) {
                    return RiungButton(label: t.activePlan, onPressed: null);
                  }
                  final trialDays = offers?[sku.productId]?.trialDays;
                  return RiungButton(
                    label: _processing ? t.processing : trialDays != null ? t.tryFree(trialDays) : t.subscribeNow,
                    onPressed: _processing || offers == null ? null : _mulaiTrial,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.konten),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.xs,
                children: [
                  GestureDetector(
                    onTap: _processing ? null : _pulihkanPembelian,
                    behavior: HitTestBehavior.opaque,
                    child: Text(t.restore, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksSekunder)),
                  ),
                  GestureDetector(
                    onTap: () => showKetentuanSheet(context, trialDays: offers?[sku.productId]?.trialDays),
                    behavior: HitTestBehavior.opaque,
                    child: Text(t.terms, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksSekunder)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.konten),
              Text(t.premiumNote, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
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
