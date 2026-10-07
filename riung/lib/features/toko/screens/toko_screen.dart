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
import '../widgets/koin_price_pill.dart';
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
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: scope.wallet,
          builder: (context, _) {
            return RiungBleedListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (canPop) ...[
                      RiungGlassIconButton(icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).maybePop()),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.shopTitle, style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(t.shopSubtitle, style: AppTextStyles.caption.copyWith(fontSize: 13, height: 1.35, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    KoinChip(balance: scope.wallet.coins),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(t.sectionRoutine),
                _RutinitasCard(
                  icon: RiungIcon.fokus,
                  title: t.focusTitle,
                  subtitle: t.focusSub,
                  price: rc.spendFokus25Menit,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BeliSesiFokusScreen())),
                ),
                const SizedBox(height: AppSpacing.md),
                _RutinitasCard(
                  icon: RiungIcon.pelindung,
                  title: t.shieldTitle,
                  subtitle: t.shieldSub,
                  price: rc.spendPelindungStreak,
                  onTap: () => _buyStreakShield(rc.spendPelindungStreak),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(t.sectionMonster),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 169 / 201,
                  children: [
                    for (final cosmetic in tokoCosmetics)
                      _KosmetikCard(cosmetic: cosmetic, owned: scope.wallet.ownsCosmetic(cosmetic.id), onTap: () => _buyCosmetic(cosmetic)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const AppBekuTokoSection(),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(t.sectionCoins),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < EconomyCoinPacks.all.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
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
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.primerLembut.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.primer),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t.ethicNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.primer))),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(text, style: AppTextStyles.title.copyWith(fontSize: 17)),
    );
  }
}

/// Baris "Buat rutinitasmu" (frame `Baris …`): ikon 3D, judul, sub, harga.
class _RutinitasCard extends StatelessWidget {
  const _RutinitasCard({required this.icon, required this.title, required this.subtitle, required this.price, required this.onTap});

  final RiungIcon icon;
  final String title;
  final String subtitle;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      onTap: onTap,
      radius: 24,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          RiungIcon3D(icon, size: 58),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.35, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          KoinPricePill(label: '$price'),
        ],
      ),
    );
  }
}

/// Kartu kosmetik (frame `Kosmetik …`): badge rarity, art item 3D, nama,
/// harga atau "Dimiliki".
class _KosmetikCard extends StatelessWidget {
  const _KosmetikCard({required this.cosmetic, required this.owned, required this.onTap});

  final TokoCosmetic cosmetic;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.toko;
    final rarity = cosmetic.rarity;
    return RiungGlassCard(
      onTap: onTap,
      radius: 26,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: rarity.background, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(rarity.label(t), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: rarity.foreground)),
          ),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, c) {
                  final size = c.biggest.shortestSide.clamp(40.0, 96.0);
                  return Image.asset(cosmetic.artAsset, width: size, height: size, fit: BoxFit.contain, cacheWidth: (size * 3).round());
                },
              ),
            ),
          ),
          Text(t.cosmeticName(cosmetic.id), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, height: 1.25, color: AppColors.teksUtama)),
          const SizedBox(height: 6),
          if (owned)
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  const Icon(Icons.check_rounded, size: 14, color: AppColors.primer),
                  const SizedBox(width: 4),
                  Text(t.owned, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primer)),
                ],
              ),
            )
          else
            KoinPricePill(label: t.coinsPrice(cosmetic.price)),
        ],
      ),
    );
  }
}

/// Paket koin (frame `Paket …`): yang terpopuler berbingkai emas, harga
/// berlatar tinta.
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
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 14),
          decoration: BoxDecoration(
            color: highlight ? AppColors.permukaanPadat.withValues(alpha: 0.88) : AppColors.kartu,
            border: Border.all(color: highlight ? AppColors.emas : AppColors.garis, width: highlight ? 2 : AppGlass.edgeWidth),
            borderRadius: BorderRadius.circular(24),
            boxShadow: highlight ? AppGlass.shadow : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 15,
                child: highlight
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: AppColors.emasLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        alignment: Alignment.center,
                        child: Text(t.coinPackBadge, style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.emasGelap)),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              RiungIcon3D(RiungIcon.koin, size: highlight ? 60 : 50),
              const SizedBox(height: 4),
              Text('${pack.totalCoins}', style: AppTextStyles.title.copyWith(fontSize: 22, height: 1.2)),
              Text(pack.bonus > 0 ? t.packBonus(pack.bonus) : t.coinUnit, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: highlight ? AppColors.tinta : AppColors.permukaanPadat.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    product?.price ?? t.priceShort(pack.priceIdr),
                    style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: highlight ? AppColors.diAtasTinta : AppColors.teksUtama),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
