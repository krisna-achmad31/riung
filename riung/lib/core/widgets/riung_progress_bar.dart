import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Bar progres tipis berujung bulat (kartu Kenali Dirimu, spotlight monster,
/// rincian hasil kuis). [value] 0..1.
class RiungProgressBar extends StatelessWidget {
  const RiungProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.colors = const [AppColors.emas, AppColors.aksenHangat],
    this.track = AppColors.permukaan,
  });

  final double value;
  final double height;
  final List<Color> colors;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return Container(
      height: height,
      decoration: BoxDecoration(color: track, borderRadius: radius),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        heightFactor: 1,
        widthFactor: value.clamp(0.0, 1.0),
        child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: radius)),
      ),
    );
  }
}
