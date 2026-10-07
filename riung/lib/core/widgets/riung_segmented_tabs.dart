import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Kontrol segmen pil kaca (frame `Tab Jelajah` di `design/riung.pen`):
/// wadah kaca 46dp, segmen aktif = pil tinta berteks putih.
class RiungSegmentedTabs extends StatelessWidget {
  const RiungSegmentedTabs({super.key, required this.labels, required this.index, required this.onChanged, this.night = false});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Varian malam: wadah kaca tipis, segmen aktif terang.
  final bool night;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: night ? AppNight.kaca : AppColors.kartu,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: night ? AppNight.tepi : AppColors.garis, width: AppGlass.edgeWidth),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              // Lebar segmen mengikuti panjang label supaya semua teks tampil
              // di ukuran yang sama (tidak ada label yang mengecil sendiri).
              flex: labels[i].length + 6,
              child: Semantics(
                button: true,
                selected: i == index,
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: i == index ? (night ? AppNight.teks : AppColors.tinta) : AppColors.tinta.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        style: AppTextStyles.chipLabel.copyWith(
                          fontSize: 13,
                          fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                          color: i == index ? (night ? AppNight.latarAtas : AppColors.diAtasTinta) : (night ? AppNight.teksSekunder : AppColors.teksSekunder),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
