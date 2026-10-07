import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Judul + keterangan satu bagian hub ("Kuis Besar", "Diri & Relasi", …).
class KenaliSectionHeader extends StatelessWidget {
  const KenaliSectionHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.title.copyWith(fontSize: 18)),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksSekunder)),
      ],
    );
  }
}
