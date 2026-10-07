import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Bayangan lantai lembut di bawah art 3D (monster & karakter). Art-nya
/// sendiri bebas bayangan supaya kosmetik/aksesori bisa ditumpuk rapi; satu
/// bayangan seragam ini yang menapakkan semuanya ke latar kaca.
///
/// Diletakkan di dalam Stack kanvas persegi art: [floorY] = garis lantai
/// (fraksi tinggi kanvas), [widthFactor] = lebar elips terhadap kanvas.
class RiungGroundShadow extends StatelessWidget {
  const RiungGroundShadow({
    super.key,
    required this.canvasWidth,
    required this.canvasHeight,
    this.floorY = 0.955,
    this.widthFactor = 0.58,
    this.centerX = 0.5,
  });

  final double canvasWidth;
  final double canvasHeight;
  final double floorY;
  final double widthFactor;
  final double centerX;

  @override
  Widget build(BuildContext context) {
    final w = canvasWidth * widthFactor;
    final h = w * 0.16;
    return Positioned(
      left: canvasWidth * centerX - w / 2,
      top: canvasHeight * floorY - h / 2,
      width: w,
      height: h,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AppColors.bayanganLantai,
                AppColors.bayanganLantai.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
