import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/widgets.dart';

/// Tombol "Lanjutkan dengan Apple" — Sign in with Apple lewat
/// `FirebaseAuthService`. Hanya tampil di iOS ([isSupported]) dan selama
/// [appleSignInEnabled] menyala: di Android Apple butuh alur web + Services
/// ID yang belum disiapkan. Gayanya sama
/// dengan [GoogleSignInButton] supaya keduanya setara (App Store 4.8).
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  /// Ikut [defaultTargetPlatform], jadi test bisa menggantinya lewat
  /// `debugDefaultTargetPlatformOverride`.
  static bool get isSupported => appleSignInEnabled && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    return RiungButton(
      label: context.s.launch.continueWithApple,
      variant: RiungButtonVariant.secondary,
      icon: Icons.apple,
      onPressed: onPressed,
    );
  }
}
