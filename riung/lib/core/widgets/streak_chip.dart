import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'riung_icon_3d.dart';
import 'riung_pill_chip.dart';

/// Chip streak harian — ikon api 3D (`StreakChip` Riung Glass).
/// `compact: true` (mis. top bar Beranda) hanya menampilkan angka tanpa
/// akhiran "hari".
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days, this.compact = false});

  final int days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RiungPillChip(
      icon3d: RiungIcon.streak,
      label: compact ? '$days' : context.s.common.daysCount(days),
    );
  }
}
