import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Varian visual [RiungButton], mengikuti §05 Komponen inti · Tombol
/// di `design/Design System.dc.html`.
enum RiungButtonVariant {
  /// Pil tinta padat — aksi utama ("Mulai sekarang"), `Tombol Utama`.
  primary,

  /// Pil kaca kuat bertepi putih — aksi sekunder ("Nanti saja"), `Tombol Kaca`.
  secondary,

  /// Teks saja tanpa latar/garis — aksi tersier ("Lewati").
  text,

  /// Pil terang di latar malam (alur Tidur) — aksi utama ("Putar cerita").
  night,
}

/// Tombol standar Riung Glass — pil tinggi 54dp (`Tombol Utama` /
/// `Tombol Kaca` di `design/riung.pen`).
/// `onPressed == null` otomatis merender gaya nonaktif ("Lanjut (nonaktif)").
class RiungButton extends StatelessWidget {
  const RiungButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = RiungButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final RiungButtonVariant variant;

  /// Ikon opsional di kiri label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;

    Color background;
    Color textColor;
    Border? border;
    List<BoxShadow>? shadow;

    if (disabled) {
      background = AppColors.kartu;
      textColor = AppColors.teksRedup;
      border = Border.all(color: AppColors.garis, width: AppGlass.edgeWidth);
    } else {
      switch (variant) {
        case RiungButtonVariant.primary:
          background = AppColors.tinta;
          textColor = AppColors.diAtasTinta;
          shadow = AppGlass.inkShadow;
        case RiungButtonVariant.secondary:
          background = AppColors.permukaan;
          textColor = AppColors.teksUtama;
          border = Border.all(
            color: AppColors.garis,
            width: AppGlass.edgeWidth,
          );
          shadow = AppGlass.shadow;
        case RiungButtonVariant.text:
          background = Colors.transparent;
          textColor = AppColors.teksSekunder;
        case RiungButtonVariant.night:
          background = AppNight.teks;
          textColor = AppNight.latarAtas;
      }
    }
    final radius = BorderRadius.circular(AppRadius.pill);

    return _PressScale(
      enabled: !disabled,
      child: Opacity(
        opacity: disabled ? 0.6 : 1,
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
          child: Material(
            color: background,
            borderRadius: radius,
            child: InkWell(
              onTap: onPressed,
              borderRadius: radius,
              child: Container(
                decoration: BoxDecoration(border: border, borderRadius: radius),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: textColor),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.buttonLabel.copyWith(
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Umpan balik tekan: tombol mengecil ke 97% selama ditekan (120ms).
class _PressScale extends StatefulWidget {
  const _PressScale({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
