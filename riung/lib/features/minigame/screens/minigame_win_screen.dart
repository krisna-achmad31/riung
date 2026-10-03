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
    final color = AppColors.monsterColors[saboteur.id] ?? AppColors.primer;
    final progress = scope.monsterProgress.progressOf(saboteur.id) ?? MonsterProgress.initial(saboteur.id);
    final before = (progress.progress - EconomyEarn.minigameWinProgressPercent).clamp(0, 100);

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 158,
                          child: RiungMonster(monsterId: saboteur.id, state: MonsterVisualState.liar, size: 150),
                        ),
                        const Positioned(top: -4, right: -6, child: Text('💥', style: TextStyle(fontSize: 26))),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.winKicker, style: AppTextStyles.caption.copyWith(color: AppColors.sukses, fontWeight: FontWeight.w700, letterSpacing: 1.4, fontSize: 10)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(t.winTitle(saboteur.nama), textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 24)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.winBody(score, hits, isReaction),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.55),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatChip(icon: Icons.bolt, color: color, value: '-${EconomyEarn.minigameWinProgressPercent}%', label: t.chipStrengthShort),
                        const SizedBox(width: AppSpacing.sm),
                        _StatChip(icon: Icons.monetization_on, color: AppColors.aksenHangat, value: '+${EconomyEarn.menangGame}', label: t.chipCoins),
                        const SizedBox(width: AppSpacing.sm),
                        _StatChip(icon: Icons.confirmation_number, color: AppColors.sekunder, value: '×${scope.wallet.tickets}', label: t.chipTicketsLeft),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: progress.progress / 100,
                              minHeight: 8,
                              backgroundColor: AppColors.permukaan,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            t.winProgress(saboteur.nama, before, progress.progress),
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
              child: Column(
                children: [
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => MinigameIntroScreen(saboteur: saboteur)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: AppColors.latar,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      ),
                      icon: const Icon(Icons.bolt, size: 17),
                      label: Text(t.attackAgain, style: AppTextStyles.chipLabel.copyWith(color: AppColors.latar, fontSize: 15)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (justTamed) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => MonsterTamedCelebrationScreen(saboteur: saboteur)),
                        );
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    child: Text(t.enoughBack, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: color)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}
