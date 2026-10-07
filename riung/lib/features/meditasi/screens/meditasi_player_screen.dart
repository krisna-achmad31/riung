import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/meditation_catalog.dart';
import 'meditasi_selesai_screen.dart';

/// Pemutar meditasi — audio placeholder (nada lembut, di-loop) lewat
/// `just_audio`; konten audio asli menyusul belakangan (lihat instruksi
/// M3). Diawali layar "Menyiapkan sesimu…" (setara MeditasiEmptyScreen
/// state-loading), lalu pemutar aktif persis `design/Meditasi.dc.html`
/// § Pemutar — sesi berjalan.
class MeditasiPlayerScreen extends StatefulWidget {
  const MeditasiPlayerScreen({super.key, required this.session, required this.durationMinutes});

  final MeditationSession session;
  final int durationMinutes;

  @override
  State<MeditasiPlayerScreen> createState() => _MeditasiPlayerScreenState();
}

class _MeditasiPlayerScreenState extends State<MeditasiPlayerScreen> {
  final _player = AudioPlayer();
  bool _preparing = true;
  double _loadProgress = 0;
  late final Duration _total = Duration(minutes: widget.durationMinutes);
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    for (var i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() => _loadProgress = i / 10);
    }
    try {
      await _player.setAsset(widget.session.ambientAsset);
      await _player.setLoopMode(LoopMode.one);
      unawaited(_player.play());
    } catch (_) {
      // Placeholder audio gagal dimuat (mis. lingkungan tanpa audio) —
      // timer sesi tetap jalan, bukan kegagalan fatal.
    }
    if (!mounted) return;
    setState(() => _preparing = false);
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _elapsed += const Duration(seconds: 1));
    if (_elapsed >= _total && !_finishing) {
      _finishing = true;
      _finish();
    }
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    await _player.stop();
    if (!mounted) return;
    final scope = AppScope.of(context);
    final uid = scope.auth.uid;
    if (uid != null) {
      await scope.wallet.earn(amount: EconomyEarn.meditasi, reason: 'meditasi:${widget.session.id}');
      await scope.wallet.addTickets(1);
      await scope.monsterProgress.tambahProgres(saboteurId: widget.session.targetMonsterId, delta: 3);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MeditasiSelesaiScreen(session: widget.session)),
    );
  }

  void _togglePlayPause() {
    if (_player.playing) {
      _player.pause();
      _ticker?.cancel();
    } else {
      unawaited(_player.play());
      _startTicker();
    }
    setState(() {});
  }

  void _seek(int deltaSeconds) {
    setState(() {
      final next = _elapsed + Duration(seconds: deltaSeconds);
      _elapsed = next < Duration.zero
          ? Duration.zero
          : (next > _total ? _total : next);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_preparing) {
      return _PreparingView(session: widget.session, progress: _loadProgress);
    }

    final remaining = _total - _elapsed;
    final menit = remaining.inMinutes.toString().padLeft(2, '0');
    final detik = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final t = context.s.meditasi;
    final phaseLabel = widget.session.id == 'napas_4_7_8' ? _breathingPhaseLabel(t, _elapsed) : null;
    final elapsedLabel = '${_elapsed.inMinutes.toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            children: [
              RiungGlassHeader(title: t.running),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BreathingRings(monsterId: widget.session.targetMonsterId, label: phaseLabel ?? t.session(widget.session.id).title),
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.followRhythm, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _total.inSeconds == 0 ? 0 : _elapsed.inSeconds / _total.inSeconds,
                  minHeight: 6,
                  backgroundColor: AppColors.permukaan,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primer),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(elapsedLabel, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                  Text('$menit:$detik', style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SeekButton(label: t.seekBack, onTap: () => _seek(-15)),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tinta, boxShadow: AppGlass.inkShadow),
                      child: Icon(_player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30, color: AppColors.diAtasTinta),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _SeekButton(label: t.seekForward, onTap: () => _seek(15)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  static String _breathingPhaseLabel(MeditasiStrings t, Duration elapsed) {
    final phase = elapsed.inSeconds % 19;
    if (phase < 4) return t.breathIn;
    if (phase < 11) return t.breathHold(11 - phase);
    return t.breathOut;
  }
}

/// Tombol lompat ±15 detik: lingkaran kaca 56dp.
class _SeekButton extends StatelessWidget {
  const _SeekButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: AppGlass.card(radius: 28),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teksUtama)),
      ),
    );
  }
}

class _PreparingView extends StatelessWidget {
  const _PreparingView({required this.session, required this.progress});

  final MeditationSession session;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            children: [
              RiungGlassHeader(title: context.s.meditasi.running),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 96,
                            height: 96,
                            child: CircularProgressIndicator(strokeWidth: 4, backgroundColor: AppColors.permukaan, valueColor: const AlwaysStoppedAnimation(AppColors.primer)),
                          ),
                          RiungMonster(monsterId: session.targetMonsterId, state: MonsterVisualState.jinak, size: 60, applyBossScale: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(context.s.meditasi.preparingTitle, style: AppTextStyles.title.copyWith(fontSize: 20)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(context.s.meditasi.preparingBody, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13)),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: AppColors.permukaan, valueColor: const AlwaysStoppedAnimation(AppColors.primer)),
                      ),
                    ),
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

/// Tiga gelombang kaca bernapas (frame `Napas`): lingkaran 320/260/200 sage
/// tembus bertepi putih, monster 3D di tengah, label fase di bawahnya.
class _BreathingRings extends StatefulWidget {
  const _BreathingRings({required this.monsterId, required this.label});

  final String monsterId;
  final String label;

  @override
  State<_BreathingRings> createState() => _BreathingRingsState();
}

class _BreathingRingsState extends State<_BreathingRings> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.94, end: 1.04).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ring(double size, Color fill) => ScaleTransition(
        scale: _scale,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fill, border: Border.all(color: AppColors.garis)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width - 2 * AppSpacing.xl;
    final k = (w / 320).clamp(0.7, 1.0);
    return SizedBox(
      width: 320 * k,
      height: 320 * k,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(320 * k, AppColors.kabutSage.withValues(alpha: 0.3)),
          _ring(260 * k, AppColors.kabutSage.withValues(alpha: 0.5)),
          _ring(200 * k, AppColors.permukaan),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RiungMonster(monsterId: widget.monsterId, state: MonsterVisualState.jinak, size: 140 * k, applyBossScale: false),
              SizedBox(
                width: 170 * k,
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTextStyles.title.copyWith(fontSize: 18, height: 1.15, color: AppColors.teksUtama),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
