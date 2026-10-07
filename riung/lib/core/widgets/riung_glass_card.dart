import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Kartu kaca (komponen `Kartu Kaca` di `design/riung.pen`): isi putih
/// tembus, tepi putih, bayangan lembut. `blur: true` menambah blur latar
/// asli — pakai hemat (mis. elemen mengambang), mahal di HP RAM 2–4GB.
class RiungGlassCard extends StatelessWidget {
  const RiungGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = 28,
    this.color = AppColors.kartu,
    this.blur = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final bool blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = DecoratedBox(
      decoration: AppGlass.card(radius: radius, color: color, shadowed: !blur),
      child: Padding(padding: padding, child: child),
    );
    if (blur) {
      content = DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: AppGlass.shadow),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: AppGlass.blur / 2, sigmaY: AppGlass.blur / 2),
            child: content,
          ),
        ),
      );
    }
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: content);
  }
}
