import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'kartu_pemain_screen.dart';

/// Sesi Mode Fokus selesai — perayaan hangat, progres monster naik.
/// Implement persis `design/Home.dc.html` § Sesi selesai.
///
/// Monster penemani Mode Fokus selalu Si Waswas (pilihan tetap desain,
/// bukan dinamis per user) — progresnya naik
/// [EconomyEarn.fokusProgressPercent]% begitu layar ini muncul.
class SesiSelesaiScreen extends StatefulWidget {
  const SesiSelesaiScreen({super.key, this.duration = const Duration(minutes: 25)});

  final Duration duration;

  @override
  State<SesiSelesaiScreen> createState() => _SesiSelesaiScreenState();
}

class _SesiSelesaiScreenState extends State<SesiSelesaiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).monsterProgress.tambahProgres(
            saboteurId: 'waswas',
            delta: EconomyEarn.fokusProgressPercent,
          );
      AppScope.of(context).analytics.focusComplete(durationMinutes: widget.duration.inMinutes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.home;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([scope.auth, scope.streak]),
          builder: (context, _) {
            final profile = scope.auth.profile;
            final userName = profile?.displayName ?? '';
            final monsterId = (profile != null && profile.dominantSaboteurs.isNotEmpty) ? profile.dominantSaboteurs.first : 'waswas';
            return Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
              child: Column(
                children: [
                  Expanded(
                    child: RiungBleedListView(
                      children: [
                        _Celebration(monsterId: monsterId),
                        const SizedBox(height: AppSpacing.md),
                        Text(t.fullMinutes(widget.duration.inMinutes, userName), style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                        const SizedBox(height: AppSpacing.md),
                        Text(t.sessionRest, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                        const SizedBox(height: AppSpacing.lg),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: RiungValueChip(leading: const RiungIcon3D(RiungIcon.streak, size: 30), value: '${scope.streak.current}', label: t.streakDays),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RiungValueChip(
                                  leading: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 30, applyBossScale: false),
                                  value: '+${EconomyEarn.fokusProgressPercent}%',
                                  label: context.s.common.monsterName(monsterId),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RiungButton(label: t.viewPlayerCard, onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KartuPemainScreen()))),
                  const SizedBox(height: 10),
                  RiungButton(label: t.backToHome, variant: RiungButtonVariant.secondary, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Monster jinak dengan aura & kilau emas (frame `Perayaan`).
class _Celebration extends StatelessWidget {
  const _Celebration({required this.monsterId});

  final String monsterId;

  @override
  Widget build(BuildContext context) {
    Widget spark(double l, double tp, double size) => Positioned(left: l, top: tp, child: Icon(Icons.auto_awesome, size: size, color: AppColors.emas));
    return Center(
      child: SizedBox(
        width: 300,
        height: 260,
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 0,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
              ),
            ),
            Positioned(left: 50, top: 30, child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 200, applyBossScale: false)),
            spark(30, 40, 22),
            spark(250, 30, 16),
            spark(270, 170, 20),
            spark(20, 190, 14),
          ],
        ),
      ),
    );
  }
}
