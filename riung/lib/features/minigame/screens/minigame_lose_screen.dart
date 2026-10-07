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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: RiungBleedListView(
                  children: [
                    _Stage(monsterId: saboteur.id),
                    const SizedBox(height: AppSpacing.sm),
                    Text(t.loseTitle, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                    const SizedBox(height: AppSpacing.sm),
                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, color: AppColors.teksSekunder),
                        children: [
                          TextSpan(text: t.loseBody(score, hits, saboteur.nama, isReaction)),
                          TextSpan(text: '−${EconomyEarn.minigameLoseProgressPercent}%', style: const TextStyle(color: AppColors.sekunder, fontWeight: FontWeight.w700)),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: RiungValueChip(value: '−${EconomyEarn.minigameLoseProgressPercent}%', label: t.chipStillHits)),
                          const SizedBox(width: 10),
                          Expanded(child: RiungValueChip(leading: const RiungIcon3D(RiungIcon.tiket, size: 30), value: '${scope.wallet.tickets}', label: t.chipTicketsLeft)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.kabutSage.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          const Icon(Icons.volunteer_activism_outlined, size: 18, color: AppColors.primer),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t.loseCbtNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.primer))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RiungButton(
                label: t.tryAgain,
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MinigameIntroScreen(saboteur: saboteur))),
              ),
              const SizedBox(height: 10),
              RiungButton(label: context.s.common.nantiSaja, variant: RiungButtonVariant.secondary, onPressed: () => Navigator.of(context).maybePop()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panggung monster dengan aura.
class _Stage extends StatelessWidget {
  const _Stage({required this.monsterId});

  final String monsterId;

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}
