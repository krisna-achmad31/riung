import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../state/state.dart';
import '../theme/theme.dart';

/// Sheet pilih bahasa. Bahasa berganti seketika begitu satu opsi diketuk
/// (lihat [LanguageNotifier]) — sheet tetap terbuka supaya user langsung
/// melihat hasilnya & bisa balik memilih, lalu ditutup lewat tombol tutup
/// atau ketuk di luar sheet.
Future<void> showBahasaSheet(BuildContext context) {
  final notifier = AppScope.of(context).language;
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => ListenableBuilder(
      listenable: notifier,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: AppColors.garis, borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(context.s.common.languageSheetTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 17)),
            const SizedBox(height: AppSpacing.md),
            for (final language in AppLanguage.values) ...[
              _BahasaOption(
                language: language,
                selected: notifier.language == language,
                onTap: () => notifier.setLanguage(language),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(context.s.common.tutup, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BahasaOption extends StatelessWidget {
  const _BahasaOption({required this.language, required this.selected, required this.onTap});

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? AppColors.primer.withValues(alpha: 0.1) : AppColors.kartu,
          border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Expanded(child: Text(language.nativeName, style: AppTextStyles.chipLabel.copyWith(fontSize: 14))),
            if (selected) const Icon(Icons.check_rounded, size: 18, color: AppColors.primer),
          ],
        ),
      ),
    );
  }
}
