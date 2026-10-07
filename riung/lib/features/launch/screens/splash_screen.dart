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
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SplashLogo(),
                  const SizedBox(height: AppSpacing.md),
                  Text('Riung', style: AppTextStyles.display.copyWith(fontSize: 52, height: 1.2)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(t.tagline, style: AppTextStyles.body.copyWith(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  const SizedBox(height: 26),
                  if (_gagal)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Column(
                        children: [
                          Text(t.connectFailed, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.aksenHangatGelap)),
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
    );
  }
}

/// Logo splash (frame `Logo`): halo tipis, orb kaca, Si Kabut di tengah dan
/// empat monster kecil mengorbit.
class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        children: [
          Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.permukaan, width: AppGlass.edgeWidth))),
          Positioned(
            left: 50,
            top: 50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.permukaanPadat, AppColors.permukaan.withValues(alpha: 0.4)]),
                border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                boxShadow: AppGlass.shadow,
              ),
            ),
          ),
          const Positioned(left: 75, top: 62, child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 150, applyBossScale: false)),
          const Positioned(left: 4, top: 30, child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 64, applyBossScale: false)),
          const Positioned(left: 236, top: 40, child: RiungMonster(monsterId: 'cermin', state: MonsterVisualState.jinak, size: 58, applyBossScale: false)),
          const Positioned(left: 10, top: 214, child: RiungMonster(monsterId: 'meronta', state: MonsterVisualState.jinak, size: 58, applyBossScale: false)),
          const Positioned(left: 232, top: 206, child: RiungMonster(monsterId: 'mengelak', state: MonsterVisualState.jinak, size: 62, applyBossScale: false)),
        ],
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
