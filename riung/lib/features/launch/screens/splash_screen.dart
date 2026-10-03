import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../home/screens/root_shell_screen.dart';
import '../../onboarding/screens/onboarding_flow_screen.dart';

/// Layar pembuka — logo fade+scale, lalu auto-navigate: ke Onboarding kalau
/// user belum pernah menyelesaikannya, ke Beranda kalau sudah.
/// Implement persis `design/Launch.dc.html` § Splash.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _gagal = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    setState(() => _gagal = false);
    final auth = AppScope.of(context).auth;
    try {
      // Jalan paralel: animasi 2 detik & pemuatan profil — mana pun lebih
      // lama yang menentukan kapan pindah layar.
      final results = await Future.wait([
        Future.delayed(const Duration(seconds: 2)),
        auth.ensureProfileLoaded(),
      ]);
      if (!mounted) return;
      final profile = results[1];
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              profile.onboardingDone ? const RootShellScreen() : const OnboardingFlowScreen(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _gagal = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.launch;
    return Scaffold(
      body: RiungGlowBackground(
        alignment: const Alignment(0, -0.16),
        opacity: 0.24,
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primer, AppColors.primerGelap],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primer.withValues(alpha: 0.4),
                            blurRadius: 50,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 72,
                        height: 76,
                        child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 72),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Riung', style: AppTextStyles.display),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.tagline,
                      style: AppTextStyles.body.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 26),
                    if (_gagal)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                        child: Column(
                          children: [
                            Text(
                              t.connectFailed,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.error),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            RiungButton(label: context.s.common.cobaLagi, onPressed: _goNext),
                          ],
                        ),
                      )
                    else
                      const _PulsingDots(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) _dot(i * 0.15),
          ],
        );
      },
    );
  }

  Widget _dot(double delay) {
    final t = (_controller.value + delay) % 1.0;
    final opacity = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(2 * math.pi * t));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.5),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: AppColors.primer, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
