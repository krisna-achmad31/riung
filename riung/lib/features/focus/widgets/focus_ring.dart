import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Cincin timer fokus (frame `Timer` di `Glass — Mode Fokus` dan
/// `Glass — Home · Timer fokus`): cincin kaca, busur progres gradien
/// sage→biru/lavender, lingkar dalam, monster jinak 3D + angka waktu.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.monsterId,
    required this.time,
    required this.unit,
    required this.progress,
    this.night = false,
  });

  final String monsterId;
  final String time;
  final String unit;

  /// 0–1, panjang busur progres.
  final double progress;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width - 2 * AppSpacing.xl;
    final size = math.min(280.0, w * 0.85);
    final k = size / 280;
    return Center(
      child: SizedBox(
        width: size + 20,
        height: size + 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size + 20,
              height: size + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: night
                      ? [AppColors.kabutSage.withValues(alpha: 0.2), AppColors.kabutSage.withValues(alpha: 0)]
                      : [AppColors.garis, AppColors.garis.withValues(alpha: 0)],
                ),
              ),
            ),
            CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(progress: progress, night: night),
            ),
            Container(
              width: 224 * k,
              height: 224 * k,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: night ? AppNight.kaca : null,
                gradient: night ? null : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.garis, AppColors.permukaan.withValues(alpha: 0.4)]),
                border: Border.all(color: night ? AppNight.tepi : AppColors.garis),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 120 * k, applyBossScale: false),
                Text(time, style: AppTextStyles.display.copyWith(fontSize: 40 * k, height: 1.1, color: night ? AppNight.teks : AppColors.teksUtama)),
                Text(unit, style: AppTextStyles.caption.copyWith(fontSize: 12, color: night ? AppNight.teksSekunder : AppColors.teksSekunder)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.night});

  final double progress;
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = night ? AppNight.pil : AppColors.permukaan.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (progress <= 0) return;
    final sweep = math.pi * 2 * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: night ? const [AppColors.kabutSage, AppNight.aksen] : const [AppColors.kabutSage, AppColors.langit],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.night != night;
}
