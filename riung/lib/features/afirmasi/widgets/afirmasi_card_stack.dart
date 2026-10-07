import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';

/// Tumpukan kartu afirmasi (frame `Tumpukan kartu`): kartu depan diseret
/// jari ke kiri/kanan, terlempar keluar kalau cukup jauh/cepat, lalu kartu
/// di belakangnya naik ke depan. Kartu ke-n kembali ke kartu pertama.
///
/// Kartu berikutnya sudah dirender di posisi "belakang" (miring, tertutup
/// lapisan lavender) dan pelan-pelan tegak saat kartu depan diseret, jadi
/// pergantian kartu mulus tanpa lompatan.
class AfirmasiCardStack extends StatefulWidget {
  const AfirmasiCardStack({
    super.key,
    required this.itemCount,
    required this.index,
    required this.cardBuilder,
    required this.onSwiped,
    required this.colorOf,
  });

  final int itemCount;
  final int index;
  final Widget Function(BuildContext context, int index) cardBuilder;
  final ValueChanged<int> onSwiped;

  /// Warna polos kartu ke-i — dipakai kartu belakang & tirai kartu
  /// berikutnya, jadi warna yang terlihat di belakang = warna kartu itu.
  final Color Function(int index) colorOf;

  @override
  State<AfirmasiCardStack> createState() => _AfirmasiCardStackState();
}

class _AfirmasiCardStackState extends State<AfirmasiCardStack> with SingleTickerProviderStateMixin {
  // Pose kartu belakang (sama dengan tumpukan statis sebelumnya).
  static const _backAngle = -0.06;
  static const _backOffset = Offset(-14, 22);
  static const _back2Angle = 0.05;
  static const _back2Offset = Offset(14, -18);

  late final AnimationController _controller = AnimationController(vsync: this)..addListener(_tick);
  Animation<Offset>? _flight;
  Offset _drag = Offset.zero;
  double _width = 360;
  bool _flyingOut = false;

  bool get _canSwipe => widget.itemCount > 1;

  void _tick() {
    final flight = _flight;
    if (flight != null) setState(() => _drag = flight.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (!_canSwipe || _flyingOut) return;
    _controller.stop();
    setState(() => _drag += Offset(d.delta.dx, d.delta.dy * 0.25));
  }

  void _onEnd(DragEndDetails d) {
    if (!_canSwipe || _flyingOut) return;
    final vx = d.velocity.pixelsPerSecond.dx;
    final jauh = _drag.dx.abs() > _width * 0.28;
    final cepat = vx.abs() > 700 && vx.sign == _drag.dx.sign;
    if (jauh || cepat) {
      _flyOut(_drag.dx == 0 ? vx.sign : _drag.dx.sign);
    } else {
      _animateTo(Offset.zero, const Duration(milliseconds: 320), Curves.easeOutBack);
    }
  }

  Future<void> _flyOut(double sign) async {
    _flyingOut = true;
    HapticFeedback.selectionClick();
    await _animateTo(Offset(sign * _width * 1.3, _drag.dy + 30), const Duration(milliseconds: 240), Curves.easeIn);
    if (!mounted) return;
    widget.onSwiped((widget.index + 1) % widget.itemCount);
    setState(() {
      _flight = null;
      _drag = Offset.zero;
      _flyingOut = false;
    });
  }

  Future<void> _animateTo(Offset target, Duration duration, Curve curve) {
    _flight = Tween(begin: _drag, end: target).animate(CurvedAnimation(parent: _controller, curve: curve));
    _controller.duration = duration;
    return _controller.forward(from: 0).orCancel.catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        // 0 = kartu belakang di posisi diam, 1 = sudah tegak di depan.
        final p = (_drag.dx.abs() / (_width * 0.45)).clamp(0.0, 1.0);
        final n = widget.itemCount;
        final next = (widget.index + 1) % n;
        final afterNext = (widget.index + 2) % n;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _onUpdate,
          onHorizontalDragEnd: _onEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Kartu ke-3: polos, bergeser ke posisi kartu ke-2 saat diseret.
                Positioned.fill(
                  child: _Pose(
                    angle: _back2Angle + (_backAngle - _back2Angle) * p,
                    offset: Offset.lerp(_back2Offset, _backOffset, p)!,
                    child: _PlainCard(color: widget.colorOf(_canSwipe ? afterNext : widget.index), alpha: 0.7 + 0.3 * p),
                  ),
                ),
                if (_canSwipe)
                  _Pose(
                    angle: _backAngle * (1 - p),
                    offset: _backOffset * (1 - p),
                    child: Stack(
                      children: [
                        widget.cardBuilder(context, next),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Opacity(opacity: 1 - p, child: _PlainCard(color: widget.colorOf(next))),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Positioned.fill(child: _Pose(angle: _backAngle, offset: _backOffset, child: _PlainCard(color: widget.colorOf(widget.index)))),
                _Pose(
                  angle: _drag.dx / _width * 0.3,
                  offset: _drag,
                  child: widget.cardBuilder(context, widget.index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pose extends StatelessWidget {
  const _Pose({required this.angle, required this.offset, required this.child});

  final double angle;
  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(angle: angle, child: child),
    );
  }
}

class _PlainCard extends StatelessWidget {
  const _PlainCard({required this.color, this.alpha = 1});

  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
      ),
    );
  }
}
