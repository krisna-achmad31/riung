import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../logic/avatar_catalog.dart';

/// Lingkaran avatar: potret pilihan user dengan bingkai putih.
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
        border: Border.all(color: AppColors.diAtasTinta, width: size >= 100 ? 4 : 3),
        boxShadow: AppGlass.shadow,
      ),
      child: ClipOval(child: Image.asset(avatar.asset, fit: BoxFit.cover, cacheWidth: (size * 3).round())),
    );
  }
}
