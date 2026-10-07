import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'riung_icon_3d.dart';
import 'riung_monster.dart';

/// Ilustrasi perayaan layar selesai Riung Glass (frame `Perayaan`): aura
/// putih lembut, monster 3D besar, dan ikon 3D fitur di sampingnya.
class RiungCelebrationHero extends StatelessWidget {
  const RiungCelebrationHero({
    super.key,
    required this.monsterId,
    required this.icon,
    this.state = MonsterVisualState.jinak,
    this.iconOnLeft = false,
  });

  final String monsterId;
  final RiungIcon icon;
  final MonsterVisualState state;

  /// Ikon di kiri-bawah (meditasi) atau kanan-bawah (jurnal).
  final bool iconOnLeft;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 240,
        child: Stack(
          children: [
            Positioned(
              left: 30,
              top: 0,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
              ),
            ),
            Positioned(
              left: iconOnLeft ? 90 : 40,
              top: 20,
              child: RiungMonster(monsterId: monsterId, state: state, size: 185, applyBossScale: false),
            ),
            Positioned(
              left: iconOnLeft ? 10 : null,
              right: iconOnLeft ? null : 0,
              top: 100,
              child: RiungIcon3D(icon, size: 130),
            ),
          ],
        ),
      ),
    );
  }
}
