import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Varian visual [RiungButton], mengikuti §05 Komponen inti · Tombol
/// di `design/Design System.dc.html`.
enum RiungButtonVariant {
  /// Terisi penuh warna primer — aksi utama ("Mulai sekarang").
  primary,

  /// Garis tepi primer, latar transparan — aksi sekunder ("Nanti saja").
  secondary,

  /// Teks saja tanpa latar/garis — aksi tersier ("Lewati").
  text,
}

/// Tombol standar Riung, tinggi 52dp radius 16.
/// `onPressed == null` otomatis merender gaya nonaktif ("Lanjut (nonaktif)").
class RiungButton extends StatelessWidget {
  const RiungButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = RiungButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final RiungButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;

    Color background;
    Color textColor;
    Border? border;

    if (disabled) {
      background = AppColors.kartu;
      textColor = AppColors.teksRedup;
      border = null;
    } else {
      switch (variant) {
        case RiungButtonVariant.primary:
          background = AppColors.primer;
          textColor = AppColors.latar;
          border = null;
        case RiungButtonVariant.secondary:
          background = Colors.transparent;
          textColor = AppColors.primer;
          border = Border.all(color: AppColors.primer, width: 1.5);
        case RiungButtonVariant.text:
          background = Colors.transparent;
          textColor = AppColors.teksSekunder;
          border = null;
      }
    }

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              decoration: BoxDecoration(
                border: border,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppTextStyles.buttonLabel.copyWith(color: textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
