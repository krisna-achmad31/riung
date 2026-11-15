import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../screens/bantuan_krisis_screen.dart';

/// Tautan kecil ke [BantuanKrisisScreen] untuk layar di luar tab Profil
/// (hasil check-in, simpan jurnal) — CLAUDE.md #4: layar krisis selalu bisa
/// diakses. Tidak dilog.
class BantuanKrisisLink extends StatelessWidget {
  const BantuanKrisisLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BantuanKrisisScreen())),
      icon: const Icon(Icons.favorite_border_rounded, size: 16, color: AppColors.aksenHangatGelap),
      label: Text(
        context.s.profil.crisisTitle,
        style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.aksenHangatGelap),
      ),
    );
  }
}
