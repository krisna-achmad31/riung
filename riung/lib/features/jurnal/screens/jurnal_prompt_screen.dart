import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/journal_prompts.dart';
import 'jurnal_editor_screen.dart';

/// Pilih sumber tulisan — tulis bebas atau panduan CBT. Implement persis
/// `design/Jurnal.dc.html` § Pilih prompt jurnal.
class JurnalPromptScreen extends StatelessWidget {
  const JurnalPromptScreen({super.key});

  void _openEditor(BuildContext context, {JournalPrompt? prompt}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => JurnalEditorScreen(prompt: prompt)),
    );
    if (saved == true && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.jurnal;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.dailyLimitTitle),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
                  children: [
                    Text(t.promptScreenTitle, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                    const SizedBox(height: AppSpacing.md),
                    RiungGlassCard(
                      onTap: () => _openEditor(context),
                      color: AppColors.permukaan,
                      radius: 28,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const RiungIcon3D(RiungIcon.jurnal, size: 64),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.freeWriteKicker, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.sekunder)),
                                const SizedBox(height: 3),
                                Text(t.freeWriteTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 16, color: AppColors.teksUtama)),
                                const SizedBox(height: 3),
                                Text(t.freeWriteBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.teksSekunder)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.orCbtGuide, style: AppTextStyles.title.copyWith(fontSize: 16)),
                    const SizedBox(height: AppSpacing.md),
                    for (final prompt in journalPrompts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: RiungGlassCard(
                          onTap: () => _openEditor(context, prompt: prompt),
                          radius: 22,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(color: AppColors.monsterLembut[prompt.monsterId] ?? AppColors.kabutSage, borderRadius: BorderRadius.circular(16)),
                                alignment: Alignment.center,
                                child: RiungMonster(monsterId: prompt.monsterId, state: MonsterVisualState.jinak, size: 48, applyBossScale: false),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.prompt(prompt.id).title, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, height: 1.3, color: AppColors.teksUtama)),
                                    const SizedBox(height: 3),
                                    Text(t.prompt(prompt.id).sub, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.35, color: AppColors.teksSekunder)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.teksRedup),
                            ],
                          ),
                        ),
                      ),
                    Text(t.threeSentences(EconomyEarn.jurnal), textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
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
