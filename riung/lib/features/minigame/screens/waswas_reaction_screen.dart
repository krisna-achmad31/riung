import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/minigame_config.dart';
import '../logic/waswas_reaction_engine.dart';
import '../widgets/waswas_reaction_painter.dart';
import 'minigame_lose_screen.dart';
import 'minigame_win_screen.dart';

/// Sesi serangan Si Waswas: "Lepaskan Pikiran" — gelembung pikiran terburuk
/// naik dari bawah, sentuh sebelum menyentuh garis atas untuk dilepaskan.
/// Beda mekanik dari Block Breaker (menghancurkan) karena inti Si Waswas
/// beda: bukan soal menghancurkan, tapi bertahan tenang tanpa kewalahan.
/// Kesulitan (`intensity`) dihitung dari seberapa liar Si Waswas sekarang —
/// makin sering dilatih, makin jinak, makin mudah — bukan dari pembelian.
class WaswasReactionScreen extends StatefulWidget {
  const WaswasReactionScreen({super.key, required this.saboteur});

  final Saboteur saboteur;

  @override
  State<WaswasReactionScreen> createState() => _WaswasReactionScreenState();
}

class _WaswasReactionScreenState extends State<WaswasReactionScreen> with SingleTickerProviderStateMixin {
  late final WaswasReactionEngine _engine;
  bool _engineReady = false;
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  int _seenHits = 0;
  bool _ended = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_engineReady) return;
    final scope = AppScope.of(context);
    final progress = scope.monsterProgress.progressOf(widget.saboteur.id)?.progress ?? 0;
    // Makin rendah progres (makin liar), makin tinggi intensitasnya.
    final intensity = (100 - progress) / 100;
    _engine = WaswasReactionEngine(intensity: intensity);
    _engineReady = true;
  }

  void _onTick(Duration elapsed) {
    if (_ended || _paused) {
      _last = elapsed;
      return;
    }
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _engine.step(dt);
    if (_engine.hits != _seenHits) {
      _seenHits = _engine.hits;
      HapticFeedback.selectionClick();
    }
    _frame.value++;
    if (_engine.status != WaswasReactionStatus.playing) _endSession();
  }

  void _pause() => _paused = true;
  void _resume() => _paused = false;

  Future<void> _confirmKeluar() async {
    if (_ended || _paused) return;
    _pause();
    final keluar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.permukaan,
        title: Text(dialogContext.s.minigame.exitTitle, style: AppTextStyles.title.copyWith(fontSize: 17)),
        content: Text(dialogContext.s.minigame.exitBody, style: AppTextStyles.body.copyWith(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(dialogContext.s.common.batal)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(dialogContext.s.common.keluar)),
        ],
      ),
    );
    if (!mounted) return;
    if (keluar == true) {
      _ended = true;
      _ticker.stop();
      Navigator.of(context).pop();
      return;
    }
    _resume();
  }

  Future<void> _endSession() async {
    if (_ended) return;
    _ended = true;
    _ticker.stop();
    final won = _engine.status == WaswasReactionStatus.won;
    final scope = AppScope.of(context);
    final wasTamed = scope.monsterProgress.progressOf(widget.saboteur.id)?.state == MonsterState.tamed;
    final delta = won ? EconomyEarn.minigameWinProgressPercent : EconomyEarn.minigameLoseProgressPercent;
    await scope.monsterProgress.tambahProgres(saboteurId: widget.saboteur.id, delta: delta);
    if (won) {
      await scope.wallet.earn(amount: EconomyEarn.menangGame, reason: 'minigame_win:${widget.saboteur.id}');
    }
    if (!mounted) return;
    final justTamed = !wasTamed && scope.monsterProgress.progressOf(widget.saboteur.id)?.state == MonsterState.tamed;
    scope.analytics.minigameComplete(saboteurId: widget.saboteur.id, won: won);
    if (justTamed) {
      scope.analytics.monsterTamed(saboteurId: widget.saboteur.id);
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => won
            ? MinigameWinScreen(saboteur: widget.saboteur, hits: _engine.hits, score: _engine.score, justTamed: justTamed, isReaction: true)
            : MinigameLoseScreen(saboteur: widget.saboteur, hits: _engine.hits, score: _engine.score, isReaction: true),
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _handleTap(Offset local, double scale) => _engine.tap(local.dx / scale, local.dy / scale);

  @override
  Widget build(BuildContext context) {
    final t = context.s.minigame;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmKeluar();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
            child: Column(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _frame,
                  builder: (context, _, _) {
                    final seconds = _engine.timeLeft.ceil();
                    final waktu = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
                    return Row(
                      children: [
                        RiungGlassIconButton(icon: Icons.pause_rounded, onTap: _confirmKeluar),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(waktu, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.aksenHangatGelap)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  for (var i = 0; i < MinigameConfig.lives; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(Icons.favorite_rounded, size: 16, color: i < _engine.lives ? AppColors.aksenHangat : AppColors.permukaan),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 52,
                          height: 42,
                          decoration: AppGlass.card(radius: 14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${_engine.score}', style: AppTextStyles.title.copyWith(fontSize: 16, height: 1.1)),
                              Text(t.points, style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.teksSekunder)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scale = (constraints.maxWidth / WaswasReactionEngine.width).clamp(0.0, constraints.maxHeight / WaswasReactionEngine.height);
                      final w = WaswasReactionEngine.width * scale;
                      final h = WaswasReactionEngine.height * scale;
                      return Center(
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (d) => _handleTap(d.localPosition, scale),
                            child: DecoratedBox(
                              decoration: AppGlass.card(radius: 30, color: AppColors.permukaan.withValues(alpha: 0.5)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(29),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: RiungMonster(monsterId: widget.saboteur.id, state: MonsterVisualState.liar, size: 110 * scale.clamp(0.6, 1.0), applyBossScale: false),
                                    ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: WaswasReactionPainter(engine: _engine, labels: t.worryLabels, repaint: _frame),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(t.waswasReactionHint, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.teksSekunder)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
