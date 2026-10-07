import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Hero layar auth (frame `Hero` di Masuk/Daftar): aura putih + tiga monster
/// jinak — satu besar di tengah, dua mengapit lebih kecil.
class LaunchHero extends StatelessWidget {
  const LaunchHero({super.key, required this.left, required this.center, required this.right, this.height = 210, this.centerSize = 160, this.sideSize = 110});

  final String left;
  final String center;
  final String right;
  final double height;
  final double centerSize;
  final double sideSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 220,
            height: height - 10,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
          ),
          Positioned(left: 8, bottom: 0, child: RiungMonster(monsterId: left, state: MonsterVisualState.jinak, size: sideSize, applyBossScale: false)),
          Positioned(right: 8, bottom: 4, child: RiungMonster(monsterId: right, state: MonsterVisualState.jinak, size: sideSize, applyBossScale: false)),
          Positioned(top: 0, child: RiungMonster(monsterId: center, state: MonsterVisualState.jinak, size: centerSize, applyBossScale: false)),
        ],
      ),
    );
  }
}
