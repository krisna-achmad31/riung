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
    final stroke = Paint()
      ..color = AppNight.tepi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (final block in engine.blocks) {
      if (!block.alive) continue;
      final rrect = RRect.fromRectAndRadius(block.rect, const Radius.circular(4));
      canvas.drawRRect(rrect, Paint()..color = AppNight.balok[block.labelIndex % AppNight.balok.length]);
      canvas.drawRRect(rrect, stroke);
      final painter = TextPainter(
        text: TextSpan(
          text: labels[block.labelIndex % labels.length].toUpperCase(),
          style: const TextStyle(color: AppNight.teksBalok, fontSize: 4.6, height: 1.05, fontWeight: FontWeight.w700),
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
    const r = BlockBreakerEngine.ballRadius;
    canvas.drawCircle(center, r + 4, Paint()..color = AppNight.aksen.withValues(alpha: 0.25));
    canvas.drawCircle(
      center,
      r,
      Paint()..shader = const RadialGradient(colors: [AppNight.teks, AppNight.aksen]).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  void _paintPaddle(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset(engine.paddleX, engine.paddleY + BlockBreakerEngine.paddleHeight / 2),
      width: BlockBreakerEngine.paddleWidth,
      height: BlockBreakerEngine.paddleHeight,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(BlockBreakerEngine.paddleHeight / 2)), Paint()..color = AppNight.teks);
  }

  @override
  bool shouldRepaint(covariant BlockBreakerPainter oldDelegate) => true;
}
