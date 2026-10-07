import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Ikon 3D Riung Glass (`assets/icons/<nama>.webp`, dibangun
/// `tools/build_3d_assets.py` dari komponen `Ikon …` di `design/riung.pen`).
enum RiungIcon {
  afirmasi('afirmasi'),
  aplikasiBeku('aplikasi_beku'),
  bantuan('bantuan'),
  beranda('beranda'),
  checkin('checkin'),
  fokus('fokus'),
  jurnal('jurnal'),
  kepribadian('kepribadian'),
  koin('koin'),
  laporan('laporan'),
  meditasi('meditasi'),
  pelindung('pelindung'),
  premium('premium'),
  streak('streak'),
  tidur('tidur'),
  tiket('tiket');

  const RiungIcon(this.file);
  final String file;

  String get asset => 'assets/icons/$file.webp';
}

/// Satu ikon 3D, di-decode seukuran tampil.
class RiungIcon3D extends StatelessWidget {
  const RiungIcon3D(this.icon, {super.key, this.size = 24});

  final RiungIcon icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    return Image.asset(
      icon.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: (size * math.max(dpr, 2.0)).round().clamp(1, 192),
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}
