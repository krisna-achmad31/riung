import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import 'paid_unlock_button.dart';

/// [PaidUnlockButton] dengan jeda wajib [EconomyScroll.unlockCooldownSeconds]
/// sebelum aktif (pengaman etis CLAUDE.md #3: buka-berbayar "jeda 60 dtk")
/// dan pengaman ketuk-ganda: selama [onTap] berjalan tombol nonaktif, jadi
/// koin tidak terpotong dua kali.
class CooldownPaidUnlockButton extends StatefulWidget {
  const CooldownPaidUnlockButton({super.key, required this.label, required this.onTap});

  final String label;
  final Future<void> Function()? onTap;

  @override
  State<CooldownPaidUnlockButton> createState() => _CooldownPaidUnlockButtonState();
}

class _CooldownPaidUnlockButtonState extends State<CooldownPaidUnlockButton> {
  int _cooldown = EconomyScroll.unlockCooldownSeconds;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _cooldown = (_cooldown - 1).clamp(0, EconomyScroll.unlockCooldownSeconds));
      if (_cooldown == 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tap() async {
    final onTap = widget.onTap;
    if (onTap == null || _busy) return;
    setState(() => _busy = true);
    try {
      await onTap();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _cooldown > 0;
    return PaidUnlockButton(
      label: waiting ? context.s.appbeku.waitSeconds(_cooldown) : widget.label,
      onTap: waiting || _busy || widget.onTap == null ? null : _tap,
    );
  }
}
