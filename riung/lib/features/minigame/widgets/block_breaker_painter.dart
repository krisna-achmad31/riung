import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../logic/block_breaker_engine.dart';

/// Menggambar balok, bola, dan papan pada [BlockBreakerEngine]. Bos
/// digambar sebagai widget terpisah (RiungMonster) di atas kanvas ini.
class BlockBreakerPainter extends CustomPainter {
  BlockBreakerPainter({
    required this.engine,
    required this.blockColor,
    required this.labels,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final BlockBreakerEngine engine;
  final Color blockColor;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / BlockBreakerEngine.width;
    canvas.save();
    canvas.scale(scale);

    _paintBlocks(canvas);
    _paintBall(canvas);
    _paintPaddle(canvas);

    canvas.restore();
  }

  void _paintBlocks(Canvas canvas) {
    final fill = Paint()..color = blockColor.withValues(alpha: 0.18);
    final stroke = Paint()
      ..color = blockColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final block in engine.blocks) {
      if (!block.alive) continue;
      final rrect = RRect.fromRectAndRadius(block.rect, const Radius.circular(5));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, stroke);
      final painter = TextPainter(
        text: TextSpan(
          text: labels[block.labelIndex % labels.length],
          style: TextStyle(color: blockColor, fontSize: 5, height: 1.05, fontWeight: FontWeight.w700),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: block.rect.width - 3);
      painter.paint(canvas, Offset(block.rect.center.dx - painter.width / 2, block.rect.center.dy - painter.height / 2));
    }
  }

  void _paintBall(Canvas canvas) {
    final center = engine.ball;
    canvas.drawCircle(center, BlockBreakerEngine.ballRadius + 5, Paint()..color = AppColors.sekunder.withValues(alpha: 0.18));
    canvas.drawCircle(center, BlockBreakerEngine.ballRadius, Paint()..color = AppColors.sekunder);
  }

  void _paintPaddle(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset(engine.paddleX, engine.paddleY + BlockBreakerEngine.paddleHeight / 2),
      width: BlockBreakerEngine.paddleWidth,
      height: BlockBreakerEngine.paddleHeight,
    );
    final paint = Paint()
      ..shader = const LinearGradient(colors: [AppColors.primer, AppColors.sekunder]).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);
  }

  @override
  bool shouldRepaint(covariant BlockBreakerPainter oldDelegate) => true;
}
