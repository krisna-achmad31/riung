import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
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

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close, size: 20, color: AppColors.teksRedup)),
                  Text(t.nightMode, style: AppTextStyles.caption.copyWith(color: AppColors.teksRedup, fontWeight: FontWeight.w600, fontSize: 12)),
                  const Icon(Icons.nightlight_round, size: 17, color: AppColors.teksRedup),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.8,
                    child: _BreathingMonster(monsterId: widget.story.targetMonsterId),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.story(widget.story.id).title, textAlign: TextAlign.center, style: AppTextStyles.subtitle.copyWith(color: AppColors.teksSekunder, fontSize: 18)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t.playerSub(widget.story.reader, widget.timerMinutes),
                    style: AppTextStyles.caption.copyWith(color: AppColors.teksRedup, fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '${_remaining.inMinutes.toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: AppTextStyles.display.copyWith(fontSize: 44, letterSpacing: -1, color: AppColors.teksRedup),
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
                    child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: AppColors.permukaan, valueColor: const AlwaysStoppedAnimation(AppColors.garis)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.kartu, border: Border.all(color: AppColors.garis)),
                      alignment: Alignment.center,
                      child: Icon(_player.playing ? Icons.pause : Icons.play_arrow, size: 22, color: AppColors.teksSekunder),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(t.autoStop, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
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
    _scale = Tween<double>(begin: 1, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: 104,
        height: 110,
        child: RiungMonster(monsterId: widget.monsterId, state: MonsterVisualState.jinak, size: 104),
      ),
    );
  }
}
