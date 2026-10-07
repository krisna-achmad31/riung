import 'package:flutter/material.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/paid_unlock_button.dart';

/// Setelah napas selesai, tanpa rasa bersalah apa pun jawabannya.
/// Implement persis `design/AppBeku.dc.html` § "Setelah napas".
class AppBekuPostBreathingScreen extends StatelessWidget {
  const AppBekuPostBreathingScreen({super.key, required this.packageName, this.fromLock = false});

  final String packageName;
  final bool fromLock;

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
      Navigator.of(context).popUntil((r) => r.isFirst);
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
    final rc = AppScope.of(context).remoteConfig;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.langitLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(t.postKicker, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.langitGelap)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 210,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 210,
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                          ),
                          const RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 190, applyBossScale: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(alignment: Alignment.centerLeft, child: Text(t.postTitle, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2))),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.postBody, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  ],
                ),
              ),
              RiungButton(label: t.closeApp(entry?.name), onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
              const SizedBox(height: 10),
              PaidUnlockButton(
                label: t.unlockShortCoins(AppScope.of(context).appBeku.effectiveUnlockPrice(rc.scrollUnlock10Menit)),
                onTap: () => _bukaLagi(context),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(t.noWrongAnswer, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksRedup)),
            ],
          ),
        ),
      ),
    );
  }
}
