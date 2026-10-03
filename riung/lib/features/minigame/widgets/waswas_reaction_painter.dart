import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../logic/waswas_reaction_engine.dart';

/// Menggambar gelembung "pikiran terburuk" naik dari bawah, dan garis batas
/// atas (kalau gelembung menyentuhnya, lolos jadi "mengakar").
class WaswasReactionPainter extends CustomPainter {
  WaswasReactionPainter({
    required this.engine,
    required this.labels,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final WaswasReactionEngine engine;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / WaswasReactionEngine.width;
    canvas.save();
    canvas.scale(scale);

    _paintTopLine(canvas);
    for (final b in engine.bubbles) {
      _paintBubble(canvas, b);
    }

    canvas.restore();
  }

  void _paintTopLine(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.error.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, WaswasReactionEngine.topLine),
      Offset(WaswasReactionEngine.width, WaswasReactionEngine.topLine),
      paint,
    );
  }

  void _paintBubble(Canvas canvas, WorryBubble b) {
    final center = Offset(b.x, b.y);
    const r = 34.0;
    final glow = Paint()..color = AppColors.monsterWaswas.withValues(alpha: 0.16);
    canvas.drawCircle(center, r + 8, glow);
    final fill = Paint()..color = AppColors.permukaan;
    final stroke = Paint()
      ..color = AppColors.monsterWaswas
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, r, fill);
    canvas.drawCircle(center, r, stroke);

    final label = labels[b.labelIndex % labels.length];
    final tp = TextPainter(
      text: TextSpan(text: label, style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.teksUtama, height: 1.2)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: r * 1.7);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant WaswasReactionPainter oldDelegate) => true;
}
