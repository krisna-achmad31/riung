import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';

/// Ringkasan kebijakan privasi dalam bahasa manusia, konsisten dengan
/// pesan yang sama di seluruh app (jurnal terenkripsi lokal, data
/// pribadi tidak pernah ke server kecuali profil/wallet/progres monster,
/// halaman krisis tidak dilog). Tidak ada mockup terpisah di desain.
class KebijakanPrivasiScreen extends StatelessWidget {
  const KebijakanPrivasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
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
                  Text(t.privacyPolicy, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bagian(judul: t.privacyJournalTitle, isi: t.privacyJournalBody),
                    _Bagian(judul: t.privacySyncTitle, isi: t.privacySyncBody),
                    _Bagian(judul: t.privacyCrisisTitle, isi: t.privacyCrisisBody),
                    _Bagian(judul: t.privacyFrozenTitle, isi: t.privacyFrozenBody),
                    _Bagian(judul: t.privacyDataTitle, isi: t.privacyDataBody),
                    _Bagian(judul: t.privacyDeleteTitle, isi: t.privacyDeleteBody),
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

class _Bagian extends StatelessWidget {
  const _Bagian({required this.judul, required this.isi});
  final String judul;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.xs),
          Text(isi, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}
