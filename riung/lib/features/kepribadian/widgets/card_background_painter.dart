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

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    switch (style) {
      case CardStyle.klasik:
        canvas.drawRect(
          rect,
          Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.kartu, AppColors.latar]).createShader(rect),
        );
        canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.34), size.width * 0.55, Paint()..color = tint.withValues(alpha: 0.16));
      case CardStyle.taman:
        canvas.drawRect(
          rect,
          Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.sukses.withValues(alpha: 0.28), AppColors.latar]).createShader(rect),
        );
        final rnd = math.Random(4);
        for (var i = 0; i < 16; i++) {
          final c = Offset(rnd.nextDouble() * size.width, size.height * (0.55 + rnd.nextDouble() * 0.45));
          canvas.drawOval(
            Rect.fromCenter(center: c, width: 26 + rnd.nextDouble() * 26, height: 12 + rnd.nextDouble() * 14),
            Paint()..color = AppColors.sukses.withValues(alpha: 0.12 + rnd.nextDouble() * 0.16),
          );
        }
        for (var i = 0; i < 9; i++) {
          canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.5), 2.2, Paint()..color = AppColors.peringatan.withValues(alpha: 0.55));
        }
      case CardStyle.arkade:
        canvas.drawRect(rect, Paint()..color = AppColors.latar);
        final grid = Paint()
          ..color = AppColors.sekunder.withValues(alpha: 0.12)
          ..strokeWidth = 1;
        for (var x = 0.0; x < size.width; x += 24) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
        }
        for (var y = 0.0; y < size.height; y += 24) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
        }
        final rnd = math.Random(9);
        final colors = [AppColors.sekunder, AppColors.aksenHangat, AppColors.primer, AppColors.error];
        for (var i = 0; i < 22; i++) {
          final gx = (rnd.nextInt((size.width / 24).floor())) * 24.0;
          final gy = (rnd.nextInt((size.height / 24).floor())) * 24.0;
          canvas.drawRect(Rect.fromLTWH(gx + 6, gy + 6, 12, 12), Paint()..color = colors[i % colors.length].withValues(alpha: 0.35));
        }
      case CardStyle.galaksi:
        canvas.drawRect(
          rect,
          Paint()..shader = RadialGradient(center: const Alignment(0, -0.3), radius: 1.1, colors: [AppColors.monsterHakim.withValues(alpha: 0.6), AppColors.latar]).createShader(rect),
        );
        final rnd = math.Random(21);
        for (var i = 0; i < 70; i++) {
          final r = rnd.nextDouble() * 1.8 + 0.4;
          canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), r, Paint()..color = AppColors.teksUtama.withValues(alpha: 0.35 + rnd.nextDouble() * 0.5));
        }
        canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.12), size.width * 0.08, Paint()..color = AppColors.monsterCermin.withValues(alpha: 0.5));
      case CardStyle.aurora:
        canvas.drawRect(rect, Paint()..color = AppColors.latar);
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
            Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [(i.isEven ? AppColors.sekunder : AppColors.monsterHakim).withValues(alpha: 0.32), AppColors.latar.withValues(alpha: 0)]).createShader(rect),
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant CardBackgroundPainter oldDelegate) => oldDelegate.style != style || oldDelegate.tint != tint;
}
