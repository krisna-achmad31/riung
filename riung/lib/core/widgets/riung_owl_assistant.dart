import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Burung hantu kecil — teman/asisten di dalam app (bukan monster, bukan
/// karaktermu sendiri). Munculnya di titik-titik yang butuh sedikit
/// dorongan atau penjelasan, memberi satu kalimat lewat balon chat.
/// Digambar langsung (CustomPainter), bukan aset gambar, seperti monster
/// & karakter kepribadian — supaya gaya visualnya konsisten.
class RiungOwlTip extends StatelessWidget {
  const RiungOwlTip({super.key, required this.message, this.size = 44});

  final String message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: size, height: size, child: CustomPaint(painter: _OwlPainter())),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.permukaan,
              border: Border.all(color: AppColors.garis),
              borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(topLeft: Radius.zero),
            ),
            child: Text(message, style: AppTextStyles.body.copyWith(fontSize: 12.5, height: 1.45)),
          ),
        ),
      ],
    );
  }
}

class _OwlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;
    final cy = s * 0.56;
    final bodyPaint = Paint()..color = AppColors.aksenHangat;
    final darkPaint = Paint()..color = AppColors.teksUtama;
    final lightPaint = Paint()..color = AppColors.latar;

    // Telinga (dua segitiga kecil di atas kepala).
    for (final side in [-1.0, 1.0]) {
      final base = Offset(cx + side * s * 0.24, cy - s * 0.34);
      canvas.drawPath(
        Path()
          ..moveTo(base.dx - s * 0.07, base.dy)
          ..lineTo(base.dx + side * s * 0.04, base.dy - s * 0.16)
          ..lineTo(base.dx + s * 0.07, base.dy)
          ..close(),
        bodyPaint,
      );
    }

    // Badan bulat.
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: s * 0.78, height: s * 0.72), bodyPaint);

    // Wajah bagian dalam (lebih terang) tempat mata.
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - s * 0.02), width: s * 0.58, height: s * 0.5), Paint()..color = AppColors.permukaan);

    // Mata besar bulat, ciri khas burung hantu.
    for (final side in [-1.0, 1.0]) {
      final c = Offset(cx + side * s * 0.15, cy - s * 0.04);
      canvas.drawCircle(c, s * 0.14, lightPaint);
      canvas.drawCircle(c, s * 0.14, Paint()
        ..color = AppColors.garis
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02);
      canvas.drawCircle(c, s * 0.075, darkPaint);
      canvas.drawCircle(c + Offset(-s * 0.02, -s * 0.02), s * 0.02, Paint()..color = AppColors.permukaan);
    }

    // Paruh kecil segitiga.
    canvas.drawPath(
      Path()
        ..moveTo(cx - s * 0.045, cy + s * 0.09)
        ..lineTo(cx + s * 0.045, cy + s * 0.09)
        ..lineTo(cx, cy + s * 0.16)
        ..close(),
      Paint()..color = AppColors.peringatan,
    );

    // Sayap terlipat di sisi badan.
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + side * s * 0.32, cy + s * 0.08), width: s * 0.2, height: s * 0.34),
        Paint()..color = AppColors.aksenHangat.withValues(alpha: 0.75),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OwlPainter oldDelegate) => false;
}
