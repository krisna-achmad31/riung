import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../monster/screens/monster_tamed_celebration_screen.dart';
import 'minigame_intro_screen.dart';

/// Serangan berhasil. Implement persis `design/Monster.dc.html` § Menang.
class MinigameWinScreen extends StatelessWidget {
  const MinigameWinScreen({
    super.key,
    required this.saboteur,
    required this.hits,
    required this.score,
    required this.justTamed,
    required this.isReaction,
  });

  final Saboteur saboteur;
  final int hits;
  final int score;
  final bool justTamed;

  /// Sesi yang baru selesai memakai mekanik "Lepaskan Pikiran" (gelembung),
  /// bukan Block Breaker — dipakai supaya salinan menang cocok dengan
  /// mini-game yang sungguh dimainkan (lihat `MinigameStrings.winBody`).
  final bool isReaction;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.minigame;
    final progress = scope.monsterProgress.progressOf(saboteur.id) ?? MonsterProgress.initial(saboteur.id);
    final before = (progress.progress - EconomyEarn.minigameWinProgressPercent).clamp(0, 100);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: RiungBleedListView(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primerLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(t.winKicker, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.primer)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _Stage(monsterId: saboteur.id, sparkles: true),
                    const SizedBox(height: AppSpacing.sm),
                    Text(t.winTitle(saboteur.nama), textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.2)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(t.winBody(score, hits, isReaction), textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.lg),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: RiungValueChip(value: '−${EconomyEarn.minigameWinProgressPercent}%', label: t.chipStrengthShort)),
                          const SizedBox(width: 10),
                          Expanded(child: RiungValueChip(leading: const RiungIcon3D(RiungIcon.koin, size: 30), value: '+${EconomyEarn.menangGame}', label: t.chipCoins)),
                          const SizedBox(width: 10),
                          Expanded(child: RiungValueChip(leading: const RiungIcon3D(RiungIcon.tiket, size: 30), value: '×${scope.wallet.tickets}', label: t.chipTicketsLeft)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.sekunderLembut.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.sekunder),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(t.winProgress(saboteur.nama, before, progress.progress), style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.sekunder)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RiungButton(
                label: t.attackAgain,
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MinigameIntroScreen(saboteur: saboteur))),
              ),
              const SizedBox(height: 10),
              RiungButton(
                label: t.enoughBack,
                variant: RiungButtonVariant.secondary,
                onPressed: () {
                  if (justTamed) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MonsterTamedCelebrationScreen(saboteur: saboteur)));
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panggung monster dengan aura (+ kilau emas opsional).
class _Stage extends StatelessWidget {
  const _Stage({required this.monsterId, this.sparkles = false});

  final String monsterId;
  final bool sparkles;

  @override
  Widget build(BuildContext context) {
    Widget spark(double l, double tp, double size) => Positioned(left: l, top: tp, child: Icon(Icons.auto_awesome, size: size, color: AppColors.emas));
    return Center(
      child: SizedBox(
        width: 300,
        height: 240,
        child: Stack(
          children: [
            Positioned(
              left: 35,
              top: 0,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
              ),
            ),
            Positioned(left: 45, top: 15, child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.liar, size: 210, applyBossScale: false)),
            if (sparkles) ...[spark(20, 40, 22), spark(260, 50, 18), spark(250, 190, 20)],
          ],
        ),
      ),
    );
  }
}
