import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Monster tidur di atas bantal mini dengan cahaya biru lembut (frame
/// `Si Kabut tidur` di layar Tidur Riung Glass).
class SleepingMonster extends StatelessWidget {
  const SleepingMonster({super.key, required this.monsterId, this.size = 200, this.glow = 260});

  final String monsterId;
  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: glow,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: glow,
            height: glow,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppNight.cahayaKartu, AppNight.cahayaKartu.withValues(alpha: 0)]),
            ),
          ),
          RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: size, cosmetics: const ['bantal_mini'], applyBossScale: false),
        ],
      ),
    );
  }
}
