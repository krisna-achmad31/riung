import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Chip filter pil Riung Glass (frame `Chip …` di `design/riung.pen`):
/// terpilih = primer padat berteks putih, lainnya = kaca bertepi putih.
class RiungFilterChip extends StatelessWidget {
  const RiungFilterChip({super.key, required this.label, required this.selected, required this.onTap, this.selectedColor = AppColors.primer, this.night = false});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  /// Varian malam: kaca tipis, terpilih = pil terang.
  final bool night;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: night ? (selected ? AppNight.teks : AppNight.kaca) : (selected ? selectedColor : AppColors.permukaan.withValues(alpha: 0.6)),
            border: Border.all(color: night ? (selected ? AppNight.teks : AppNight.tepi) : (selected ? selectedColor : AppColors.garis)),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTextStyles.chipLabel.copyWith(
              fontSize: 12,
              height: 1.25,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: night ? (selected ? AppNight.latarAtas : AppNight.teks) : (selected ? AppColors.diAtasTinta : AppColors.teksUtama),
            ),
          ),
        ),
      ),
    );
  }
}
