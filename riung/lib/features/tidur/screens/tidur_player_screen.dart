import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/sleeping_monster.dart';
import '../logic/sleep_catalog.dart';
import 'tidur_selesai_screen.dart';

/// Pemutar malam — audio placeholder di-loop, layar dijaga tetap menyala
/// (`WakelockPlus`, bukan mati sendiri di tengah cerita) sampai timer
/// habis, lalu auto-stop & memudar. Implement persis
/// `design/Tidur.dc.html` § Pemutar malam.
class TidurPlayerScreen extends StatefulWidget {
  const TidurPlayerScreen({super.key, required this.story, required this.timerMinutes});

  final SleepStory story;
  final int timerMinutes;

  @override
  State<TidurPlayerScreen> createState() => _TidurPlayerScreenState();
}

class _TidurPlayerScreenState extends State<TidurPlayerScreen> {
  final _player = AudioPlayer();
  late Duration _remaining = Duration(minutes: widget.timerMinutes);
  Timer? _ticker;
  StreamSubscription<ProcessingState>? _completedSub;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _startAudio();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _startAudio() async {
    try {
      await _player.setAsset(widget.story.assetPath);
      await _player.setVolume(0.7);
      // Cerita diputar sekali; begitu selesai (atau timer habis) sesi ditutup.
      _completedSub = _player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed && !_finishing && mounted) {
          _finishing = true;
          _finish();
        }
      });
      unawaited(_player.play());
    } catch (_) {
      // Audio gagal dimuat — timer & wakelock tetap jalan.
    }
  }

  void _tick() {
    if (!mounted) return;
    if (_remaining <= const Duration(seconds: 1)) {
      if (!_finishing) {
        _finishing = true;
        _finish();
      }
      return;
    }
    setState(() => _remaining -= const Duration(seconds: 1));
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    await _player.stop();
    await WakelockPlus.disable();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TidurSelesaiScreen(story: widget.story)),
    );
  }

  void _togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      unawaited(_player.play());
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _completedSub?.cancel();
    _player.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.tidur;
    final total = Duration(minutes: widget.timerMinutes);
    final progress = total.inSeconds == 0 ? 0.0 : 1 - (_remaining.inSeconds / total.inSeconds);
    final elapsed = total - _remaining;
    String fmt(Duration d) => '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      body: RiungGlassBackdrop(
        night: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              children: [
                Row(
                  children: [
                    RiungGlassIconButton(icon: Icons.close_rounded, night: true, onTap: () => Navigator.of(context).maybePop()),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: AppNight.card(radius: AppRadius.pill),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.dark_mode_rounded, size: 14, color: AppNight.aksen),
                              const SizedBox(width: 6),
                              Text(t.nightMode, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppNight.teks)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BreathingMonster(monsterId: widget.story.targetMonsterId),
                      const SizedBox(height: AppSpacing.lg),
                      Text(t.story(widget.story.id).title, textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 22, color: AppNight.teks)),
                      const SizedBox(height: 8),
                      Text(t.playerSub(widget.story.reader, widget.timerMinutes), style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppNight.teksRedup)),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: AppNight.pil, valueColor: const AlwaysStoppedAnimation(AppNight.aksen)),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(fmt(elapsed), style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppNight.teksRedup)),
                    Text(fmt(total), style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppNight.teksRedup)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppNight.teks),
                    child: Icon(_player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28, color: AppNight.latarBawah),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(t.autoStop, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppNight.teksRedup)),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingMonster extends StatefulWidget {
  const _BreathingMonster({required this.monsterId});

  final String monsterId;

  @override
  State<_BreathingMonster> createState() => _BreathingMonsterState();
}

class _BreathingMonsterState extends State<_BreathingMonster> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _scale = Tween<double>(begin: 1, end: 1.04).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: SleepingMonster(monsterId: widget.monsterId, size: 210, glow: 273));
  }
}
