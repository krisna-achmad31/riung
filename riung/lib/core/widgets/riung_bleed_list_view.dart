import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// ListView yang "menembus" padding horizontal induknya ([bleed] di kiri &
/// kanan) supaya bayangan kartu kaca tidak terpotong lurus di tepi area
/// gulir. Konten tetap sejajar dengan induk karena [bleed] ditambahkan ke
/// padding horizontal list.
///
/// Saat layar pertama kali tampil, beberapa anak teratas masuk berurutan
/// (pudar + naik 16dp, jeda 45ms per anak). Hanya sekali per layar; anak
/// yang dibangun belakangan (digulir) langsung tampil.
class RiungBleedListView extends StatefulWidget {
  const RiungBleedListView({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.bleed = AppSpacing.xl,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double bleed;

  @override
  State<RiungBleedListView> createState() => _RiungBleedListViewState();
}

class _RiungBleedListViewState extends State<RiungBleedListView> with SingleTickerProviderStateMixin {
  static const _animated = 8;
  static const _stagger = 45;
  static const _itemMs = 320;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _itemMs + _stagger * (_animated - 1)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _controller.duration!.inMilliseconds;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth + widget.bleed * 2;
        return OverflowBox(
          minWidth: width,
          maxWidth: width,
          child: ListView(
            padding: widget.padding.copyWith(
              left: widget.padding.left + widget.bleed,
              right: widget.padding.right + widget.bleed,
            ),
            children: [
              for (var i = 0; i < widget.children.length; i++)
                if (i < _animated)
                  _Entrance(
                    animation: CurvedAnimation(
                      parent: _controller,
                      curve: Interval(i * _stagger / total, (i * _stagger + _itemMs) / total, curve: Curves.easeOutCubic),
                    ),
                    child: widget.children[i],
                  )
                else
                  widget.children[i],
            ],
          ),
        );
      },
    );
  }
}

class _Entrance extends StatelessWidget {
  const _Entrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => Transform.translate(offset: Offset(0, 16 * (1 - animation.value)), child: child),
      ),
    );
  }
}
