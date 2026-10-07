import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Ringkasan kebijakan privasi dalam bahasa manusia, konsisten dengan
/// pesan yang sama di seluruh app (jurnal terenkripsi lokal, data
/// pribadi tidak pernah ke server kecuali profil/hasil kuis/wallet/progres
/// monster setelah login, halaman krisis tidak dilog) dan dengan
/// kebijakan lengkap di [_urlKebijakanLengkap] (`landing/public/privacy.html`).
/// Tidak ada mockup terpisah di desain.
class KebijakanPrivasiScreen extends StatelessWidget {
  const KebijakanPrivasiScreen({super.key});

  static const _urlKebijakanLengkap = 'https://riung-5e979.web.app/privacy';

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.privacyPolicy),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
                  children: [
                    _Bagian(icon: Icons.lock_outline_rounded, judul: t.privacyJournalTitle, isi: t.privacyJournalBody),
                    _Bagian(icon: Icons.cloud_outlined, judul: t.privacySyncTitle, isi: t.privacySyncBody),
                    _Bagian(icon: Icons.support_outlined, judul: t.privacyCrisisTitle, isi: t.privacyCrisisBody),
                    _Bagian(icon: Icons.ac_unit_rounded, judul: t.privacyFrozenTitle, isi: t.privacyFrozenBody),
                    _Bagian(icon: Icons.bar_chart_rounded, judul: t.privacyDataTitle, isi: t.privacyDataBody),
                    _Bagian(icon: Icons.insights_outlined, judul: t.privacyAnalyticsTitle, isi: t.privacyAnalyticsBody),
                    _Bagian(icon: Icons.delete_outline_rounded, judul: t.privacyDeleteTitle, isi: t.privacyDeleteBody),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse(_urlKebijakanLengkap), mode: LaunchMode.externalApplication),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.primer),
                      child: Text(t.privacyFullPolicy, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.primer)),
                    ),
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

/// Satu bagian kebijakan (frame kartu kaca + kotak ikon primer lembut).
class _Bagian extends StatelessWidget {
  const _Bagian({required this.icon, required this.judul, required this.isi});
  final IconData icon;
  final String judul;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RiungGlassCard(
        radius: 22,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RiungMenuRow.iconBox(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                  const SizedBox(height: 4),
                  Text(isi, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
