import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'riung_pill_chip.dart';

/// Chip jumlah tiket pertarungan — icon & teks warna sekunder.
class TiketChip extends StatelessWidget {
  const TiketChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return RiungPillChip(
      icon: Icons.confirmation_number_rounded,
      label: context.s.common.tickets(count),
      iconColor: AppColors.sekunder,
      textColor: AppColors.sekunder,
    );
  }
}
