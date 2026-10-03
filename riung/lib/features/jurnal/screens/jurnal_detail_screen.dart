import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/journal_entry.dart';
import '../../../core/theme/theme.dart';

/// Baca-ulang satu entri jurnal tersimpan. Bukan bagian dari 7 layar
/// `design/Jurnal.dc.html`, tapi diperlukan supaya daftar entri (yang ada
/// di desain) bisa benar-benar dibuka — dibuat minimal, mengikuti gaya
/// § Menulis jurnal versi baca-saja (tanpa tombol edit/hapus).
class JurnalDetailScreen extends StatelessWidget {
  const JurnalDetailScreen({super.key, required this.entry});

  final JournalEntry entry;

  static const _moodEmoji = {'berat': '😞', 'agak_berat': '😕', 'datar': '😟', 'cukup_baik': '🙂', 'senang': '😄'};

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEEE, d MMMM · HH:mm', context.s.dateLocale);
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder)),
                  Text(_moodEmoji[entry.mood] ?? '🙂', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.sm),
                  if (entry.tags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.sekunder), borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(entry.tags.first, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.sekunder)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatter.format(entry.createdAt), style: AppTextStyles.caption.copyWith(fontSize: 12)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(entry.text, style: AppTextStyles.body.copyWith(fontSize: 15, color: AppColors.teksUtama, height: 1.75)),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
