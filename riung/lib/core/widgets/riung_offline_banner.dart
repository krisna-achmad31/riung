import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';

/// Bungkus seluruh app (dipasang lewat `MaterialApp.builder` di
/// `main.dart`) — pita tipis muncul otomatis di atas layar kalau
/// perangkat offline, hilang sendiri begitu online lagi. Data lokal
/// (jurnal/check-in/progres) tetap jalan penuh saat offline (CLAUDE.md
/// aturan #5) — ini cuma pemberitahuan, bukan blokir.
class RiungOfflineBanner extends StatefulWidget {
  const RiungOfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  State<RiungOfflineBanner> createState() => _RiungOfflineBannerState();
}

class _RiungOfflineBannerState extends State<RiungOfflineBanner> {
  bool _offline = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_apply);
    _sub = Connectivity().onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    if (!mounted) return;
    setState(() => _offline = results.every((r) => r == ConnectivityResult.none));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _offline
              ? Container(
                  width: double.infinity,
                  color: AppColors.peringatan,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: SafeArea(
                    bottom: false,
                    child: Text(
                      context.s.common.offlineBanner,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(color: AppColors.latar, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
