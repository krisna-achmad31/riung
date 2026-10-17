import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'riung_icon_3d.dart';

/// Lencana Pro (komponen `Lencana Pro` di papan `Glass — Komponen · Lencana
/// Pro`, `design/riung.pen`): pil lavender lembut, ikon premium 3D + "PRO".
/// Hanya ditampilkan untuk pelanggan Premium yang aktif; bukan tombol.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.s.toko.premiumTitle,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
        decoration: BoxDecoration(color: AppColors.sekunderLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RiungIcon3D(RiungIcon.premium, size: 16),
            const SizedBox(width: 4),
            Text(
              context.s.common.proBadge,
              style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.sekunderTerang),
            ),
          ],
        ),
      ),
    );
  }
}
