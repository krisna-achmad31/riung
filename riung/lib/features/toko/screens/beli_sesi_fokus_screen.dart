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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(
                title: t.prepaidTitle,
                trailing: ListenableBuilder(listenable: scope.wallet, builder: (context, _) => KoinChip(balance: scope.wallet.coins)),
              ),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                  children: [
                    SizedBox(
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                          ),
                          const RiungIcon3D(RiungIcon.fokus, size: 150),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _OpsiSesi(title: t.oneSession, subtitle: t.oneSessionSub, price: hargaSatu, selected: !_paket, onTap: () => setState(() => _paket = false)),
                    const SizedBox(height: AppSpacing.md),
                    _OpsiSesi(
                      title: t.bundleTitle(TokoFocusBundle.jumlahPaket),
                      subtitle: t.bundleSub,
                      price: hargaPaket,
                      badge: t.bundleBadge,
                      selected: _paket,
                      onTap: () => setState(() => _paket = true),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Poin(icon: Icons.verified_user_outlined, text: t.pointEmergency),
                    _Poin(icon: Icons.wifi_off_rounded, text: t.pointOffline),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RiungButton(
                label: _paket ? t.buyBundle(jumlah, harga) : t.buyOne(harga),
                onPressed: () => _beli(context, jumlah: jumlah, harga: harga),
              ),
            ],
          ),
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
          statIcon: RiungIcon.fokus,
          statValue: '$jumlah',
          statLabel: t.sessionsLabel,
          ctaMulaiFokus: true,
        ),
      ),
    );
  }
}

/// Opsi paket (frame `1 sesi` / `Paket 5 sesi`) dengan harga koin di kanan.
class _OpsiSesi extends StatelessWidget {
  const _OpsiSesi({required this.title, required this.subtitle, required this.price, required this.selected, required this.onTap, this.badge});

  final String title;
  final String subtitle;
  final int price;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return RiungRadioOption(
      title: title,
      subtitle: subtitle,
      selected: selected,
      onTap: onTap,
      badge: badge,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RiungIcon3D(RiungIcon.koin, size: 20),
          const SizedBox(width: 4),
          Text('$price', style: AppTextStyles.title.copyWith(fontSize: 16)),
        ],
      ),
    );
  }
}

class _Poin extends StatelessWidget {
  const _Poin({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primer),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksUtama))),
        ],
      ),
    );
  }
}
