import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/services/app_usage_service.dart';
import '../../../core/theme/theme.dart';

/// Tile aplikasi (frame `App …`): kotak berwarna khas aplikasi + ikon putih.
/// Aplikasi pilihan pengguna memakai ikon aslinya begitu termuat.
class AppTile extends StatefulWidget {
  const AppTile({super.key, required this.entry, this.size = 40});

  final AppBekuCatalogEntry? entry;
  final double size;

  @override
  State<AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<AppTile> {
  static final _icons = <String, Uint8List?>{};

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(AppTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry?.packageName != widget.entry?.packageName) _loadIcon();
  }

  Future<void> _loadIcon() async {
    final e = widget.entry;
    if (e == null || !e.isCustom || _icons.containsKey(e.packageName)) return;
    _icons[e.packageName] = await AppUsageService().getAppIcon(e.packageName);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final size = widget.size;
    final icon = e == null ? null : _icons[e.packageName];
    if (icon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: Image.memory(icon, width: size, height: size, gaplessPlayback: true),
      );
    }
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
