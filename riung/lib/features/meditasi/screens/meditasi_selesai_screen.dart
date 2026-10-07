import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/meditation_catalog.dart';

/// Sesi meditasi selesai. Implement persis `design/Meditasi.dc.html`
/// § Sesi selesai.
class MeditasiSelesaiScreen extends StatelessWidget {
  const MeditasiSelesaiScreen({super.key, required this.session});

  final MeditationSession session;

  @override
  Widget build(BuildContext context) {
    final t = context.s.meditasi;
    final monsterId = session.targetMonsterId;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: SizedBox(
                          width: 300,
                          height: 250,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 25,
                                top: 0,
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)]),
                                  ),
                                ),
                              ),
                              const Positioned(left: 16, top: 110, child: RiungIcon3D(RiungIcon.meditasi, size: 130)),
                              Positioned(
                                left: 90,
                                top: 20,
                                child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 190, applyBossScale: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(t.doneTitle(session.defaultDuration), style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                      const SizedBox(height: AppSpacing.md),
                      Text(t.doneBody, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: RiungStatTile(
                              leading: const RiungIcon3D(RiungIcon.koin, size: 44),
                              value: '+${EconomyEarn.meditasi}',
                              label: t.coins,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RiungStatTile(
                              leading: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 44, applyBossScale: false),
                              value: '+3%',
                              label: context.s.common.monsterName(monsterId),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RiungButton(label: context.s.home.backToHome, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
              const SizedBox(height: 10),
              RiungButton(label: t.repeatSession, variant: RiungButtonVariant.secondary, onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}
