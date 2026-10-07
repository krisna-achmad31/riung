import 'package:flutter/material.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/theme/theme.dart';

/// Tile aplikasi (frame `App …`): kotak berwarna khas aplikasi + ikon putih.
class AppTile extends StatelessWidget {
  const AppTile({super.key, required this.entry, this.size = 40});

  final AppBekuCatalogEntry? entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: e?.tileColors ?? const [AppColors.appX, AppColors.appX]),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(e?.icon ?? Icons.apps_rounded, size: size / 2, color: AppColors.diAtasTinta),
    );
  }
}
