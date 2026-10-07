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
    final rc = scope.remoteConfig;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: RiungGlassIconButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).maybePop()),
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
                          const Padding(padding: EdgeInsets.only(right: 60, bottom: 30), child: RiungIcon3D(RiungIcon.koin, size: 110)),
                          const Padding(
                            padding: EdgeInsets.only(left: 110, top: 50),
                            child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 90, applyBossScale: false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.notEnoughTitle, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                    const SizedBox(height: AppSpacing.md),
                    ListenableBuilder(
                      listenable: scope.wallet,
                      builder: (context, _) => Text.rich(
                        TextSpan(
                          style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder),
                          children: [
                            TextSpan(text: t.needPrefix),
                            TextSpan(text: t.needCoins(needed), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.teksUtama)),
                            TextSpan(text: t.youHave),
                            TextSpan(text: '${scope.wallet.coins}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.teksUtama)),
                            TextSpan(text: t.needSuffix),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    RiungGlassCard(
                      radius: 26,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.fastestWays, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.primer)),
                          const SizedBox(height: 10),
                          _BarisReward(icon: RiungIcon.checkin, label: t.wayCheckin, value: '+${rc.earnCheckinHarian}'),
                          _BarisReward(icon: RiungIcon.jurnal, label: t.wayJournal, value: '+${rc.earnJurnal}'),
                          _BarisReward(icon: RiungIcon.meditasi, label: t.wayMeditation, value: '+${rc.earnMeditasi}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.emasLembut.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          const RiungIcon3D(RiungIcon.streak, size: 26),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t.streakBonus(rc.earnStreak7Hari, rc.earnStreak30Hari),
                              style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.35, fontWeight: FontWeight.w600, color: AppColors.emasGelap),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RiungButton(
                label: t.startCheckin(rc.earnCheckinHarian),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckInMoodScreen())),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const TokoScreen())),
                child: Text(t.orTopUp, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksSekunder)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris cara dapat koin (frame `Check-in pagi …`): ikon 3D, label, +koin.
class _BarisReward extends StatelessWidget {
  const _BarisReward({required this.icon, required this.label, required this.value});

  final RiungIcon icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          RiungIcon3D(icon, size: 38),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teksUtama))),
          Text(value, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.primer)),
        ],
      ),
    );
  }
}
