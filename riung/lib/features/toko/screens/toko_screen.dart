import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/services.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../appbeku/widgets/appbeku_toko_section.dart';
import '../logic/billing_sku_mapping.dart';
import '../logic/toko_data.dart';
import '../widgets/konfirmasi_pembelian_sheet.dart';
import '../widgets/kosmetik_preview_sheet.dart';
import 'beli_sesi_fokus_screen.dart';
import 'koin_kurang_screen.dart';

/// Layar Toko utama — sesi fokus prabayar, pelindung streak, kosmetik
/// monster, isi koin. Implement persis `design/Toko.dc.html` § "Toko".
class TokoScreen extends StatefulWidget {
  const TokoScreen({super.key});

  @override
  State<TokoScreen> createState() => _TokoScreenState();
}

class _TokoScreenState extends State<TokoScreen> {
  Map<String, ProductDetails> _products = {};
  bool _purchasingCoinPack = false;

  @override
  void initState() {
    super.initState();
    final billing = AppScope.of(context).billing;
    billing.updates.listen(_onBillingUpdate);
    billing.queryProducts().then((res) {
      if (!mounted) return;
      setState(() => _products = {for (final p in res.productDetails) p.id: p});
    });
  }

  void _onBillingUpdate(BillingUpdate update) {
    final isCoinPack = CoinPackSku.values.any((s) => s.productId == update.productId);
    if (!isCoinPack || !mounted) return;
    if (update.status == BillingStatus.pending) {
      setState(() => _purchasingCoinPack = true);
      return;
    }
    setState(() => _purchasingCoinPack = false);
    final t = context.s.toko;
    if (update.status == BillingStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.coinsAdded)));
    } else if (update.status == BillingStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.billingError(update.errorKind, update.detail))));
    }
  }

  Future<void> _buyCoinPack(CoinPack pack) async {
    final sku = billingSkuFor(pack);
    final product = _products[sku.productId];
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.toko.packUnavailable)),
      );
      return;
    }
    if (!await ensureAccountForPurchase(context)) return;
    if (!mounted) return;
    await AppScope.of(context).billing.buyCoinPack(product);
  }

  Future<void> _buyStreakShield(int price) async {
    final wallet = AppScope.of(context).wallet;
    if (wallet.coins < price) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => KoinKurangScreen(needed: price, backTitle: context.s.toko.shopTitle)));
      return;
    }
    final t = context.s.toko;
    final konfirmasi = await showKonfirmasiPembelianSheet(context, itemLabel: t.shieldTitle, price: price);
    if (!konfirmasi || !mounted) return;
    final berhasil = await wallet.buyStreakShield(price: price);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(berhasil ? t.shieldReady : t.coinsChanged)),
    );
  }

  Future<void> _buyCosmetic(TokoCosmetic cosmetic) => showKosmetikPreviewSheet(context, cosmetic: cosmetic);

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final rc = scope.remoteConfig;
    final t = context.s.toko;

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: scope.wallet,
                builder: (context, _) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.shopTitle, style: AppTextStyles.title.copyWith(fontSize: 22)),
                                const SizedBox(height: 2),
                                Text(t.shopSubtitle, style: AppTextStyles.caption.copyWith(fontSize: 13)),
                              ],
                            ),
                          ),
                          KoinChip(balance: scope.wallet.coins),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(t.sectionRoutine, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                      const SizedBox(height: AppSpacing.md),
                      _RutinitasCard(
                        icon: Icons.center_focus_strong_rounded,
                        iconColor: AppColors.sekunder,
                        title: t.focusTitle,
                        subtitle: t.focusSub,
                        price: rc.spendFokus25Menit,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BeliSesiFokusScreen())),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _RutinitasCard(
                        icon: Icons.shield_rounded,
                        iconColor: AppColors.aksenHangat,
                        title: t.shieldTitle,
                        subtitle: t.shieldSub,
                        price: rc.spendPelindungStreak,
                        onTap: () => _buyStreakShield(rc.spendPelindungStreak),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(t.sectionMonster, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                      const SizedBox(height: AppSpacing.md),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.95,
                        children: [
                          for (final cosmetic in tokoCosmetics)
                            _KosmetikCard(
                              cosmetic: cosmetic,
                              owned: scope.wallet.ownsCosmetic(cosmetic.id),
                              onTap: () => _buyCosmetic(cosmetic),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const AppBekuTokoSection(),
                      const SizedBox(height: AppSpacing.xl),
                      Text(t.sectionCoins, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < EconomyCoinPacks.all.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _CoinPackCard(
                                pack: EconomyCoinPacks.all[i],
                                product: _products[billingSkuFor(EconomyCoinPacks.all[i]).productId],
                                busy: _purchasingCoinPack,
                                onTap: () => _buyCoinPack(EconomyCoinPacks.all[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        t.ethicNote,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ],
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

class _RutinitasCard extends StatelessWidget {
  const _RutinitasCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(15)),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.kartu,
                border: Border.all(color: AppColors.garis),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 13, color: AppColors.aksenHangat),
                  const SizedBox(width: 4),
                  Text('$price', style: AppTextStyles.chipLabel.copyWith(color: AppColors.aksenHangat, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KosmetikCard extends StatelessWidget {
  const _KosmetikCard({required this.cosmetic, required this.owned, required this.onTap});

  final TokoCosmetic cosmetic;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 62,
              height: 68,
              child: RiungMonster(
                monsterId: cosmetic.monsterId,
                state: MonsterVisualState.jinak,
                size: 62,
                cosmetics: [cosmetic.id],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(context.s.toko.cosmeticName(cosmetic.id), textAlign: TextAlign.center, style: AppTextStyles.chipLabel.copyWith(fontSize: 12, height: 1.35)),
            const SizedBox(height: 6),
            if (owned)
              Text(context.s.toko.owned, style: AppTextStyles.caption.copyWith(color: AppColors.sukses, fontWeight: FontWeight.w700, fontSize: 12))
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 12, color: AppColors.aksenHangat),
                  const SizedBox(width: 4),
                  Text('${cosmetic.price}', style: AppTextStyles.chipLabel.copyWith(color: AppColors.aksenHangat, fontSize: 12)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CoinPackCard extends StatelessWidget {
  const _CoinPackCard({required this.pack, required this.product, required this.busy, required this.onTap});

  final CoinPack pack;
  final ProductDetails? product;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.toko;
    final highlight = pack.badge != null;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Opacity(
        opacity: busy ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 12),
          decoration: BoxDecoration(
            color: highlight ? AppColors.aksenHangat.withValues(alpha: 0.08) : AppColors.permukaan,
            border: Border.all(color: highlight ? AppColors.aksenHangat : AppColors.garis, width: highlight ? 1.5 : 1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              if (pack.badge != null)
                Positioned(
                  top: -18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.aksenHangat, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text(
                      t.coinPackBadge.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(color: AppColors.latar, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.coinPackLabel(pack.id), textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontWeight: FontWeight.w700, fontSize: 11)),
                  const SizedBox(height: 4),
                  const Icon(Icons.monetization_on, size: 20, color: AppColors.aksenHangat),
                  const SizedBox(height: 2),
                  Text('${pack.totalCoins}', style: AppTextStyles.chipLabel.copyWith(color: AppColors.aksenHangat, fontSize: 16)),
                  Text(
                    pack.bonus > 0 ? t.packBonus(pack.bonus) : t.coinUnit,
                    style: AppTextStyles.caption.copyWith(fontSize: 9),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.kartu,
                      border: Border.all(color: AppColors.garis),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      product?.price ?? 'Rp${pack.priceIdr}',
                      style: AppTextStyles.chipLabel.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
