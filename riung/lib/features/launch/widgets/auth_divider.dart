import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';

/// Garis pemisah "atau" antara form auth & tombol social login.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, this.label});

  /// Kosong = pakai teks "atau" sesuai bahasa aktif.
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.garis, height: 1, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label ?? context.s.launch.orDivider, style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider(color: AppColors.garis, height: 1, thickness: 1)),
      ],
    );
  }
}
