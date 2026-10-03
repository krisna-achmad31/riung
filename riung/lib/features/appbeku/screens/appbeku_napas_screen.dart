import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'appbeku_post_breathing_screen.dart';

enum _NapasFase { tarik, tahan, hembus }

const _fasePerCycle = 4;
const _totalCycles = 5;

/// Napas terpandu 1 menit (4-4-4, sama seperti mekanik mini-game
/// serangan) sebelum kembali ke aplikasi yang dibekukan. Implement persis
/// alur `design/AppBeku.dc.html` § interstisial "Tarik napas 1 menit dulu"
/// — di sini murni menenangkan, tidak ada skor/serangan.
class AppBekuNapasScreen extends StatefulWidget {
  const AppBekuNapasScreen({super.key, required this.packageName, this.fromLock = false});

  final String packageName;
  final bool fromLock;

  @override
  State<AppBekuNapasScreen> createState() => _AppBekuNapasScreenState();
}

class _AppBekuNapasScreenState extends State<AppBekuNapasScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _circleController;
  Timer? _ticker;
  int _cycleIndex = 0;
  _NapasFase _fase = _NapasFase.tarik;
  int _detikFaseTersisa = _fasePerCycle;
  bool _selesai = false;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(vsync: this, duration: const Duration(seconds: _fasePerCycle));
    _mulaiFase(_NapasFase.tarik);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _mulaiFase(_NapasFase fase) {
    _fase = fase;
    _detikFaseTersisa = _fasePerCycle;
    if (fase == _NapasFase.tarik) {
      _circleController.animateTo(1, duration: const Duration(seconds: _fasePerCycle), curve: Curves.easeInOut);
    } else if (fase == _NapasFase.hembus) {
      _circleController.animateTo(0, duration: const Duration(seconds: _fasePerCycle), curve: Curves.easeInOut);
    }
  }

  void _tick() {
    if (_selesai || !mounted) return;
    setState(() {
      _detikFaseTersisa -= 1;
      if (_detikFaseTersisa <= 0) _lanjutFase();
    });
  }

  void _lanjutFase() {
    switch (_fase) {
      case _NapasFase.tarik:
        _mulaiFase(_NapasFase.tahan);
      case _NapasFase.tahan:
        _mulaiFase(_NapasFase.hembus);
      case _NapasFase.hembus:
        _cycleIndex += 1;
        if (_cycleIndex >= _totalCycles) {
          _selesaiNapas();
        } else {
          _mulaiFase(_NapasFase.tarik);
        }
    }
  }

  Future<void> _selesaiNapas() async {
    _selesai = true;
    _ticker?.cancel();
    await AppScope.of(context).appBeku.recordBreath();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => AppBekuPostBreathingScreen(packageName: widget.packageName, fromLock: widget.fromLock)),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _circleController.dispose();
    super.dispose();
  }

  String _labelFase(AppbekuStrings t) => switch (_fase) {
        _NapasFase.tarik => t.breathIn,
        _NapasFase.tahan => t.breathHold,
        _NapasFase.hembus => t.breathOut,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.s.appbeku;
    final entry = AppBekuCatalog.byPackage(widget.packageName);
    final faseOffset = switch (_fase) {
      _NapasFase.tarik => 0,
      _NapasFase.tahan => _fasePerCycle,
      _NapasFase.hembus => _fasePerCycle * 2,
    };
    final detikBerlalu = _cycleIndex * (_fasePerCycle * 3) + faseOffset + (_fasePerCycle - _detikFaseTersisa);
    final totalDetikTersisa = (_totalCycles * _fasePerCycle * 3) - detikBerlalu;

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: AppColors.sekunder,
        alignment: const Alignment(0, -0.5),
        opacity: 0.18,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  t.breatheHeader(entry?.name),
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _circleController,
                        builder: (context, child) {
                          final scale = 0.8 + (_circleController.value * 0.35);
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.sekunder.withValues(alpha: 0.16),
                            border: Border.all(color: AppColors.sekunder, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.spa_rounded, size: 48, color: AppColors.sekunder),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(_labelFase(t), style: AppTextStyles.display.copyWith(fontSize: 26)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        t.secondsLeft(totalDetikTersisa.clamp(0, 60)),
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  t.breatheHint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
