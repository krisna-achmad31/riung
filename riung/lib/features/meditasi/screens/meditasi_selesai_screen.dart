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
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: AppColors.sukses,
        alignment: const Alignment(0, -0.75),
        opacity: 0.16,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 132,
                        height: 139,
                        child: RiungMonster(monsterId: session.targetMonsterId, state: MonsterVisualState.jinak, size: 132),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        t.doneTitle(session.defaultDuration),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.3),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.doneBody,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatBox(icon: Icons.monetization_on, iconColor: AppColors.aksenHangat, value: '+${EconomyEarn.meditasi}', label: t.coins),
                          const SizedBox(width: AppSpacing.sm),
                          _StatBox(icon: Icons.pest_control, iconColor: AppColors.monsterWaswas, value: '+3%', label: context.s.common.monsterName(session.targetMonsterId)),
                          const SizedBox(width: AppSpacing.sm),
                          _StatBox(icon: Icons.self_improvement, iconColor: AppColors.sekunder, value: '', label: t.totalSessions),
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
                    RiungButton(label: context.s.common.selesai, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.repeatSession, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
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
  const _StatBox({required this.icon, required this.iconColor, required this.value, required this.label});

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: AppSpacing.xs),
          Text(value.isEmpty ? '-' : value, style: AppTextStyles.chipLabel.copyWith(color: iconColor, fontSize: 14)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}
