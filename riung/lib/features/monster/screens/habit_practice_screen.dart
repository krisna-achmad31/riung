import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../kenali_dirimu/logic/kenali_feature_route.dart';
import '../logic/habit_monsters.dart';

/// Satu latihan di peta Monster Kebiasaan: cara melakukannya, pintasan ke
/// fitur terkait, lalu "Sudah kulakukan" (pop `true`) untuk membuka node
/// berikutnya. Tidak memberi koin/progres — progres jinak tetap lewat
/// serangan, dan tidak pernah bisa dibeli.
class HabitPracticeScreen extends StatelessWidget {
  const HabitPracticeScreen({super.key, required this.monsterId, required this.index});

  final String monsterId;
  final int index;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final practice = HabitMonsters.practicesOf(monsterId)[index];
    final feature = practice.feature;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(title: t.stageTitle(s.common.monsterName(monsterId))),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
                  children: [
                    Center(child: RiungIcon3D(practice.icon, size: 96)),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      s.monster.stageLevelLabel(index + 1).toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup),
                    ),
                    const SizedBox(height: 4),
                    Text(t.practiceTitle(monsterId, index), textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                    const SizedBox(height: AppSpacing.lg),
                    RiungGlassCard(
                      radius: 24,
                      padding: const EdgeInsets.all(18),
                      child: Text(t.practiceHowTo(monsterId, index), style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.55, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
                    ),
                    if (feature != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      RiungButton(label: t.openFeature(feature), variant: RiungButtonVariant.secondary, onPressed: () => openKenaliFeature(context, feature)),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    RiungOwlTip(message: t.practiceNote),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: RiungButton(label: t.practiceDoneButton, onPressed: () => Navigator.of(context).pop(true))),
            ],
          ),
        ),
      ),
    );
  }
}
