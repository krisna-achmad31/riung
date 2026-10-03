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
                    SizedBox(width: 128, height: 135, child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.liar, size: 128)),
                    const SizedBox(height: AppSpacing.md),
                    Text(judul, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 21)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(subjudul, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.55)),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RewardStat(icon: Icons.monetization_on, value: '+${EconomyEarn.jurnal}', label: t.coins, color: AppColors.aksenHangat),
                        const SizedBox(width: AppSpacing.sm),
                        if (prompt != null) ...[
                          _RewardStat(icon: Icons.pest_control, value: '+2%', label: context.s.common.monsterName(prompt!.monsterId), color: AppColors.sekunder),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(14),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, size: 17, color: AppColors.sukses),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              t.savedNote,
                              style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: RiungButton(label: t.backToJournal, onPressed: () => Navigator.of(context).pop(true)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardStat extends StatelessWidget {
  const _RewardStat({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.chipLabel.copyWith(fontSize: 16, color: color)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
