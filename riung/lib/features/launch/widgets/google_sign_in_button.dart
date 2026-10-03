import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';

/// Tombol "Lanjutkan dengan Google" — tersambung ke Google Sign-In asli
/// sejak M5 lewat `FirebaseAuthService`. `onPressed` null = nonaktif
/// (dipakai saat proses lain sedang berjalan).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.garis, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text(
                'G',
                style: TextStyle(color: AppColors.latar, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              context.s.launch.continueWithGoogle,
              style: AppTextStyles.subtitle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.teksUtama,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
