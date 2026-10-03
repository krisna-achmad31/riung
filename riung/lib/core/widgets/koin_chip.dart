import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'riung_pill_chip.dart';

/// Chip saldo koin — icon & teks warna aksen hangat.
class KoinChip extends StatelessWidget {
  const KoinChip({super.key, required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return RiungPillChip(
      icon: Icons.monetization_on_rounded,
      label: '$balance',
      iconColor: AppColors.aksenHangat,
      textColor: AppColors.aksenHangat,
    );
  }
}
