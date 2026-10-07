import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Ilustrasi perayaan satu aset (frame `Perayaan` di layar sukses Toko):
/// aura putih lembut, aset 3D di tengah, empat kilau emas.
class RiungSparkleHero extends StatelessWidget {
  const RiungSparkleHero({super.key, required this.child});

  /// Aset 3D (mis. `RiungIcon3D(RiungIcon.fokus, size: 170)`).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
            ),
            child,
            const Positioned(left: 20, top: 40, child: Icon(Icons.auto_awesome, size: 22, color: AppColors.emas)),
            const Positioned(right: 22, top: 40, child: Icon(Icons.auto_awesome, size: 18, color: AppColors.emas)),
            const Positioned(right: 10, bottom: 40, child: Icon(Icons.auto_awesome, size: 20, color: AppColors.emas)),
            const Positioned(left: 16, bottom: 36, child: Icon(Icons.auto_awesome, size: 14, color: AppColors.emas)),
          ],
        ),
      ),
    );
  }
}
