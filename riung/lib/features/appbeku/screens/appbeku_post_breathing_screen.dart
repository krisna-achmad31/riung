import 'package:flutter/material.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

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
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: AppColors.sekunder,
        alignment: const Alignment(0, -0.5),
        opacity: 0.16,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 130,
                        height: 137,
                        child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 130),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        t.postKicker,
                        style: AppTextStyles.caption.copyWith(color: AppColors.sekunder, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 1.4),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(t.postTitle, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 24)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.postBody,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(fontSize: 13),
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
                      label: t.closeApp(entry?.name),
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RiungButton(
                      label: t.unlockShortCoins(AppScope.of(context).appBeku.effectiveUnlockPrice(rc.scrollUnlock10Menit)),
                      variant: RiungButtonVariant.secondary,
                      onPressed: () => _bukaLagi(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.noWrongAnswer,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
