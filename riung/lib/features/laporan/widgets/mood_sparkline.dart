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
          height: 120,
          width: double.infinity,
          child: CustomPaint(painter: _SparklinePainter(days)),
        ),
        if (labels.length == days.length) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (final l in labels)
                Expanded(
                  child: Text(l, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Batang suasana hati (frame `Batang` di `Glass — Laporan`): batang kaca
/// putih per hari, hari terakhir bergradien primer.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.days);

  final List<ReportDay> days;

  @override
  void paint(Canvas canvas, Size size) {
    final n = days.length;
    if (n == 0) return;
    final slot = size.width / n;
    final barW = (slot * 0.72).clamp(3.0, 38.0);
    final radius = Radius.circular((barW / 3).clamp(2.0, 12.0));
    final edge = Paint()
      ..color = AppColors.garis
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < n; i++) {
      final mood = days[i].mood;
      final h = mood == null ? 6.0 : 10 + (mood - 1) / 4 * (size.height - 10);
      final rect = Rect.fromLTWH(slot * i + (slot - barW) / 2, size.height - h, barW, h);
      final rrect = RRect.fromRectAndRadius(rect, radius);
      final last = i == n - 1 && mood != null;
      canvas.drawRRect(
        rrect,
        last
            ? (Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.kabutSage, AppColors.primer]).createShader(rect))
            : (Paint()..color = mood == null ? AppColors.permukaan.withValues(alpha: 0.4) : AppColors.permukaan),
      );
      canvas.drawRRect(rrect, edge);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.days != days;
}
