import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'riung_icon_3d.dart';
import 'riung_pill_chip.dart';

/// Chip jumlah tiket pertarungan — ikon tiket 3D (`TiketChip` Riung Glass).
class TiketChip extends StatelessWidget {
  const TiketChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return RiungPillChip(
      icon3d: RiungIcon.tiket,
      label: context.s.common.tickets(count),
    );
  }
}
