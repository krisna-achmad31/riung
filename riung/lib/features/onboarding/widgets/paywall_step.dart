import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/services.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../toko/logic/premium_offer.dart';
import '../../toko/logic/restore_feedback.dart';
import '../logic/onboarding_controller.dart';

enum _Plan { tahunan, bulanan }

/// Penawaran Premium di akhir onboarding — tersambung ke Play Billing
/// sungguhan sejak M6 (lewat [BillingService] yang sama dipakai
/// `PaywallPremiumScreen` di Toko). "Lanjut versi gratis" & tombol X
/// selalu setara mudahnya dengan CTA beli (CLAUDE.md aturan #4: tidak ada
/// dark pattern). Implement persis `design/Onboarding.dc.html` § Paywall
/// onboarding & frame `Glass — Toko · Paywall onboarding` di
/// `design/riung.pen`.
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
  bool _restoring = false;

  /// Pembayaran tertunda (VA/minimarket) — "Lanjut versi gratis" tetap aktif.
  bool _pending = false;

  /// null = masih memuat dari Play; plan yang tidak ada = Play gagal.
  Map<String, PremiumOffer>? _offers;
  StreamSubscription<BillingUpdate>? _sub;

  @override
  void initState() {
    super.initState();
    final scope = AppScope.of(context);
    scope.analytics.paywallView(source: 'onboarding');
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
      _restoring = false;
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
    final offer = _offers?[sku.productId];
    if (offer == null) {
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
      _processing = true;
      _restoring = true;
    });
    final outcome = await AppScope.of(context).billing.restorePurchases();
    if (!mounted) return;
    // Error per pembelian sudah ditampilkan _onUpdate; Premium yang pulih
    // juga menutup langkah ini lewat _onUpdate.
    final handled = !_restoring;
    setState(() {
      _processing = false;
      _restoring = false;
    });
    if (!handled) showRestoreOutcome(context, outcome);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.toko;
    final offers = _offers;
    final sku = _plan == _Plan.tahunan ? PremiumSku.yearly : PremiumSku.monthly;
    final selectedTrial = offers?[sku.productId]?.trialDays;
    final yearlyTrial = offers?[PremiumSku.yearly.productId]?.trialDays;
    final pricesFailed = offers != null && PremiumSku.values.any((p) => offers[p.productId] == null);
    String? priceLine(PremiumSku plan, String Function(String) format) {
      if (offers == null) return null; // skeleton
      final offer = offers[plan.productId];
      return offer == null ? t.priceOnPlay : format(offer.recurringPrice);
    }

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
                padding: const EdgeInsets.only(top: AppSpacing.konten - 4, bottom: AppSpacing.konten),
                children: [
                  const _PaywallHero(),
                  const SizedBox(height: AppSpacing.konten),
                  Text(t.onboardingTitle(nama), style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.15)),
                  const SizedBox(height: AppSpacing.konten),
                  Text(selectedTrial != null ? t.onboardingSub(selectedTrial) : t.onboardingSubNoTrial, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  const SizedBox(height: AppSpacing.konten),
                  RiungRadioOption(
                    selected: _plan == _Plan.tahunan,
                    title: t.planYearly,
                    subtitle: priceLine(PremiumSku.yearly, t.yearlyPrice),
                    trailing: yearlyTrial == null
                        ? null
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.primerLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                            child: Text(t.trialTrailing(yearlyTrial), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primer)),
                          ),
                    onTap: () => setState(() => _plan = _Plan.tahunan),
                  ),
                  const SizedBox(height: AppSpacing.konten),
                  RiungRadioOption(
                    selected: _plan == _Plan.bulanan,
                    title: t.monthlySimple,
                    subtitle: priceLine(PremiumSku.monthly, t.monthlyPrice),
                    onTap: () => setState(() => _plan = _Plan.bulanan),
                  ),
                  if (pricesFailed) RiungRetryLink(onTap: _loadOffers),
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
                return RiungButton(
                  label: _processing ? t.processing : selectedTrial != null ? t.startTrial(selectedTrial) : t.subscribeNow,
                  onPressed: _processing || offers == null ? null : _mulaiTrial,
                );
              },
            ),
            const SizedBox(height: AppSpacing.konten),
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
          const Positioned(left: 56, top: 60, child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 80, applyBossScale: false)),
          const Positioned(right: 20, top: 62, child: RiungMonster(monsterId: 'cermin', state: MonsterVisualState.jinak, size: 80, applyBossScale: false)),
          const Positioned(right: 0, top: 124, child: RiungMonster(monsterId: 'mengelak', state: MonsterVisualState.jinak, size: 74, applyBossScale: false)),
          const Positioned(top: 30, child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 170, applyBossScale: false)),
        ],
      ),
    );
  }
}
