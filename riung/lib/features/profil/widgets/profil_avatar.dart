import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/avatar_catalog.dart';

/// Lingkaran avatar (frame `Avatar`): gradien lembut, bingkai putih, monster
/// jinak pilihan user di tengah.
class ProfilAvatar extends StatelessWidget {
  const ProfilAvatar({super.key, required this.avatar, this.size = 72});

  final AvatarOption avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: avatar.colors),
        border: Border.all(color: AppColors.diAtasTinta, width: size >= 100 ? 4 : 3),
        boxShadow: AppGlass.shadow,
      ),
      alignment: Alignment.center,
      child: RiungMonster(monsterId: avatar.monsterId, state: MonsterVisualState.jinak, size: size * 0.82, applyBossScale: false),
    );
  }
}
