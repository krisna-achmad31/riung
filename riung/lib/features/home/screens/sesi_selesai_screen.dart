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
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: AppColors.sukses,
        alignment: const Alignment(0, -0.75),
        opacity: 0.16,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([scope.auth, scope.streak]),
            builder: (context, _) {
              final userName = scope.auth.profile?.displayName ?? '';
              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 140,
                            height: 147,
                            child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 140),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            t.fullMinutes(widget.duration.inMinutes, userName),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.display.copyWith(fontSize: 25),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            t.sessionRest,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatBox(
                                icon: Icons.local_fire_department,
                                iconColor: AppColors.aksenHangat,
                                value: '${scope.streak.current}',
                                label: t.streakDays,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _StatBox(
                                icon: Icons.pest_control,
                                iconColor: AppColors.monsterWaswas,
                                value: '+${EconomyEarn.fokusProgressPercent}%',
                                label: context.s.common.monsterName('waswas'),
                                valueColor: AppColors.monsterWaswas,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
                    child: Column(
                      children: [
                        RiungButton(
                          label: t.viewPlayerCard,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const KartuPemainScreen()),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                          child: Text(
                            t.backToHome,
                            style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color? valueColor;

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
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.chipLabel.copyWith(color: valueColor ?? AppColors.teksUtama, fontSize: 16),
          ),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
