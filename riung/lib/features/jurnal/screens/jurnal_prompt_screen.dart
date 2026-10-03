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
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close, color: AppColors.teksSekunder)),
                  Text(context.s.jurnal.promptScreenTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  GestureDetector(
                    onTap: () => _openEditor(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.aksenHangat.withValues(alpha: 0.15), AppColors.kartu.withValues(alpha: 0.9)]),
                        border: Border.all(color: AppColors.aksenHangat.withValues(alpha: 0.45), width: 1.5),
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.s.jurnal.freeWriteKicker, style: AppTextStyles.caption.copyWith(color: AppColors.aksenHangat, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 10)),
                          const SizedBox(height: 6),
                          Text(context.s.jurnal.freeWriteTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 15)),
                          const SizedBox(height: 6),
                          Text(context.s.jurnal.freeWriteBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(context.s.jurnal.orCbtGuide, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
                  const SizedBox(height: AppSpacing.sm),
                  for (final prompt in journalPrompts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => _openEditor(context, prompt: prompt),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.xxl)),
                          child: Row(
                            children: [
                              SizedBox(width: 42, height: 44, child: RiungMonster(monsterId: prompt.monsterId, state: MonsterVisualState.liar, size: 42)),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.s.jurnal.prompt(prompt.id).title, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(context.s.jurnal.prompt(prompt.id).sub, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 18, color: AppColors.teksRedup),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      context.s.jurnal.threeSentences(EconomyEarn.jurnal),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
