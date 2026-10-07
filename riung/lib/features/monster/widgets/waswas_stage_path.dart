import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Status visual satu node latihan di peta (frame `Node …` di
/// `Glass — Monster · Peta latihan Si Waswas`).
enum StageNodeStatus { done, current, upcoming }

/// Data satu node latihan.
class StageStep {
  const StageStep({
    required this.icon,
    required this.caption,
    required this.title,
    required this.status,
    required this.onTap,
    this.subtitle,
  });

  final RiungIcon icon;
  final String caption;
  final String title;
  final String? subtitle;
  final StageNodeStatus status;
  final VoidCallback onTap;
}

/// Data node bos di ujung jalur.
class StageBoss {
  const StageBoss({
    required this.monsterId,
    required this.caption,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String monsterId;
  final String caption;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

/// Jalur berkelok ala Duolingo: node bulat ber-ikon 3D yang zig-zag,
/// disambung garis kaca putih (bagian yang sudah dilewati berwarna primer),
/// berujung monster bos 3D. Geometri mengikuti frame desain lebar 350
/// dan diskalakan horizontal ke lebar yang tersedia.
class WaswasStagePath extends StatelessWidget {
  const WaswasStagePath({super.key, required this.steps, required this.boss});

  final List<StageStep> steps;
  final StageBoss boss;

  static const double _designWidth = 350;
  static const double _circle = 84;
  static const double _bossCircle = 120;
  static const double _rowGap = 180;
  static const double _bossGap = 188;
  static const double _firstY = 52;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final k = width / _designWidth;
        final centers = [
          for (var i = 0; i < steps.length; i++) Offset((i.isEven ? 250 : 180) * k, _firstY + i * _rowGap),
        ];
        final bossCenter = Offset(175 * k, (centers.isEmpty ? _firstY : centers.last.dy) + _bossGap);
        var doneUntil = -1;
        for (var i = 0; i < steps.length && steps[i].status == StageNodeStatus.done; i++) {
          doneUntil = i;
        }
        final height = bossCenter.dy + _bossCircle / 2 + 6 + 64 + AppSpacing.lg;

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter(points: [...centers, bossCenter], doneUntil: doneUntil, bulge: 80 * k),
                ),
              ),
              for (var i = 0; i < steps.length; i++)
                ..._placeNode(
                  width: width,
                  center: centers[i],
                  circleSize: _circle,
                  circle: _StepCircle(step: steps[i]),
                  label: _NodeLabel(
                    caption: steps[i].caption,
                    title: steps[i].title,
                    subtitle: steps[i].subtitle,
                    captionColor: switch (steps[i].status) {
                      StageNodeStatus.done => AppColors.primer,
                      StageNodeStatus.current => AppColors.aksenHangatGelap,
                      StageNodeStatus.upcoming => AppColors.teksRedup,
                    },
                  ),
                  onTap: steps[i].onTap,
                ),
              ..._placeNode(
                width: width,
                center: bossCenter,
                circleSize: _bossCircle,
                circle: _BossCircle(monsterId: boss.monsterId),
                label: _NodeLabel(
                  caption: boss.caption,
                  title: boss.title,
                  subtitle: boss.subtitle,
                  captionColor: AppColors.aksenHangatGelap,
                ),
                onTap: boss.onTap,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Lingkaran di [center] + label kaca di bawahnya (dipusatkan, dijaga
  /// tidak keluar dari lebar peta).
  List<Widget> _placeNode({
    required double width,
    required Offset center,
    required double circleSize,
    required Widget circle,
    required Widget label,
    required VoidCallback onTap,
  }) {
    const labelMaxWidth = 190.0;
    final labelLeft = (center.dx - labelMaxWidth / 2).clamp(0.0, math.max(0.0, width - labelMaxWidth)).toDouble();
    return [
      Positioned(
        left: center.dx - circleSize / 2,
        top: center.dy - circleSize / 2,
        width: circleSize,
        height: circleSize,
        child: GestureDetector(onTap: onTap, child: circle),
      ),
      Positioned(
        left: labelLeft,
        top: center.dy + circleSize / 2 + 6,
        width: labelMaxWidth,
        child: Align(
          alignment: Alignment(((center.dx - labelLeft) / labelMaxWidth) * 2 - 1, 0),
          child: GestureDetector(onTap: onTap, child: label),
        ),
      ),
    ];
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.step});

  final StageStep step;

  @override
  Widget build(BuildContext context) {
    final (fill, border, borderWidth) = switch (step.status) {
      StageNodeStatus.done => (AppColors.primerLembut, AppColors.primer, 2.0),
      StageNodeStatus.current => (AppColors.garis, AppColors.aksenHangat, 3.0),
      StageNodeStatus.upcoming => (AppColors.kartu, AppColors.garis, 2.0),
    };
    return Semantics(
      button: true,
      label: step.title,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: borderWidth),
          boxShadow: const [BoxShadow(color: AppColors.bayangan, offset: Offset(0, 10), blurRadius: 24)],
        ),
        alignment: Alignment.center,
        child: RiungIcon3D(step.icon, size: 62),
      ),
    );
  }
}

class _BossCircle extends StatelessWidget {
  const _BossCircle({required this.monsterId});

  final String monsterId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [AppColors.garis, AppColors.aksenHangatLembut]),
        border: Border.all(color: AppColors.aksenHangat, width: 2),
        boxShadow: AppGlass.shadow,
      ),
      alignment: Alignment.center,
      child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.liar, size: 104, applyBossScale: false),
    );
  }
}

class _NodeLabel extends StatelessWidget {
  const _NodeLabel({required this.caption, required this.title, required this.captionColor, this.subtitle});

  final String caption;
  final String title;
  final String? subtitle;
  final Color captionColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppGlass.card(radius: 16, color: AppColors.permukaan),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption.toUpperCase(),
            style: AppTextStyles.caption.copyWith(fontSize: 9, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: captionColor),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.chipLabel.copyWith(fontSize: 13, height: 1.25, color: AppColors.teksUtama),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.3, color: AppColors.teksSekunder),
            ),
          ],
        ],
      ),
    );
  }
}

/// Garis jalur: kurva halus antartitik dengan tonjolan bergantian kiri/kanan.
/// Jalur penuh = kaca putih; segmen sampai node selesai terakhir = primer.
class _PathPainter extends CustomPainter {
  _PathPainter({required this.points, required this.doneUntil, required this.bulge});

  final List<Offset> points;
  final int doneUntil;
  final double bulge;

  Path _build(int lastIndex) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < lastIndex; i++) {
      final a = points[i];
      final b = points[i + 1];
      final dy = b.dy - a.dy;
      final side = i.isEven ? -1.0 : 1.0;
      path.cubicTo(a.dx + side * bulge, a.dy + dy * 0.45, b.dx + side * bulge, a.dy + dy * 0.7, b.dx, b.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_build(points.length - 1), stroke(AppColors.garis));
    if (doneUntil >= 0) {
      // Garis primer berhenti di node selesai terakhir (minimal node pertama
      // ke berikutnya bila lebih dari satu selesai).
      final end = math.min(doneUntil + 1, points.length - 1);
      canvas.drawPath(_build(end), stroke(AppColors.primer));
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) =>
      old.doneUntil != doneUntil || old.bulge != bulge || old.points.length != points.length;
}
