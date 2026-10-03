import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/sleep_catalog.dart';

/// Cerita tidur selesai / timer habis — audio & wakelock sudah berhenti,
/// layar ini menutup sesi dengan tenang sebelum kembali.
class TidurSelesaiScreen extends StatelessWidget {
  const TidurSelesaiScreen({super.key, required this.story});

  final SleepStory story;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 116,
                      child: RiungMonster(monsterId: story.targetMonsterId, state: MonsterVisualState.jinak, size: 110),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(context.s.tidur.doneTitle, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 23)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.s.tidur.doneBody,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
              child: RiungButton(label: context.s.common.selesai, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
            ),
          ],
        ),
      ),
    );
  }
}
