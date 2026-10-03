import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'riung_pill_chip.dart';

/// Chip streak harian — icon api warna aksen hangat, teks warna utama.
/// `compact: true` (mis. top bar Beranda) hanya menampilkan angka tanpa
/// akhiran "hari".
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days, this.compact = false});

  final int days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RiungPillChip(
      icon: Icons.local_fire_department_rounded,
      label: compact ? '$days' : context.s.common.daysCount(days),
      iconColor: AppColors.aksenHangat,
      textColor: AppColors.teksUtama,
    );
  }
}
