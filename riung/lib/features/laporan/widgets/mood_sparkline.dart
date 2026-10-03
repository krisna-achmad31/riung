import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../logic/report_models.dart';

/// Grafik garis suasana hati per hari (skala 1..5), digambar dengan kanvas
/// tanpa package. Hari tanpa data memutus garis (bukan diisi angka palsu).
class MoodSparkline extends StatelessWidget {
  const MoodSparkline({super.key, required this.days, this.labels = const []});

  final List<ReportDay> days;

  /// Label singkat di bawah tiap titik (kosong = tanpa label, mis. bulanan).
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 84,
          width: double.infinity,
          child: CustomPaint(painter: _SparklinePainter(days)),
        ),
        if (labels.length == days.length) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (final l in labels)
                Expanded(
                  child: Text(l, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.days);

  final List<ReportDay> days;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = AppColors.garis
      ..strokeWidth = 1;
    for (final v in [1.0, 3.0, 5.0]) {
      final y = _y(v, size);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
    }
    final n = days.length;
    double x(int i) => n == 1 ? size.width / 2 : size.width * (i + 0.5) / n;

    final line = Paint()
      ..color = AppColors.primer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    var path = Path();
    var open = false;
    for (var i = 0; i < n; i++) {
      final mood = days[i].mood;
      if (mood == null) {
        if (open) canvas.drawPath(path, line);
        path = Path();
        open = false;
        continue;
      }
      final p = Offset(x(i), _y(mood, size));
      if (open) {
        path.lineTo(p.dx, p.dy);
      } else {
        path.moveTo(p.dx, p.dy);
        open = true;
      }
    }
    if (open) canvas.drawPath(path, line);

    final dot = Paint()..color = AppColors.primer;
    final ring = Paint()..color = AppColors.permukaan;
    final radius = n > 14 ? 2.5 : 4.5;
    for (var i = 0; i < n; i++) {
      final mood = days[i].mood;
      if (mood == null) continue;
      final p = Offset(x(i), _y(mood, size));
      canvas.drawCircle(p, radius + 1.5, ring);
      canvas.drawCircle(p, radius, dot);
    }
  }

  double _y(double mood, Size size) {
    const pad = 8.0;
    return pad + (5 - mood) / 4 * (size.height - 2 * pad);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.days != days;
}
