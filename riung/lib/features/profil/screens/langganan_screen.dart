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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.subTitle),
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
                      return _BelumPremium(onUpgrade: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPremiumScreen())));
                    }
                    final isMonthly = profile.premiumPlan == 'premium_monthly';
                    final planLabel = isMonthly ? t.planMonthly : t.planYearly;
                    final rc = scope.remoteConfig;
                    final rupiah = NumberFormat.decimalPattern('id_ID');
                    final harga = isMonthly ? rc.premiumHargaBulananIdr : rc.premiumHargaTahunanIdr;
                    final tanggal = profile.premiumRenewsAt == null ? '-' : DateFormat('d MMM yyyy', context.s.dateLocale).format(profile.premiumRenewsAt!);

                    return RiungBleedListView(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
                      children: [
                        _PaketAktifCard(
                          title: t.planTitle(planLabel),
                          sub: '${t.activeUntil}$tanggal${t.autoRenew}',
                          price: t.priceVia(rupiah.format(harga), isMonthly),
                          warning: status == PremiumStatus.renewsSoon ? t.statusRenewsSoon : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PremiumDailyCoinsCard(isAnnual: profile.isAnnual),
                        const SizedBox(height: AppSpacing.md),
                        RiungGlassCard(
                          radius: 26,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.whatYouGet, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5, color: AppColors.sekunder)),
                              for (final benefit in t.subBenefits)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.check_rounded, size: 16, color: AppColors.primer)),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(benefit, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksUtama))),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        RiungButton(label: t.manageSub, variant: RiungButtonVariant.secondary, onPressed: () => _kelolaLangganan(profile.premiumPlan)),
                        const SizedBox(height: 6),
                        Text(t.cancelNote, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, color: AppColors.teksSekunder)),
                        const SizedBox(height: AppSpacing.md),
                        const Center(child: _PulihkanLink()),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu paket aktif (frame `Paket aktif`): gradien ungu malam → primer.
class _PaketAktifCard extends StatelessWidget {
  const _PaketAktifCard({required this.title, required this.sub, required this.price, this.warning});

  final String title;
  final String sub;
  final String price;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.tiketAwal, AppColors.primer]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppGlass.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const RiungIcon3D(RiungIcon.premium, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.title.copyWith(fontSize: 17, color: AppColors.diAtasTinta)),
                    const SizedBox(height: 2),
                    Text(sub, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.3, fontWeight: FontWeight.w500, color: AppColors.diAtasTinta.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(price, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emasLembut)),
          if (warning != null) ...[
            const SizedBox(height: 8),
            Text(warning!, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4, color: AppColors.emasMuda)),
          ],
        ],
      ),
    );
  }
}

/// Tautan "Pulihkan pembelian" di bawah layar langganan aktif.
class _PulihkanLink extends StatefulWidget {
  const _PulihkanLink();

  @override
  State<_PulihkanLink> createState() => _PulihkanLinkState();
}

class _PulihkanLinkState extends State<_PulihkanLink> {
  bool _checking = false;

  Future<void> _pulihkan() async {
    final scope = AppScope.of(context);
    setState(() => _checking = true);
    await scope.billing.restorePurchases();
    await Future<void>.delayed(const Duration(seconds: 3));
    await scope.auth.refreshProfile();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    return GestureDetector(
      onTap: _checking ? null : _pulihkan,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(_checking ? t.restoreChecking : t.restorePurchases, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.primer)),
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
            const RiungIcon3D(RiungIcon.premium, size: 96),
            const SizedBox(height: AppSpacing.md),
            Text(t.notSubscribed, textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 20)),
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
            const RiungIcon3D(RiungIcon.premium, size: 96),
            const SizedBox(height: AppSpacing.md),
            Text(t.expiredTitle, textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 20)),
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
