import 'package:flutter/widgets.dart';

/// Builds tabs on first visit and keeps their state while hidden.
class RiungTabHost extends StatefulWidget {
  const RiungTabHost({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<RiungTabHost> createState() => _RiungTabHostState();
}

class _RiungTabHostState extends State<RiungTabHost>
    with SingleTickerProviderStateMixin {
  final Set<int> _visited = {};
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final Animation<Offset> _position = Tween(
    begin: const Offset(0, 0.012),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_controller);

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) _controller.value = 1;
  }

  @override
  void didUpdateWidget(RiungTabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      if (_reduceMotion) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
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
    _visited.add(widget.index);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (_visited.contains(i))
            Offstage(
              key: ValueKey(i),
              offstage: i != widget.index,
              child: TickerMode(
                enabled: i == widget.index,
                child: ExcludeFocus(
                  excluding: i != widget.index,
                  child: SlideTransition(
                    position: i == widget.index
                        ? _position
                        : const AlwaysStoppedAnimation(Offset.zero),
                    child: RepaintBoundary(child: widget.children[i]),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
