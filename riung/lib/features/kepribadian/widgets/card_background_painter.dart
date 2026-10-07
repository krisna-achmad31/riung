import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../logic/card_style.dart';

/// Latar kartu karakter per [CardStyle] — semua dari token tema, digambar
/// dengan kanvas supaya ringan dan tajam saat diekspor jadi gambar.
class CardBackgroundPainter extends CustomPainter {
  CardBackgroundPainter(this.style, this.tint);

  final CardStyle style;

  /// Warna dasar karakter, dipakai untuk menyelaraskan gradiennya.
  final Color tint;

  /// Gradien dasar tiap gaya (preview `Gaya …` di `Glass — Kepribadian · Hasil`).
  static List<Color> gradientOf(CardStyle style) => switch (style) {
        CardStyle.klasik => const [AppColors.kabutLavender, AppColors.langitLembut],
        CardStyle.taman => const [AppColors.kabutSage, AppColors.kabutPersik],
        CardStyle.arkade => const [AppColors.aksenHangatLembut, AppColors.sekunderLembut],
        CardStyle.galaksi => const [AppNight.latarUngu, Color(0xFF5D6A9C)],
        CardStyle.aurora => const [AppColors.primerLembut, AppNight.aksen],
      };

  /// Gaya berlatar gelap (teks kartu jadi terang).
  static bool isDark(CardStyle style) => style == CardStyle.galaksi;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientOf(style)).createShader(rect),
    );
    switch (style) {
      case CardStyle.klasik:
        canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), size.width * 0.36, Paint()..shader = RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.4), radius: size.width * 0.36)));
      case CardStyle.taman:
        final rnd = math.Random(4);
        for (var i = 0; i < 14; i++) {
          final c = Offset(rnd.nextDouble() * size.width, size.height * (0.6 + rnd.nextDouble() * 0.4));
          canvas.drawOval(
            Rect.fromCenter(center: c, width: 26 + rnd.nextDouble() * 26, height: 12 + rnd.nextDouble() * 14),
            Paint()..color = AppColors.primer.withValues(alpha: 0.08 + rnd.nextDouble() * 0.1),
          );
        }
        for (var i = 0; i < 9; i++) {
          canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.5), 2.2, Paint()..color = AppColors.emas.withValues(alpha: 0.7));
        }
      case CardStyle.arkade:
        final grid = Paint()
          ..color = AppColors.garis.withValues(alpha: 0.6)
          ..strokeWidth = 1;
        for (var x = 0.0; x < size.width; x += 24) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
        }
        for (var y = 0.0; y < size.height; y += 24) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
        }
        final rnd = math.Random(9);
        const colors = [AppColors.sekunder, AppColors.aksenHangat, AppColors.primer, AppColors.langit];
        for (var i = 0; i < 22; i++) {
          final gx = (rnd.nextInt((size.width / 24).floor())) * 24.0;
          final gy = (rnd.nextInt((size.height / 24).floor())) * 24.0;
          canvas.drawRect(Rect.fromLTWH(gx + 6, gy + 6, 12, 12), Paint()..color = colors[i % colors.length].withValues(alpha: 0.25));
        }
      case CardStyle.galaksi:
        final rnd = math.Random(21);
        for (var i = 0; i < 70; i++) {
          final r = rnd.nextDouble() * 1.8 + 0.4;
          canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), r, Paint()..color = AppNight.bintang.withValues(alpha: 0.35 + rnd.nextDouble() * 0.5));
        }
        canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.12), size.width * 0.08, Paint()..color = AppNight.aksen.withValues(alpha: 0.5));
      case CardStyle.aurora:
        for (var i = 0; i < 4; i++) {
          final path = Path()..moveTo(0, size.height * (0.15 + i * 0.05));
          for (var x = 0.0; x <= size.width; x += size.width / 8) {
            path.quadraticBezierTo(x + size.width / 16, size.height * (0.06 + i * 0.05) + math.sin(x / 40 + i) * 16, x + size.width / 8, size.height * (0.16 + i * 0.05));
          }
          path.lineTo(size.width, size.height * 0.75);
          path.lineTo(0, size.height * 0.75);
          path.close();
          canvas.drawPath(
            path,
            Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [(i.isEven ? AppColors.garis : AppColors.sekunderLembut).withValues(alpha: 0.5), AppColors.garis.withValues(alpha: 0)]).createShader(rect),
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant CardBackgroundPainter oldDelegate) => oldDelegate.style != style || oldDelegate.tint != tint;
}
