import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'minigame_intro_screen.dart';

/// Kalah — tetap suportif, tetap dapat progres. Implement persis
/// `design/Monster.dc.html` § Kalah — tetap suportif (CLAUDE.md aturan #4:
/// anti-guilt design).
class MinigameLoseScreen extends StatelessWidget {
  const MinigameLoseScreen({super.key, required this.saboteur, required this.hits, required this.score, required this.isReaction});

  final Saboteur saboteur;
  final int hits;
  final int score;

  /// Lihat catatan yang sama di `MinigameWinScreen.isReaction`.
  final bool isReaction;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.minigame;
    final color = AppColors.monsterColors[saboteur.id] ?? AppColors.primer;

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
                    SizedBox(
                      width: 132,
                      height: 139,
                      child: RiungMonster(monsterId: saboteur.id, state: MonsterVisualState.liar, size: 132),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.loseTitle, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 22)),
                    const SizedBox(height: AppSpacing.sm),
                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.6),
                        children: [
                          TextSpan(text: t.loseBody(score, hits, saboteur.nama, isReaction)),
                          TextSpan(text: '-${EconomyEarn.minigameLoseProgressPercent}%', style: const TextStyle(color: AppColors.monsterHakim, fontWeight: FontWeight.w700)),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatChip(icon: Icons.bolt, color: color, value: '-${EconomyEarn.minigameLoseProgressPercent}%', label: t.chipStillHits),
                        const SizedBox(width: AppSpacing.sm),
                        _StatChip(icon: Icons.confirmation_number, color: AppColors.sekunder, value: '×${scope.wallet.tickets}', label: t.chipTicketsLeft),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(14),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(color: AppColors.sekunder.withValues(alpha: 0.08), border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.25)), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.sekunder),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              t.loseCbtNote,
                              style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5),
                            ),
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
                      label: Text(t.tryAgain, style: AppTextStyles.chipLabel.copyWith(color: AppColors.latar, fontSize: 15)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(context.s.common.nantiSaja, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
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
