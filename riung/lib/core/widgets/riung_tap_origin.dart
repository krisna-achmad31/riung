import 'package:flutter/widgets.dart';

/// Mencatat titik sentuh terakhir, supaya halaman baru bisa membesar dari
/// tempat yang disentuh tanpa mengubah tiap pemanggil `Navigator.push`.
class RiungTapOrigin extends StatelessWidget {
  const RiungTapOrigin({super.key, required this.child});

  static const _maxAge = Duration(milliseconds: 800);

  static Offset? _position;
  static DateTime? _time;

  final Widget child;

  /// Titik sentuh yang baru saja terjadi; null untuk navigasi otomatis.
  static Offset? get recent {
    final time = _time;
    if (time == null || DateTime.now().difference(time) > _maxAge) return null;
    return _position;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _position = event.position;
        _time = DateTime.now();
      },
      child: child,
    );
  }
}
