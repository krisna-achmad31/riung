import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Latar kabut pastel Riung Glass: gradien dasar + dua cahaya lembut
/// (lavender kanan atas, biru kanan bawah) meniru mesh gradient desain.
/// Dipasang otomatis di belakang setiap halaman lewat `AppTheme`
/// (`pageTransitionsTheme`), jadi Scaffold layar cukup transparan.
class RiungGlassBackdrop extends StatelessWidget {
  const RiungGlassBackdrop({super.key, required this.child, this.night = false});

  final Widget child;

  /// Varian malam (alur Tidur): gradien biru-ungu tua, cahaya bulan, bintang,
  /// ikon status bar terang.
  final bool night;

  static const _stars = [(40.0, 90.0, 3.0), (120.0, 60.0, 2.0), (330.0, 150.0, 3.0), (260.0, 40.0, 2.0), (70.0, 200.0, 2.0)];

  @override
  Widget build(BuildContext context) {
    if (night) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.overlayStyle.copyWith(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppNight.backdrop),
          child: Stack(
            children: [
              Positioned(
                right: -110,
                top: -80,
                width: 320,
                height: 320,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AppNight.cahayaBulan, AppNight.cahayaBulan.withValues(alpha: 0)]),
                  ),
                ),
              ),
              for (final (x, y, d) in _stars)
                Positioned(
                  left: x,
                  top: y,
                  child: Container(width: d, height: d, decoration: const BoxDecoration(color: AppNight.bintang, shape: BoxShape.circle)),
                ),
              Positioned.fill(child: child),
            ],
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGlass.backdrop),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.9, -0.75),
            radius: 0.9,
            colors: [AppColors.kabutLavender, AppColors.kabutLavender.withValues(alpha: 0)],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.9, 0.1),
              radius: 0.8,
              colors: [AppColors.kabutSage.withValues(alpha: 0.8), AppColors.kabutSage.withValues(alpha: 0)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
