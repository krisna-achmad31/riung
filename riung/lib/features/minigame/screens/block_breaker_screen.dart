import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/block_breaker_engine.dart';
import '../logic/minigame_config.dart';
import '../widgets/block_breaker_painter.dart';
import 'minigame_lose_screen.dart';
import 'minigame_win_screen.dart';

/// Sesi serangan aktif: mini-game "pecahkan balok" ala Arkanoid. Bos berdiri
/// di tengah, dikelilingi balok "vonis"; pantulkan bola dengan papan,
/// pecahkan balok untuk menurunkan HP bos. Implement
/// `design/Monster.dc.html` § Mini-game aktif (papan + bola + balok vonis,
/// HP bos di atas, 60 detik). Fisika ada di [BlockBreakerEngine].
class BlockBreakerScreen extends StatefulWidget {
  const BlockBreakerScreen({super.key, required this.saboteur, this.startSpeedBonus = 0});

  final Saboteur saboteur;

  /// Bonus kecepatan awal bola — dipakai untuk menala level kesulitan bos
  /// Si Waswas (lihat `WaswasBossType.speedBonus`); 0 untuk saboteur lain.
  final double startSpeedBonus;

  @override
  State<BlockBreakerScreen> createState() => _BlockBreakerScreenState();
}

class _BlockBreakerScreenState extends State<BlockBreakerScreen> with SingleTickerProviderStateMixin {
  late final BlockBreakerEngine _engine;
  bool _engineReady = false;
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  int _seenBroken = 0;
  String? _flash;
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
    // Arena mengisi tinggi layar: perkirakan tinggi tersedia (layar dikurangi
    // area aman, HUD di atas, dan baris pesan di bawah) lalu ubah ke unit dunia.
    final media = MediaQuery.of(context);
    final scale = (media.size.width - 2 * AppSpacing.xl) / BlockBreakerEngine.width;
    final availableHeight = media.size.height - media.padding.vertical - 200;
    _engine = BlockBreakerEngine(height: availableHeight / scale, startSpeedBonus: widget.startSpeedBonus);
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
    if (_engine.brokenSeq != _seenBroken) {
      _seenBroken = _engine.brokenSeq;
      HapticFeedback.selectionClick();
      final strings = AppScope.of(context).language.strings.minigame;
      final labels = strings.verdictLabels;
      setState(() => _flash = strings.blockBroken(labels[_engine.lastBrokenLabel % labels.length], MinigameConfig.pointsPerBlock));
    }
    _frame.value++;
    if (_engine.status != BlockBreakerStatus.playing) _endSession();
  }

  void _pause() {
    _paused = true;
  }

  void _resume() {
    _paused = false;
  }

  Future<void> _confirmKeluar() async {
    // Dialog bisa dipicu dua kali (tombol jeda + tombol back sistem) —
    // abaikan yang kedua selagi yang pertama masih terbuka.
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
      // `pop()` langsung, BUKAN `maybePop()` — layar ini memakai
      // PopScope(canPop: false), jadi maybePop() akan ditolak dan
      // memunculkan dialog konfirmasi ini lagi tanpa akhir.
      Navigator.of(context).pop();
      return;
    }
    _resume();
  }

  Future<void> _endSession() async {
    if (_ended) return;
    _ended = true;
    _ticker.stop();
    final won = _engine.status == BlockBreakerStatus.won;
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
            ? MinigameWinScreen(saboteur: widget.saboteur, hits: _engine.blocksBroken, score: _engine.score, justTamed: justTamed, isReaction: false)
            : MinigameLoseScreen(saboteur: widget.saboteur, hits: _engine.blocksBroken, score: _engine.score, isReaction: false),
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _movePaddle(double localDx, double scale) => _engine.movePaddle(localDx / scale);

  @override
  Widget build(BuildContext context) {
    final t = context.s.minigame;
    final color = AppColors.monsterColors[widget.saboteur.id] ?? AppColors.primer;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmKeluar();
      },
      child: Scaffold(
        backgroundColor: AppColors.latar,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                child: ValueListenableBuilder<int>(
                  valueListenable: _frame,
                  builder: (context, _, _) {
                    final seconds = _engine.timeLeft.ceil();
                    final menit = (seconds ~/ 60).toString();
                    final detik = (seconds % 60).toString().padLeft(2, '0');
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(onPressed: _confirmKeluar, icon: const Icon(Icons.pause, color: AppColors.teksRedup)),
                        Row(
                          children: [
                            Text('$menit:$detik', style: AppTextStyles.chipLabel.copyWith(color: AppColors.sekunder, fontSize: 14)),
                            const SizedBox(width: AppSpacing.md),
                            Text('${_engine.score} ${t.points}', style: AppTextStyles.chipLabel.copyWith(color: AppColors.aksenHangat, fontSize: 14)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: ValueListenableBuilder<int>(
                  valueListenable: _frame,
                  builder: (context, _, _) {
                    final hp = _engine.bossHp.ceil();
                    return Row(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 42,
                          child: RiungMonster(monsterId: widget.saboteur.id, state: MonsterVisualState.liar, size: 40, applyBossScale: false),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                child: LinearProgressIndicator(
                                  value: hp / 100,
                                  minHeight: 8,
                                  backgroundColor: AppColors.permukaan,
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(t.hpLabel(widget.saboteur.nama, hp), style: AppTextStyles.caption.copyWith(fontSize: 10)),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        for (var i = 0; i < MinigameConfig.lives; i++)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(Icons.favorite, size: 14, color: i < _engine.lives ? AppColors.error : AppColors.garis),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Arena rasio tetap 320:480, diskalakan supaya muat.
                      final scale = (constraints.maxWidth / BlockBreakerEngine.width)
                          .clamp(0.0, constraints.maxHeight / _engine.height);
                      final w = BlockBreakerEngine.width * scale;
                      final h = _engine.height * scale;
                      final boss = _engine.bossRect;
                      return Center(
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (d) {
                              _movePaddle(d.localPosition.dx, scale);
                              _engine.launch();
                            },
                            onPanUpdate: (d) => _movePaddle(d.localPosition.dx, scale),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.latar,
                                border: Border.all(color: AppColors.kartu),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(19),
                                child: Stack(
                                  children: [
                                    // Bos di tengah blok, bergoyang kalau terkena.
                                    Positioned(
                                      left: boss.left * scale,
                                      top: boss.top * scale,
                                      width: boss.width * scale,
                                      height: boss.height * scale,
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: _frame,
                                        builder: (context, _, _) {
                                          final flash = _engine.bossFlash > 0;
                                          return Opacity(
                                            opacity: flash ? 0.55 : 1,
                                            child: FittedBox(
                                              child: SizedBox(
                                                width: boss.height,
                                                height: boss.height,
                                                child: RiungMonster(
                                                  monsterId: widget.saboteur.id,
                                                  state: flash ? MonsterVisualState.jinak : MonsterVisualState.liar,
                                                  size: boss.height,
                                                  applyBossScale: false,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: BlockBreakerPainter(
                                          engine: _engine,
                                          blockColor: color,
                                          labels: t.verdictLabels,
                                          repaint: _frame,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 56 * scale,
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: _frame,
                                        builder: (context, _, _) => Text(
                                          _engine.launched ? t.dragHint : t.tapToLaunch,
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                                        ),
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                child: SizedBox(
                  height: 16,
                  child: _flash == null ? null : Text(_flash!, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
