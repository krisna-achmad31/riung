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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            children: [
              Text(t.breatheHeader(entry?.name), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.teksSekunder)),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 320,
                        height: 320,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _circleController,
                              builder: (context, _) {
                                final v = _circleController.value;
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _Ring(size: 260 + 60 * v, color: AppColors.langitLembut.withValues(alpha: 0.3)),
                                    _Ring(size: 214 + 50 * v, color: AppColors.langitLembut.withValues(alpha: 0.5)),
                                    _Ring(size: 170 + 38 * v, color: AppColors.permukaan),
                                  ],
                                );
                              },
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 150, applyBossScale: false),
                                Text(_labelFase(t), style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(t.secondsLeft(totalDetikTersisa.clamp(0, 60)), style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.langit)),
                      const SizedBox(height: AppSpacing.md),
                      Text(t.breatheHint, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gelombang napas (frame `Gelombang`): lingkaran kaca tipis.
class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: AppColors.garis)),
    );
  }
}
