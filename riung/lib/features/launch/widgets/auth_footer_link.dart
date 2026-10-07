import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Baris footer "Sudah/Belum punya akun? `<aksi>`" di bawah form auth.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({super.key, required this.text, required this.actionLabel, required this.onTap});

  final String text;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.teksSekunder),
              children: [
                TextSpan(text: '$text '),
                TextSpan(
                  text: actionLabel,
                  style: const TextStyle(color: AppColors.primer, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
