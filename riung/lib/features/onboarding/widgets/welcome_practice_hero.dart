import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Static illustrations share the existing decoded 3D assets. Only the page
/// moves during navigation; there are no ambient tickers or backdrop filters.
class WelcomePracticeHero extends StatelessWidget {
  const WelcomePracticeHero({super.key, required this.page});
  final int page;

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 360,
          height: 380,
          child: Stack(
            children: [
              Positioned(
                left: 40,
                top: 35,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.permukaan.withValues(alpha: 0.2),
                    border: Border.all(
                      color: AppColors.garis,
                      width: AppGlass.edgeWidth,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 80,
                top: page == 1 ? 80 : 40,
                child: RiungMonster(
                  monsterId: page == 1 ? 'waswas' : 'kabut',
                  state: MonsterVisualState.jinak,
                  size: 200,
                  applyBossScale: false,
                ),
              ),
              if (page == 1) ...[
                Positioned(
                  left: 180,
                  top: 34,
                  child: _ThoughtPill(label: t.worryLabel),
                ),
                Positioned(
                  left: 9,
                  top: 277,
                  child: _ThoughtPill(label: t.delayLabel),
                ),
                const Positioned(
                  left: 40,
                  top: 135,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 24,
                    color: AppColors.permukaanPadat,
                  ),
                ),
              ] else
                Positioned(
                  left: 9,
                  right: 9,
                  top: 260,
                  child: Row(
                    children: [
                      Expanded(
                        child: _PracticeTile(
                          icon: RiungIcon.meditasi,
                          label: t.breatheLabel,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _PracticeTile(
                          icon: RiungIcon.jurnal,
                          label: t.writeLabel,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _PracticeTile(
                          icon: RiungIcon.tidur,
                          label: t.restLabel,
                        ),
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

class _ThoughtPill extends StatelessWidget {
  const _ThoughtPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 164,
    height: 48,
    child: RiungGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

class _PracticeTile extends StatelessWidget {
  const _PracticeTile({required this.icon, required this.label});
  final RiungIcon icon;
  final String label;

  @override
  Widget build(BuildContext context) => RiungGlassCard(
    radius: 28,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RiungIcon3D(icon, size: 56),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
      ],
    ),
  );
}
