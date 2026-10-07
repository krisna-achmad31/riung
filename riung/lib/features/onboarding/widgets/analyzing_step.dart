import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';

/// Layar "sedang menganalisis" — 3 detik, lalu hitung skor & lanjut ke
/// hasil. Implement persis `design/Onboarding.dc.html` § Menganalisis.
class AnalyzingStep extends StatefulWidget {
  const AnalyzingStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  State<AnalyzingStep> createState() => _AnalyzingStepState();
}

class _AnalyzingStepState extends State<AnalyzingStep> {
  @override
  void initState() {
    super.initState();
    _proceed();
  }

  Future<void> _proceed() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    widget.controller.computeResult();
    final result = widget.controller.result;
    if (result != null) {
      AppScope.of(context).analytics.assessmentResult(
            bossSaboteur: 'hakim',
            dominantSaboteurs: result.dominantSaboteurs,
          );
    }
    widget.controller.next();
  }

  @override
  Widget build(BuildContext context) {
    final nama = widget.controller.nama.trim();
    final t = context.s.onboarding;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, AppSpacing.lg, 24, AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _MonsterOrbit(),
            const SizedBox(height: AppSpacing.lg),
            Align(alignment: Alignment.centerLeft, child: Text(t.analyzingTitle(nama), style: AppTextStyles.display.copyWith(fontSize: 22, height: 1.2))),
            const SizedBox(height: AppSpacing.lg),
            RiungGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _ChecklistRow(text: t.analyzingRead, state: 2),
                  const SizedBox(height: 12),
                  _ChecklistRow(text: t.analyzingMatch, state: 1),
                  const SizedBox(height: 12),
                  _ChecklistRow(text: t.analyzingPlan, state: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animasi (frame `Animasi`): cincin progres gradien berputar, Si Hakim di
/// tengah dikelilingi anak buahnya.
class _MonsterOrbit extends StatelessWidget {
  const _MonsterOrbit();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        children: [
          Container(decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.permukaan.withValues(alpha: 0.6))),
          const Positioned.fill(
            child: CircularProgressIndicator(strokeWidth: 6, color: AppColors.sekunderTerang, backgroundColor: Colors.transparent),
          ),
          Positioned(
            left: 30,
            top: 30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.permukaanPadat, AppColors.permukaan.withValues(alpha: 0.2)]),
                border: Border.all(color: AppColors.garis),
              ),
            ),
          ),
          const Positioned(left: 95, top: 10, child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 70, applyBossScale: false)),
          const Positioned(left: 10, top: 110, child: RiungMonster(monsterId: 'meronta', state: MonsterVisualState.jinak, size: 64, applyBossScale: false)),
          const Positioned(left: 186, top: 104, child: RiungMonster(monsterId: 'cermin', state: MonsterVisualState.jinak, size: 64, applyBossScale: false)),
          const Positioned(left: 60, top: 180, child: RiungMonster(monsterId: 'sempurna', state: MonsterVisualState.jinak, size: 58, applyBossScale: false)),
          const Positioned(left: 148, top: 178, child: RiungMonster(monsterId: 'mengelak', state: MonsterVisualState.jinak, size: 62, applyBossScale: false)),
          const Positioned(left: 82, top: 80, child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 96, applyBossScale: false)),
        ],
      ),
    );
  }
}

/// Langkah analisis: 2 = selesai, 1 = berjalan, 0 = menunggu.
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text, required this.state});

  final String text;
  final int state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state == 2 ? AppColors.primer : (state == 1 ? AppColors.primerLembut : AppColors.permukaan),
            border: Border.all(color: state == 0 ? AppColors.teksRedup : AppColors.primer, width: 1.5),
          ),
          child: state == 2
              ? const Icon(Icons.check_rounded, size: 13, color: AppColors.diAtasTinta)
              : state == 1
                  ? const Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primer))
                  : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              fontWeight: state == 1 ? FontWeight.w700 : FontWeight.w500,
              color: state == 0 ? AppColors.teksRedup : AppColors.teksUtama,
            ),
          ),
        ),
      ],
    );
  }
}
