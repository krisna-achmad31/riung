import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type scale Riung — di-port dari `design/Design System.dc.html` (§02 · Tipografi).
/// Font: Plus Jakarta Sans (isi) + Bricolage Grotesque (judul, `g-font-display`
/// Riung Glass). Satu-satunya sumber gaya teks untuk seluruh app.
abstract final class AppTextStyles {
  static TextStyle _base({
    required double fontSize,
    required double height,
    required FontWeight weight,
    Color color = AppColors.teksUtama,
    double? letterSpacing,
    bool display = false,
  }) {
    final font = display ? GoogleFonts.bricolageGrotesque : GoogleFonts.plusJakartaSans;
    return font(
      fontSize: fontSize,
      height: height / fontSize,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Display · 32/38 · ExtraBold — judul sambutan besar.
  static TextStyle display = _base(
    fontSize: 32,
    height: 38,
    weight: FontWeight.w700,
    letterSpacing: -0.6,
    display: true,
  );

  /// Title · 22/28 · Bold — judul layar/kartu.
  static TextStyle title = _base(
    fontSize: 22,
    height: 28,
    weight: FontWeight.w700,
    letterSpacing: -0.3,
    display: true,
  );

  /// Subtitle · 17/24 · SemiBold.
  static TextStyle subtitle = _base(
    fontSize: 17,
    height: 24,
    weight: FontWeight.w600,
  );

  /// Body · 15/23 · Regular · teksSekunder.
  static TextStyle body = _base(
    fontSize: 15,
    height: 23,
    weight: FontWeight.w400,
    color: AppColors.teksSekunder,
  );

  /// Caption · 12/16 · Medium · teksRedup.
  static TextStyle caption = _base(
    fontSize: 12,
    height: 16,
    weight: FontWeight.w500,
    color: AppColors.teksRedup,
  );

  /// Label tombol · 16 · Bold — dipakai di RiungButton.
  static TextStyle buttonLabel = _base(
    fontSize: 16,
    height: 20,
    weight: FontWeight.w700,
  );

  /// Label chip/badge kecil · 14 · Bold — dipakai di KoinChip/StreakChip/TiketChip.
  static TextStyle chipLabel = _base(
    fontSize: 14,
    height: 18,
    weight: FontWeight.w700,
  );

  /// Label navigasi bawah · 10 · SemiBold.
  static TextStyle navLabel = _base(
    fontSize: 10,
    height: 13,
    weight: FontWeight.w600,
  );
}
