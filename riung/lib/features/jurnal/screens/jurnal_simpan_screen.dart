import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/journal_prompts.dart';

/// Entri tersimpan — ringkasan reward. Implement persis
/// `design/Jurnal.dc.html` § Jurnal tersimpan.
class JurnalSimpanScreen extends StatelessWidget {
  const JurnalSimpanScreen({super.key, this.prompt});

  final JournalPrompt? prompt;

  @override
  Widget build(BuildContext context) {
    final monsterId = prompt?.monsterId ?? 'kabut';
    final t = context.s.jurnal;
    final judul = prompt != null ? t.savedBossTitle : t.savedTitle;
    final subjudul = prompt != null ? t.savedBossSub : t.savedSub;

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
                      RiungCelebrationHero(monsterId: monsterId, icon: RiungIcon.jurnal),
                      const SizedBox(height: AppSpacing.lg),
                      Text(judul, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
                      const SizedBox(height: AppSpacing.md),
                      Text(subjudul, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: RiungStatTile(leading: const RiungIcon3D(RiungIcon.koin, size: 44), value: '+${EconomyEarn.jurnal}', label: t.coins),
                          ),
                          if (prompt != null) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: RiungStatTile(
                                leading: RiungMonster(monsterId: prompt!.monsterId, state: MonsterVisualState.jinak, size: 44, applyBossScale: false),
                                value: '+2%',
                                label: context.s.common.monsterName(prompt!.monsterId),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.kabutSage.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_rounded, size: 16, color: AppColors.primer),
                            const SizedBox(width: 10),
                            Expanded(child: Text(t.savedNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.primer))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RiungButton(label: t.backToJournal, onPressed: () => Navigator.of(context).pop(true)),
            ],
          ),
        ),
      ),
    );
  }
}
