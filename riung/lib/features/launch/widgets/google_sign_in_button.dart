import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/widgets.dart';

/// Tombol "Lanjutkan dengan Google" — tersambung ke Google Sign-In asli
/// sejak M5 lewat `FirebaseAuthService`. `onPressed` null = nonaktif
/// (dipakai saat proses lain sedang berjalan).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Tombol kaca sekunder (frame `Google` = Tombol Sekunder) + tanda "G".
    return RiungButton(
      label: context.s.launch.continueWithGoogle,
      variant: RiungButtonVariant.secondary,
      icon: Icons.g_mobiledata_rounded,
      onPressed: onPressed,
    );
  }
}
