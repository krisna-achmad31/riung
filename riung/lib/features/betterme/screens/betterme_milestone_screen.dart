import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/betterme_content.dart';

/// Perayaan tiap level selesai — konfeti sederhana (lingkaran warna-warni
/// jatuh & berputar via AnimationController, bukan paket eksternal).
class BetterMeMilestoneScreen extends StatefulWidget {
  const BetterMeMilestoneScreen({super.key, required this.level});

  final BetterMeLevel level;

  @override
  State<BetterMeMilestoneScreen> createState() => _BetterMeMilestoneScreenState();
}

class _BetterMeMilestoneScreenState extends State<BetterMeMilestoneScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Confetti> _pieces;

  static const _warna = [AppColors.primer, AppColors.sekunder, AppColors.aksenHangat, AppColors.sukses, AppColors.monsterCermin];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    final rnd = math.Random();
    _pieces = List.generate(28, (i) {
      return _Confetti(
        x: rnd.nextDouble(),
        delay: rnd.nextDouble() * 0.6,
        speed: 0.6 + rnd.nextDouble() * 0.5,
        color: _warna[rnd.nextInt(_warna.length)],
        size: 6 + rnd.nextDouble() * 6,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.betterme;
    final terakhir = widget.level.number == betterMeLevels.length;
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, _controller.value)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primerLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                          child: Text(t.levelDone(widget.level.number), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.primer)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: 240,
                          height: 240,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.emasMuda, AppColors.emasTua]),
                            boxShadow: AppGlass.shadow,
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 192,
                            height: 192,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [AppColors.permukaanPadat, AppColors.emasLembut]),
                            ),
                            alignment: Alignment.center,
                            child: const RiungIcon3D(RiungIcon.streak, size: 120),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(t.level(widget.level.number).judul, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          terakhir ? t.allDone : t.nextLevelOpen(widget.level.number + 1),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(fontSize: 16, height: 1.4, fontWeight: FontWeight.w600, color: AppColors.teksUtama),
                        ),
                      ],
                    ),
                  ),
                  RiungButton(label: context.s.common.lanjut, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Confetti {
  _Confetti({required this.x, required this.delay, required this.speed, required this.color, required this.size});
  final double x;
  final double delay;
  final double speed;
  final Color color;
  final double size;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Confetti> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final progress = ((t + piece.delay) * piece.speed) % 1.0;
      final dy = progress * size.height;
      final dx = piece.x * size.width + math.sin(progress * math.pi * 4) * 14;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()..color = piece.color.withValues(alpha: opacity * 0.85);
      canvas.drawCircle(Offset(dx, dy), piece.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
