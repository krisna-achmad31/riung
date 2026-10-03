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
    final terakhir = widget.level.number == betterMeLevels.length;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(_pieces, _controller.value),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('✨ 🎉 ✨', style: AppTextStyles.title.copyWith(letterSpacing: 6, fontSize: 22)),
                        const SizedBox(height: AppSpacing.md),
                        const SizedBox(
                          width: 150,
                          height: 158,
                          child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 150, applyBossScale: false),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          context.s.betterme.levelDone(widget.level.number),
                          style: AppTextStyles.caption.copyWith(color: AppColors.aksenHangat, fontWeight: FontWeight.w700, letterSpacing: 1.4, fontSize: 10),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(context.s.betterme.level(widget.level.number).judul, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 24)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          terakhir ? context.s.betterme.allDone : context.s.betterme.nextLevelOpen(widget.level.number + 1),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.55),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
                  child: RiungButton(
                    label: context.s.common.lanjut,
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ),
              ],
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
