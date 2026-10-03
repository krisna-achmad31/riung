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
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
                  ),
                  Text(t.levelName(session.level), style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.sekunder.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(t.typeLabel(session.tipe.name), style: AppTextStyles.caption.copyWith(color: AppColors.sekunder, fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.session(session.id).judul, style: AppTextStyles.display.copyWith(fontSize: 25)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 15, color: AppColors.teksRedup),
                        const SizedBox(width: 6),
                        Text(t.minutesLong(session.estimasiMenit), style: AppTextStyles.caption.copyWith(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
              child: RiungButton(
                label: t.start,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SesiContentScreen(session: session)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
