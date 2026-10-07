import 'package:flutter/material.dart';

import 'riung_icon_3d.dart';
import 'riung_pill_chip.dart';

/// Chip saldo koin — ikon koin 3D (`KoinChip` Riung Glass).
class KoinChip extends StatelessWidget {
  const KoinChip({super.key, required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return RiungPillChip(
      icon3d: RiungIcon.koin,
      label: '$balance',
    );
  }
}
