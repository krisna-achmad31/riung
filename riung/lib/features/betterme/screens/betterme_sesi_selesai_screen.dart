import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/betterme_content.dart';
import '../logic/betterme_progress.dart';

/// Konfirmasi satu sesi selesai + koin bertambah + progres level naik.
class BetterMeSesiSelesaiScreen extends StatelessWidget {
  const BetterMeSesiSelesaiScreen({super.key, required this.session, required this.sudahDapatKoinSebelumnya});

  final BetterMeSession session;
  final bool sudahDapatKoinSebelumnya;

  @override
  Widget build(BuildContext context) {
    final t = context.s.betterme;
    final scope = AppScope.of(context);
    final progress = BetterMeProgress(scope.prefs);
    final level = betterMeLevels.firstWhere((l) => l.number == session.level);
    final selesaiDiLevel = progress.completedInLevel(level.number);

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: AppColors.sukses,
        alignment: const Alignment(0, -0.6),
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
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sukses.withValues(alpha: 0.14),
                          border: Border.all(color: AppColors.sukses, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.check_rounded, size: 38, color: AppColors.sukses),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(t.sessionDone, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 23)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(t.session(session.id).judul, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 14)),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!sudahDapatKoinSebelumnya)
                            _StatBox(icon: Icons.monetization_on, color: AppColors.aksenHangat, value: '+${EconomyEarn.betterMeLesson}', label: t.coins),
                          if (!sudahDapatKoinSebelumnya) const SizedBox(width: AppSpacing.sm),
                          _StatBox(icon: Icons.auto_awesome_rounded, color: AppColors.sekunder, value: '$selesaiDiLevel/${level.sessions.length}', label: t.sessionsInLevel),
                        ],
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
                      label: context.s.common.lanjut,
                      onPressed: () {
                        // Balik ke LevelIntroScreen (lewati SesiDetailScreen
                        // di antaranya) — SesiContentScreen sudah diganti
                        // (pushReplacement) jadi layar ini sendiri, bukan
                        // ditumpuk di atasnya.
                        final nav = Navigator.of(context);
                        nav.pop();
                        nav.pop();
                      },
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

class _StatBox extends StatelessWidget {
  const _StatBox({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.chipLabel.copyWith(color: color, fontSize: 16)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
