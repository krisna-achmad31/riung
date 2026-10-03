import 'package:flutter/material.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../toko/screens/koin_kurang_screen.dart';
import '../../toko/widgets/konfirmasi_pembelian_sheet.dart';

/// Section "Buka Waktu Scroll" di layar Toko — cuma tampil kalau ada
/// aplikasi yang sedang dibekukan (tanpa itu, "buka waktu" tidak berarti
/// apa-apa). Implement persis `design/AppBeku.dc.html` §
/// "Toko — Buka Waktu Scroll".
class AppBekuTokoSection extends StatelessWidget {
  const AppBekuTokoSection({super.key});

  Future<void> _pilihAppLaluBeli(BuildContext context, {required int minutes, required int price}) async {
    final scope = AppScope.of(context);
    final t = scope.language.strings.appbeku;
    final enabled = scope.appBeku.enabledFrozenApps;
    if (enabled.isEmpty) return;

    String packageName;
    if (enabled.length == 1) {
      packageName = enabled.first.packageName;
    } else {
      final picked = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.permukaan,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.garis, borderRadius: BorderRadius.circular(AppRadius.pill))),
              const SizedBox(height: AppSpacing.lg),
              Text(t.whichApp, style: AppTextStyles.subtitle.copyWith(fontSize: 16)),
              const SizedBox(height: AppSpacing.md),
              for (final setting in enabled)
                Builder(builder: (context) {
                  final entry = AppBekuCatalog.byPackage(setting.packageName);
                  if (entry == null) return const SizedBox.shrink();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: entry.tileColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(11)),
                      alignment: Alignment.center,
                      child: Text(entry.tile, style: AppTextStyles.chipLabel.copyWith(color: entry.tileColor, fontSize: 12)),
                    ),
                    title: Text(entry.name, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                    onTap: () => Navigator.of(sheetContext).pop(entry.packageName),
                  );
                }),
            ],
          ),
        ),
      );
      if (picked == null) return;
      packageName = picked;
    }

    if (!context.mounted) return;
    await _beli(context, packageName: packageName, minutes: minutes, price: price);
  }

  Future<void> _beli(BuildContext context, {required String packageName, required int minutes, required int price}) async {
    final scope = AppScope.of(context);
    final t = scope.language.strings;
    final wallet = scope.wallet;
    final entry = AppBekuCatalog.byPackage(packageName);
    final charged = scope.appBeku.effectiveUnlockPrice(price);
    if (!_boleh(context, charged)) return;
    final label = t.appbeku.itemMinutes(minutes, entry?.name);
    final konfirmasi = await showKonfirmasiPembelianSheet(context, itemLabel: label, price: charged);
    if (!konfirmasi || !context.mounted) return;
    final result = await scope.appBeku.unlockMinutes(wallet: wallet, packageName: packageName, minutes: minutes, price: price);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_pesan(t.appbeku, result))));
  }

  /// Gerbang pengaman etis sebelum membuka sheet konfirmasi: batas harian,
  /// lalu koin hasil latihan. Kalau koin total memang kurang, arahkan ke layar
  /// "koin kurang" (latihan dulu sebelum beli).
  bool _boleh(BuildContext context, int charged) {
    final scope = AppScope.of(context);
    final t = scope.language.strings;
    if (scope.appBeku.paidUnlockCapReached) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.appbeku.unlockCapReached)));
      return false;
    }
    if (scope.wallet.coins < charged) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => KoinKurangScreen(needed: charged, backTitle: t.toko.shopTitle)));
      return false;
    }
    if (scope.wallet.earnedCoins < charged) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.appbeku.notEnoughEarnedCoins)));
      return false;
    }
    return true;
  }

  String _pesan(AppbekuStrings t, UnlockResult result) {
    switch (result) {
      case UnlockResult.ok:
        return t.unlocked;
      case UnlockResult.dailyCapReached:
        return t.unlockCapReached;
      case UnlockResult.notEnoughEarnedCoins:
        return t.notEnoughEarnedCoins;
    }
  }

  Future<void> _beliBundelSantai(BuildContext context, int price) async {
    final scope = AppScope.of(context);
    final t = scope.language.strings;
    final ig = scope.appBeku.frozenApps[AppBekuCatalog.instagram.packageName];
    final tt = scope.appBeku.frozenApps[AppBekuCatalog.tiktok.packageName];
    if (ig?.enabled != true || tt?.enabled != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.appbeku.relaxedNeedsApps)),
      );
      return;
    }
    final wallet = scope.wallet;
    final charged = scope.appBeku.effectiveUnlockPrice(price);
    if (!_boleh(context, charged)) return;
    final konfirmasi = await showKonfirmasiPembelianSheet(context, itemLabel: t.appbeku.itemRelaxed, price: charged);
    if (!konfirmasi || !context.mounted) return;
    // Bundel dihitung SATU buka-berbayar: langkah pertama gratis & tidak
    // dihitung, langkah kedua yang memotong koin dan menambah hitungan.
    await scope.appBeku.unlockMinutes(wallet: wallet, packageName: AppBekuCatalog.instagram.packageName, minutes: 15, price: 0, countsAsUnlock: false);
    final result = await scope.appBeku.unlockMinutes(wallet: wallet, packageName: AppBekuCatalog.tiktok.packageName, minutes: 15, price: price);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result == UnlockResult.ok ? t.appbeku.relaxedUnlocked : _pesan(t.appbeku, result))),
    );
  }

  Future<void> _beliBundelSosmed(BuildContext context, int price) async {
    final scope = AppScope.of(context);
    final t = scope.language.strings;
    final sosmedAktif = scope.appBeku.enabledFrozenApps
        .where((a) => AppBekuCatalog.sosmed.any((s) => s.packageName == a.packageName))
        .toList();
    if (sosmedAktif.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.appbeku.socialNeedsApp)),
      );
      return;
    }
    final wallet = scope.wallet;
    final charged = scope.appBeku.effectiveUnlockPrice(price);
    if (!_boleh(context, charged)) return;
    final konfirmasi = await showKonfirmasiPembelianSheet(context, itemLabel: t.appbeku.itemAllSocial, price: charged);
    if (!konfirmasi || !context.mounted) return;
    var result = UnlockResult.ok;
    for (var i = 0; i < sosmedAktif.length; i++) {
      // Hanya langkah pertama yang memotong koin & dihitung sebagai satu buka-berbayar.
      result = await scope.appBeku.unlockMinutes(
        wallet: wallet,
        packageName: sosmedAktif[i].packageName,
        minutes: 30,
        price: i == 0 ? price : 0,
        countsAsUnlock: i == 0,
      );
      if (result != UnlockResult.ok) break;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result == UnlockResult.ok ? t.appbeku.socialUnlocked : _pesan(t.appbeku, result))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.appBeku,
      builder: (context, _) {
        if (scope.appBeku.enabledFrozenApps.isEmpty) return const SizedBox.shrink();
        final rc = scope.remoteConfig;
        final t = context.s.appbeku;
        final rows = [
          (10, rc.scrollUnlock10Menit),
          (20, rc.scrollUnlock20Menit),
          (30, rc.scrollUnlock30Menit),
          (60, rc.scrollUnlock60Menit),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.unlockSectionTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.unlockSectionBody,
              style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final row in rows) ...[
              _UnlockRow(minutes: row.$1, price: row.$2, onTap: () => _pilihAppLaluBeli(context, minutes: row.$1, price: row.$2)),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(t.bundles, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.md),
            _BundleRow(
              icon: Icons.favorite_rounded,
              iconColor: AppColors.sekunder,
              title: t.relaxedTitle,
              subtitle: t.relaxedSub,
              price: rc.scrollBundleSantai,
              onTap: () => _beliBundelSantai(context, rc.scrollBundleSantai),
            ),
            const SizedBox(height: AppSpacing.sm),
            _BundleRow(
              icon: Icons.star_rounded,
              iconColor: AppColors.aksenHangat,
              title: t.allSocialTitle,
              subtitle: t.allSocialSub,
              price: rc.scrollBundleSosmed,
              badge: t.saveBadge(rc.scrollBundleSosmedDiscountPercent),
              highlight: true,
              onTap: () => _beliBundelSosmed(context, rc.scrollBundleSosmed),
            ),
          ],
        );
      },
    );
  }
}

class _UnlockRow extends StatelessWidget {
  const _UnlockRow({required this.minutes, required this.price, required this.onTap});

  final int minutes;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.primer.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const Icon(Icons.center_focus_strong_rounded, size: 19, color: AppColors.primer),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.s.appbeku.minutesFull(minutes), style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                  Text(context.s.appbeku.forOneApp, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

class _BundleRow extends StatelessWidget {
  const _BundleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
    this.badge,
    this.highlight = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int price;
  final VoidCallback onTap;
  final String? badge;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: highlight ? AppColors.aksenHangat.withValues(alpha: 0.08) : AppColors.permukaan,
          border: Border.all(color: highlight ? AppColors.aksenHangat : AppColors.garis, width: highlight ? 1.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
                  decoration: BoxDecoration(color: AppColors.aksenHangat, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text(badge!, style: AppTextStyles.caption.copyWith(color: AppColors.latar, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 19, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                      Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
          ],
        ),
      ),
    );
  }
}
