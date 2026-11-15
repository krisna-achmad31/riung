import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Route ke layar malam (Tidur): layar asal perlahan meredup ke
/// [AppNight.latarBawah], lalu layar malam muncul. Kembali = kebalikannya.
class DimToNightRoute<T> extends PageRouteBuilder<T> {
  DimToNightRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 900),
          reverseTransitionDuration: const Duration(milliseconds: 600),
          opaque: false,
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            final dim = CurvedAnimation(parent: animation, curve: const Interval(0, 0.55, curve: Curves.easeInOut));
            final show = CurvedAnimation(parent: animation, curve: const Interval(0.45, 1, curve: Curves.easeOut));
            return Stack(
              fit: StackFit.expand,
              children: [
                FadeTransition(opacity: dim, child: const ColoredBox(color: AppNight.latarBawah)),
                FadeTransition(opacity: show, child: child),
              ],
            );
          },
        );
}
