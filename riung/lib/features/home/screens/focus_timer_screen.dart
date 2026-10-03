import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'sesi_selesai_screen.dart';

/// Sesi Mode Fokus aktif — timer, monster idle bernapas, jeda & keluar
/// darurat (netral, streak aman). Implement persis `design/Home.dc.html`
/// § Timer fokus — sesi aktif.
class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({
    super.key,
    this.duration = const Duration(minutes: 25),
    this.priceCoins = EconomySpend.fokus25Menit,
  });

  final Duration duration;
  final int priceCoins;

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  bool _starting = true;
  bool _insufficientCoins = false;
  bool _navigatedToResult = false;

  @override
  void initState() {
    super.initState();
    _mulaiSesi();
  }

  Future<void> _mulaiSesi() async {
    final wallet = AppScope.of(context).wallet;
    // Sesi prabayar dari Toko dipakai duluan (jalan offline seperti tiket
    // serangan) — baru kalau habis, potong koin langsung per sesi.
    // Sesi gratis harian dulu: progres monster tidak boleh bergantung pada koin.
    final pakaiGratis = await wallet.consumeFreeFocusSession(premium: AppScope.of(context).auth.profile?.premiumNow ?? false);
    final pakaiPrabayar = !pakaiGratis && await wallet.consumePrepaidFocusSession();
    final berhasil = pakaiGratis || pakaiPrabayar ||
        await wallet.spend(amount: widget.priceCoins, reason: 'focus_${widget.duration.inMinutes}min');
    if (!mounted) return;
    if (!berhasil) {
      setState(() {
        _starting = false;
        _insufficientCoins = true;
      });
      return;
    }
    AppScope.of(context).session.start(widget.duration);
    AppScope.of(context).analytics.focusStart(durationMinutes: widget.duration.inMinutes);
    setState(() => _starting = false);
  }

  void _keluarDarurat() {
    AppScope.of(context).session.cancel();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (_starting) {
      return const Scaffold(
        backgroundColor: AppColors.latar,
        body: Center(child: CircularProgressIndicator(color: AppColors.sekunder)),
      );
    }
    if (_insufficientCoins) {
      return _InsufficientCoinsView(priceCoins: widget.priceCoins, onBack: () => Navigator.of(context).maybePop());
    }

    final session = AppScope.of(context).session;
    final t = context.s.home;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: AppColors.sekunder,
        alignment: const Alignment(0, -0.6),
        opacity: 0.14,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: session,
            builder: (context, _) {
              if (session.endReason == SessionEndReason.completed && !_navigatedToResult) {
                _navigatedToResult = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => SesiSelesaiScreen(duration: widget.duration)),
                  );
                });
              }
              final total = session.totalDuration ?? widget.duration;
              final elapsedFraction = total.inSeconds == 0
                  ? 0.0
                  : 1 - (session.remaining.inSeconds / total.inSeconds);
              final menit = session.remaining.inMinutes.toString().padLeft(2, '0');
              final detik = (session.remaining.inSeconds % 60).toString().padLeft(2, '0');

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.kartu,
                            border: Border.all(color: AppColors.garis),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phonelink_lock, size: 14, color: AppColors.sekunder),
                              const SizedBox(width: 6),
                              Text(
                                t.appsBlocked,
                                style: AppTextStyles.caption.copyWith(color: AppColors.sekunder, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          t.sessionMinutes(total.inMinutes),
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 250,
                                  height: 250,
                                  child: CircularProgressIndicator(
                                    value: elapsedFraction,
                                    strokeWidth: 10,
                                    backgroundColor: AppColors.kartu,
                                    valueColor: const AlwaysStoppedAnimation(AppColors.sekunder),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$menit:$detik',
                                      style: AppTextStyles.display.copyWith(fontSize: 52, letterSpacing: -1),
                                    ),
                                    Text(t.remaining, style: AppTextStyles.caption),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _BreathingMonster(),
                          const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                            child: Text(
                              t.focusCompanion,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: session.isPaused ? session.resume : session.pause,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.garis, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                            ),
                            icon: Icon(
                              session.isPaused ? Icons.play_arrow : Icons.pause,
                              size: 16,
                              color: AppColors.teksSekunder,
                            ),
                            label: Text(
                              session.isPaused ? t.resume : t.pause,
                              style: AppTextStyles.subtitle.copyWith(fontSize: 15, color: AppColors.teksSekunder),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _keluarDarurat,
                          child: Text(
                            t.emergencyExit,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BreathingMonster extends StatefulWidget {
  const _BreathingMonster();

  @override
  State<_BreathingMonster> createState() => _BreathingMonsterState();
}

class _BreathingMonsterState extends State<_BreathingMonster> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _scale = Tween<double>(begin: 1, end: 1.06).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      child: const SizedBox(
        width: 96,
        height: 100,
        child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 96),
      ),
    );
  }
}

class _InsufficientCoinsView extends StatelessWidget {
  const _InsufficientCoinsView({required this.priceCoins, required this.onBack});

  final int priceCoins;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = context.s.home;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_outlined, size: 40, color: AppColors.aksenHangat),
                const SizedBox(height: AppSpacing.md),
                Text(
                  t.notEnoughCoins(priceCoins),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  t.fastestWayToCoins,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.lg),
                RiungButton(label: context.s.common.kembali, onPressed: onBack),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
