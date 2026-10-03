import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'appbeku_napas_screen.dart';

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
      backgroundColor: AppColors.latar,
      body: SafeArea(
          child: Column(
            children: [
              if (entry != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.kartu,
                      border: Border.all(color: AppColors.garis),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(color: entry.tileColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          alignment: Alignment.center,
                          child: Text(entry.tile, style: AppTextStyles.caption.copyWith(color: entry.tileColor, fontSize: 8, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          t.limitReachedChip(entry.name, usage),
                          style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 158,
                        child: RiungMonster(monsterId: namaMonster, state: MonsterVisualState.liar, size: 150),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        t.interstitialTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.25),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.interstitialBody,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.interstitialNote,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
                child: Column(
                  children: [
                    RiungButton(
                      label: t.breatheFree,
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => AppBekuNapasScreen(packageName: packageName, fromLock: fromLock)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (appBeku.paidUnlockCapReached)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text(t.unlockCapReached, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5)),
                      )
                    else ...[
                      RiungButton(
                        label: _cooldown > 0
                            ? t.waitSeconds(_cooldown)
                            : t.unlockMoreCoins(appBeku.effectiveUnlockPrice(rc.scrollUnlock10Menit)),
                        variant: RiungButtonVariant.secondary,
                        onPressed: _cooldown > 0 ? null : () => _bukaLagi(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.unlocksLeftToday(EconomyScroll.maxPaidUnlocksPerDay - appBeku.paidUnlocksToday)} · ${t.earnedCoinsOnly}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      // Hanya menutup layar jeda: user tetap di layar Riung sebelumnya
                      // (bukan dilempar ke layar utama Android).
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(context.s.common.kembali, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.footerNote,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}
