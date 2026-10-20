import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';

/// Tautan kecil "Coba lagi" di tengah — mis. saat harga Play gagal dimuat
/// di Paywall Premium & paywall onboarding.
class RiungRetryLink extends StatelessWidget {
  const RiungRetryLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            context.s.common.cobaLagi,
            style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primer),
          ),
        ),
      ),
    );
  }
}
