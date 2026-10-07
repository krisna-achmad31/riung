import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/betterme_content.dart';
import 'sesi_content_screen.dart';

/// Detail satu sesi sebelum dibuka: judul, tipe, estimasi durasi.
class SesiDetailScreen extends StatelessWidget {
  const SesiDetailScreen({super.key, required this.session});

  final BetterMeSession session;

  @override
  Widget build(BuildContext context) {
    final t = context.s.betterme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(title: t.levelName(session.level)),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                  children: [
                    SizedBox(
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                          ),
                          const RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 190, applyBossScale: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.aksenHangatLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(t.typeLabel(session.tipe.name).toUpperCase(), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.aksenHangatGelap)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.session(session.id).judul, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _MetaChip(icon: Icons.timer_outlined, label: t.minutesLong(session.estimasiMenit)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RiungButton(
                label: t.start,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SesiContentScreen(session: session))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: AppColors.teksSekunder), const SizedBox(width: 6)],
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksUtama)),
        ],
      ),
    );
  }
}
