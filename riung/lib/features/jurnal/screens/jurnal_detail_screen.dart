import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/journal_entry.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/journal_prompts.dart';

/// Baca-ulang satu entri jurnal tersimpan. Bukan bagian dari 7 layar
/// `design/Jurnal.dc.html`, tapi diperlukan supaya daftar entri (yang ada
/// di desain) bisa benar-benar dibuka — dibuat minimal, mengikuti gaya
/// § Menulis jurnal versi baca-saja (tanpa tombol edit/hapus).
class JurnalDetailScreen extends StatelessWidget {
  const JurnalDetailScreen({super.key, required this.entry});

  final JournalEntry entry;

  static const _moodEmoji = {'berat': '😞', 'agak_berat': '😕', 'datar': '😐', 'cukup_baik': '🙂', 'senang': '😄'};

  @override
  Widget build(BuildContext context) {
    final t = context.s.jurnal;
    final dateFmt = DateFormat('EEEE, d MMMM', context.s.dateLocale);
    final timeFmt = DateFormat('HH.mm', context.s.dateLocale);
    final prompt = journalPrompts.where((p) => p.id == entry.promptId).firstOrNull;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
          children: [
            const RiungGlassHeader(title: ''),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: AppGlass.card(radius: 26, color: AppColors.permukaan, shadowed: false),
                  alignment: Alignment.center,
                  child: Text(_moodEmoji[entry.mood] ?? '🙂', style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateFmt.format(entry.createdAt), style: AppTextStyles.title.copyWith(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(
                        prompt == null ? timeFmt.format(entry.createdAt) : '${timeFmt.format(entry.createdAt)} · ${t.prompt(prompt.id).title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            RiungGlassCard(
              radius: 28,
              color: AppColors.permukaan,
              child: Text(entry.text, style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
            ),
            if (prompt != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppGlass.card(radius: 22, color: (AppColors.monsterLembut[prompt.monsterId] ?? AppColors.aksenHangatLembut).withValues(alpha: 0.7), shadowed: false),
                child: Row(
                  children: [
                    RiungMonster(monsterId: prompt.monsterId, state: MonsterVisualState.jinak, size: 48, applyBossScale: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.monsterDetected(context.s.common.monsterName(prompt.monsterId)), style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                          const SizedBox(height: 2),
                          Text(t.monsterMarked(context.s.common.monsterName(prompt.monsterId)), style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.35, color: AppColors.teksSekunder)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 14, color: AppColors.teksRedup),
                const SizedBox(width: 8),
                Text(t.encryptedNote, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksRedup)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
