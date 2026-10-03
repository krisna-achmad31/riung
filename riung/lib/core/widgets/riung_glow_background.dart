import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Latar radial glow lembut di atas [AppColors.latar] — pola berulang di
/// banyak layar (splash, hasil sesi, info onboarding, dsb). Warna diturunkan
/// dari token lewat alpha, bukan hex literal baru.
class RiungGlowBackground extends StatelessWidget {
  const RiungGlowBackground({
    super.key,
    required this.child,
    this.glowColor = AppColors.primer,
    this.alignment = const Alignment(0, -0.5),
    this.opacity = 0.24,
    this.radius = 0.85,
  });

  final Widget child;
  final Color glowColor;
  final Alignment alignment;
  final double opacity;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: alignment,
          radius: radius,
          colors: [glowColor.withValues(alpha: opacity), AppColors.latar],
        ),
      ),
      child: child,
    );
  }
}
