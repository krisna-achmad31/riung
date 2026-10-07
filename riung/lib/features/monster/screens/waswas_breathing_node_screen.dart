import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

enum _NapasFase { tarik, tahan, hembus }

const _fasePerCycle = 4;
const _totalCycles = 3;

/// Satu node "napas" di peta latihan Si Waswas — versi ringkas & berdiri
/// sendiri dari `AppBekuNapasScreen` (yang terikat ke app yang dibekukan).
/// Selesai 3 putaran 4-4-4 → `pop(true)` supaya peta menandai node ini
/// selesai hari ini. Tidak ada skor; napas selalu gratis (CLAUDE.md aturan #4).
class WaswasBreathingNodeScreen extends StatefulWidget {
  const WaswasBreathingNodeScreen({super.key});

  @override
  State<WaswasBreathingNodeScreen> createState() => _WaswasBreathingNodeScreenState();
}

class _WaswasBreathingNodeScreenState extends State<WaswasBreathingNodeScreen> with SingleTickerProviderStateMixin {
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

  void _selesaiNapas() {
    _selesai = true;
    _ticker?.cancel();
    Navigator.of(context).pop(true);
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
    final faseOffset = switch (_fase) {
      _NapasFase.tarik => 0,
      _NapasFase.tahan => _fasePerCycle,
      _NapasFase.hembus => _fasePerCycle * 2,
    };
    final detikBerlalu = _cycleIndex * (_fasePerCycle * 3) + faseOffset + (_fasePerCycle - _detikFaseTersisa);
    final totalDetikTersisa = (_totalCycles * _fasePerCycle * 3) - detikBerlalu;
    final w = MediaQuery.sizeOf(context).width - 2 * AppSpacing.xl;
    final k = (w / 320).clamp(0.7, 1.0);

    Widget ring(double size, Color fill) => Container(
          width: size * k,
          height: size * k,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fill, border: Border.all(color: AppColors.garis)),
        );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            children: [
              RiungGlassHeader(title: t.breatheHeader(null)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _circleController,
                      builder: (context, child) => Transform.scale(scale: 0.9 + _circleController.value * 0.12, child: child),
                      child: SizedBox(
                        width: 320 * k,
                        height: 320 * k,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ring(320, AppColors.aksenHangatLembut.withValues(alpha: 0.3)),
                            ring(264, AppColors.aksenHangatLembut.withValues(alpha: 0.5)),
                            ring(208, AppColors.permukaan),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 150 * k, applyBossScale: false),
                                Text(_labelFase(t), style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      t.secondsLeft(totalDetikTersisa.clamp(0, _totalCycles * _fasePerCycle * 3)),
                      style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.aksenHangatGelap),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < _totalCycles; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 28,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i <= _cycleIndex ? AppColors.aksenHangat : AppColors.permukaan,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.breatheHint, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
