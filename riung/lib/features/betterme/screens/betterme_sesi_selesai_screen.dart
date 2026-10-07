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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      height: 230,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 230,
                            height: 230,
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                          ),
                          const RiungIcon3D(RiungIcon.kepribadian, size: 170),
                          const Positioned(left: 20, top: 40, child: Icon(Icons.auto_awesome, size: 22, color: AppColors.emas)),
                          const Positioned(right: 22, top: 40, child: Icon(Icons.auto_awesome, size: 18, color: AppColors.emas)),
                          const Positioned(right: 12, bottom: 30, child: Icon(Icons.auto_awesome, size: 20, color: AppColors.emas)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.sessionDone, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(t.session(session.id).judul, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        if (!sudahDapatKoinSebelumnya) ...[
                          Expanded(child: RiungStatTile(leading: const RiungIcon3D(RiungIcon.koin, size: 40), value: '+${EconomyEarn.betterMeLesson}', label: t.coins)),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: RiungStatTile(
                            leading: const RiungIcon3D(RiungIcon.kepribadian, size: 40),
                            value: '$selesaiDiLevel/${level.sessions.length}',
                            label: t.sessionsInLevel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              RiungButton(
                label: context.s.common.lanjut,
                onPressed: () {
                  // Balik ke LevelIntroScreen (lewati SesiDetailScreen di
                  // antaranya) — SesiContentScreen sudah diganti
                  // (pushReplacement) jadi layar ini sendiri.
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
