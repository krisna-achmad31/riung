import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../checkin/screens/checkin_mood_screen.dart';
import 'toko_screen.dart';

/// Koinmu belum cukup untuk item yang dituju — selalu menawarkan latihan
/// dulu sebelum "isi koin di Toko" (CLAUDE.md aturan #4: layar koin-kurang
/// selalu menawarkan latihan dulu). Implement persis
/// `design/Toko.dc.html` § "Koin kurang".
class KoinKurangScreen extends StatelessWidget {
  const KoinKurangScreen({super.key, required this.needed, required this.backTitle});

  final int needed;

  /// Judul layar yang mau dituju sebelum tombol back di-dim (mis. "Sesi
  /// fokus prabayar", "Toko").
  final String backTitle;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.toko;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Opacity(
              opacity: 0.3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.teksSekunder),
                    ),
                    Text(backTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.permukaan,
                  border: Border(top: BorderSide(color: AppColors.garis)),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xl),
                child: SingleChildScrollView(
                  child: ListenableBuilder(
                    listenable: scope.wallet,
                    builder: (context, _) {
                      final kurang = (needed - scope.wallet.coins).clamp(0, needed);
                      return Column(
                        children: [
                          Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(color: AppColors.garis, borderRadius: BorderRadius.circular(AppRadius.pill)),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const SizedBox(
                            width: 88,
                            height: 92,
                            child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 88),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(t.notEnoughTitle, textAlign: TextAlign.center, style: AppTextStyles.subtitle.copyWith(fontSize: 18)),
                          const SizedBox(height: AppSpacing.sm),
                          Text.rich(
                            TextSpan(
                              style: AppTextStyles.body,
                              children: [
                                TextSpan(text: t.needPrefix),
                                TextSpan(text: t.needCoins(needed), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.aksenHangat)),
                                TextSpan(text: t.youHave),
                                TextSpan(text: '${scope.wallet.coins}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.teksUtama)),
                                TextSpan(text: t.needSuffix),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.kartu,
                              border: Border.all(color: AppColors.garis),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.fastestWays,
                                  style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _BarisReward(label: t.wayCheckin, value: '+${scope.remoteConfig.earnCheckinHarian}'),
                                _BarisReward(label: t.wayJournal, value: '+${scope.remoteConfig.earnJurnal}'),
                                _BarisReward(label: t.wayMeditation, value: '+${scope.remoteConfig.earnMeditasi}'),
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                                  child: Container(
                                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.garis))),
                                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                                    child: Text(
                                      t.streakBonus(scope.remoteConfig.earnStreak7Hari, scope.remoteConfig.earnStreak30Hari),
                                      style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          RiungButton(
                            label: t.startCheckin(scope.remoteConfig.earnCheckinHarian),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CheckInMoodScreen()),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          RiungButton(
                            label: t.orTopUp,
                            variant: RiungButtonVariant.secondary,
                            onPressed: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const TokoScreen()),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            kurang > 0 ? t.stillMissing(kurang) : t.enoughNow,
                            style: AppTextStyles.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.xs),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisReward extends StatelessWidget {
  const _BarisReward({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(fontSize: 12)),
          Text(value, style: AppTextStyles.chipLabel.copyWith(color: AppColors.aksenHangat, fontSize: 12)),
        ],
      ),
    );
  }
}
