import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'appbeku_napas_screen.dart';
import '../widgets/paid_unlock_button.dart';

/// Layar yang muncul di dalam Riung saat sebuah aplikasi yang dibekukan
/// melewati batas harian. BUKAN overlay di atas aplikasi lain (Android
/// tidak izinkan tanpa SYSTEM_ALERT_WINDOW yang berisiko ditolak Play
/// review) — ini muncul saat user kembali membuka Riung, sesuai catatan
/// desain sendiri. Implement persis `design/AppBeku.dc.html` §
/// "Interstisial — batas tercapai".
class AppBekuInterstitialScreen extends StatefulWidget {
  const AppBekuInterstitialScreen({super.key, required this.packageName, this.fromLock = false});

  final String packageName;

  /// Dibuka oleh service kunci (aplikasi yang dibekukan ada di belakang layar
  /// ini): "Kembali" ke layar utama dan buka-waktu mengembalikan ke aplikasinya.
  final bool fromLock;

  @override
  State<AppBekuInterstitialScreen> createState() => _AppBekuInterstitialScreenState();
}

class _AppBekuInterstitialScreenState extends State<AppBekuInterstitialScreen> {
  String get packageName => widget.packageName;
  bool get fromLock => widget.fromLock;

  /// Jeda sebelum tombol buka-berbayar aktif: keputusan harus sadar, bukan
  /// refleks. Napas gratis & "Kembali" tidak pernah menunggu.
  int _cooldown = EconomyScroll.unlockCooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _cooldown = (_cooldown - 1).clamp(0, EconomyScroll.unlockCooldownSeconds));
      if (_cooldown == 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _bukaLagi(BuildContext context) async {
    final scope = AppScope.of(context);
    final rc = scope.remoteConfig;
    final result = await scope.appBeku.unlockMinutes(
      wallet: scope.wallet,
      packageName: packageName,
      minutes: 10,
      price: rc.scrollUnlock10Menit,
    );
    if (!context.mounted) return;
    if (result == UnlockResult.ok) {
      Navigator.of(context).maybePop();
      if (fromLock) await scope.appBeku.moveToBack();
    } else {
      final t = scope.language.strings.appbeku;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result == UnlockResult.dailyCapReached ? t.unlockCapReached : t.notEnoughEarnedCoins)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.appbeku;
    final entry = AppBekuCatalog.byPackage(packageName);
    final appBeku = AppScope.of(context).appBeku;
    final rc = AppScope.of(context).remoteConfig;
    final usage = appBeku.usageMinutesOf(packageName);
    final namaMonster = 'kabut';

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _FrozenFeed()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
              child: Column(
                children: [
                  if (entry != null)
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
                      decoration: BoxDecoration(
                        color: AppColors.permukaan,
                        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const RiungIcon3D(RiungIcon.aplikasiBeku, size: 22),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              t.limitReachedChip(entry.name, usage),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksSekunder),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                          ),
                          RiungMonster(monsterId: namaMonster, state: MonsterVisualState.jinak, size: 180, applyBossScale: false),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: AppGlass.card(radius: 34, color: AppColors.permukaan),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.interstitialTitle, style: AppTextStyles.display.copyWith(fontSize: 22, height: 1.2)),
                        const SizedBox(height: 10),
                        Text(t.interstitialBody, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                        const SizedBox(height: AppSpacing.md),
                        RiungButton(
                          label: t.breatheFree,
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => AppBekuNapasScreen(packageName: packageName, fromLock: fromLock)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (appBeku.paidUnlockCapReached)
                          Text(t.unlockCapReached, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5, color: AppColors.teksSekunder))
                        else ...[
                          PaidUnlockButton(
                            label: _cooldown > 0 ? t.waitSeconds(_cooldown) : t.unlockMoreCoins(appBeku.effectiveUnlockPrice(rc.scrollUnlock10Menit)),
                            onTap: _cooldown > 0 ? null : () => _bukaLagi(context),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              t.unlocksLeftToday(EconomyScroll.maxPaidUnlocksPerDay - appBeku.paidUnlocksToday),
                              style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.teksRedup),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.kartu, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.teksSekunder),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t.earnedCoinsOnly, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksSekunder))),
                      ],
                    ),
                  ),
                  // Jalan keluar tanpa bayar: tutup layar jeda, kembali ke layar
                  // Riung sebelumnya (bukan dilempar ke layar utama Android).
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(context.s.common.kembali, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Latar "feed membeku" (frame `Feed di belakang` + `Lapisan beku`): kartu
/// feed buram di bawah lapisan es putih dan kristal salju.
class _FrozenFeed extends StatelessWidget {
  const _FrozenFeed();

  @override
  Widget build(BuildContext context) {
    const posts = [AppColors.aksenHangatLembut, AppColors.langitLembut, AppColors.sekunderLembut, AppColors.emasLembut];
    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
            child: Column(
              children: [
                for (final c in posts)
                  Container(height: 190, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(22))),
              ],
            ),
          ),
        ),
        Positioned.fill(child: ColoredBox(color: AppColors.permukaanPadat.withValues(alpha: 0.45))),
        const Positioned(left: 30, top: 110, child: Icon(Icons.ac_unit_rounded, size: 40, color: AppColors.permukaan)),
        const Positioned(right: 34, top: 80, child: Icon(Icons.ac_unit_rounded, size: 36, color: AppColors.permukaan)),
        const Positioned(right: 57, top: 420, child: Icon(Icons.ac_unit_rounded, size: 42, color: AppColors.permukaan)),
        const Positioned(left: 24, top: 466, child: Icon(Icons.ac_unit_rounded, size: 25, color: AppColors.permukaan)),
      ],
    );
  }
}
