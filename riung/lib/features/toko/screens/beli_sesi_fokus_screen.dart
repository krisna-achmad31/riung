import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/toko_data.dart';
import '../widgets/konfirmasi_pembelian_sheet.dart';
import 'koin_kurang_screen.dart';
import 'pembelian_sukses_screen.dart';

/// "Beli sesi fokus" — 1 sesi vs paket 5 sesi Mode Fokus prabayar. Implement
/// persis `design/Toko.dc.html` § "Beli sesi fokus".
class BeliSesiFokusScreen extends StatefulWidget {
  const BeliSesiFokusScreen({super.key});

  @override
  State<BeliSesiFokusScreen> createState() => _BeliSesiFokusScreenState();
}

class _BeliSesiFokusScreenState extends State<BeliSesiFokusScreen> {
  bool _paket = true;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.toko;
    final rc = scope.remoteConfig;
    final hargaSatu = rc.spendFokus25Menit;
    final hargaPaket = rc.spendFokusBundle5Sesi;
    final jumlah = _paket ? TokoFocusBundle.jumlahPaket : 1;
    final harga = _paket ? hargaPaket : hargaSatu;

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
                  Expanded(
                    child: Text(t.prepaidTitle, textAlign: TextAlign.center, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                  ),
                  ListenableBuilder(
                    listenable: scope.wallet,
                    builder: (context, _) => KoinChip(balance: scope.wallet.coins),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    const SizedBox(
                      width: 100,
                      height: 105,
                      child: RiungMonster(monsterId: 'mengelak', state: MonsterVisualState.liar, size: 100),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      t.prepaidIntro,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _OpsiSesi(
                      title: t.oneSession,
                      subtitle: t.oneSessionSub,
                      price: hargaSatu,
                      selected: !_paket,
                      onTap: () => setState(() => _paket = false),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _OpsiSesi(
                      title: t.bundleTitle(TokoFocusBundle.jumlahPaket),
                      subtitle: t.bundleSub,
                      price: hargaPaket,
                      badge: t.bundleBadge,
                      selected: _paket,
                      onTap: () => setState(() => _paket = true),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.permukaan,
                        border: Border.all(color: AppColors.garis),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Poin(icon: Icons.check_rounded, color: AppColors.sukses, text: t.pointEmergency),
                          _Poin(icon: Icons.wifi_off_rounded, color: AppColors.sekunder, text: t.pointOffline),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
              child: RiungButton(
                label: _paket ? t.buyBundle(jumlah, harga) : t.buyOne(harga),
                onPressed: () => _beli(context, jumlah: jumlah, harga: harga),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _beli(BuildContext context, {required int jumlah, required int harga}) async {
    final wallet = AppScope.of(context).wallet;
    final t = context.s.toko;
    if (wallet.coins < harga) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => KoinKurangScreen(needed: harga, backTitle: t.prepaidTitle)),
      );
      return;
    }
    final label = jumlah == 1 ? t.itemOne : t.itemBundle(jumlah);
    final konfirmasi = await showKonfirmasiPembelianSheet(context, itemLabel: label, price: harga);
    if (!konfirmasi || !context.mounted) return;
    final berhasil = await wallet.buyPrepaidFocusSessions(count: jumlah, price: harga);
    if (!context.mounted) return;
    if (!berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.coinsChanged)));
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PembelianSuksesScreen(
          title: t.sessionsReadyTitle(jumlah),
          subtitle: t.sessionsReadySub,
          statIcon: Icons.center_focus_strong_rounded,
          statValue: '×$jumlah',
          statLabel: t.sessionsLabel,
          ctaMulaiFokus: true,
        ),
      ),
    );
  }
}

class _OpsiSesi extends StatelessWidget {
  const _OpsiSesi({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final int price;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.sekunder.withValues(alpha: 0.1) : AppColors.permukaan,
          border: Border.all(color: selected ? AppColors.sekunder : AppColors.garis, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (badge != null)
              Positioned(
                top: -21,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.sekunder, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text(
                    badge!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.latar, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.subtitle.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, size: 14, color: AppColors.aksenHangat),
                    const SizedBox(width: 4),
                    Text('$price', style: AppTextStyles.subtitle.copyWith(fontSize: 15, color: AppColors.aksenHangat)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Poin extends StatelessWidget {
  const _Poin({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder))),
        ],
      ),
    );
  }
}
