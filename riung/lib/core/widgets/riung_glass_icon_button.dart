import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Tombol ikon bulat kaca kuat 44dp (dipakai header & aksi sekunder).
class RiungGlassIconButton extends StatelessWidget {
  const RiungGlassIconButton({super.key, required this.icon, required this.onTap, this.semanticLabel, this.night = false});

  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  /// Varian malam (alur Tidur): kaca putih tipis, ikon terang.
  final bool night;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: night ? AppNight.card(radius: 22, color: AppNight.pil) : AppGlass.pill(),
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: night ? AppNight.teks : AppColors.teksUtama),
        ),
      ),
    );
  }
}
