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

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: widget.session.color,
        alignment: const Alignment(0, -0.4),
        opacity: 0.16,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close, size: 20, color: AppColors.teksRedup),
                    ),
                    Text(t.session(widget.session.id).title, style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontWeight: FontWeight.w600, fontSize: 13)),
                    const Icon(Icons.nightlight_round, size: 18, color: AppColors.teksRedup),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BreathingRings(color: widget.session.color, monsterId: widget.session.targetMonsterId),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      phaseLabel ?? t.running,
                      style: AppTextStyles.subtitle.copyWith(color: widget.session.color, fontSize: 19),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Text(
                        t.followRhythm,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: _total.inSeconds == 0 ? 0 : _elapsed.inSeconds / _total.inSeconds,
                        minHeight: 5,
                        backgroundColor: AppColors.kartu,
                        valueColor: AlwaysStoppedAnimation(widget.session.color),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_elapsed.inMinutes.toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                        Text('$menit:$detik', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => _seek(-15),
                          child: Text(t.seekBack, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: widget.session.color),
                            alignment: Alignment.center,
                            child: Icon(_player.playing ? Icons.pause : Icons.play_arrow, size: 24, color: AppColors.latar),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        TextButton(
                          onPressed: () => _seek(15),
                          child: Text(t.seekForward, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ],
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

  static String _breathingPhaseLabel(MeditasiStrings t, Duration elapsed) {
    final phase = elapsed.inSeconds % 19;
    if (phase < 4) return t.breathIn;
    if (phase < 11) return t.breathHold(11 - phase);
    return t.breathOut;
  }
}

class _PreparingView extends StatelessWidget {
  const _PreparingView({required this.session, required this.progress});

  final MeditationSession session;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, size: 20, color: AppColors.teksRedup),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: CircularProgressIndicator(strokeWidth: 4, backgroundColor: AppColors.kartu, valueColor: AlwaysStoppedAnimation(session.color)),
                          ),
                          SizedBox(
                            width: 52,
                            height: 55,
                            child: RiungMonster(monsterId: session.targetMonsterId, state: MonsterVisualState.jinak, size: 52),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(context.s.meditasi.preparingTitle, style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.s.meditasi.preparingBody,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: AppColors.kartu, valueColor: AlwaysStoppedAnimation(session.color)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingRings extends StatefulWidget {
  const _BreathingRings({required this.color, required this.monsterId});

  final Color color;
  final String monsterId;

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
    _scale = Tween<double>(begin: 1, end: 1.08).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(width: 230, height: 230, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 0.1))),
          ),
          ScaleTransition(
            scale: _scale,
            child: Container(width: 178, height: 178, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 0.14))),
          ),
          ScaleTransition(
            scale: _scale,
            child: SizedBox(
              width: 118,
              height: 124,
              child: RiungMonster(monsterId: widget.monsterId, state: MonsterVisualState.jinak, size: 118),
            ),
          ),
        ],
      ),
    );
  }
}
