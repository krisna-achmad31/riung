import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../focus/widgets/focus_ring.dart';
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
        body: Center(child: CircularProgressIndicator(color: AppColors.primer)),
      );
    }
    if (_insufficientCoins) {
      return _InsufficientCoinsView(priceCoins: widget.priceCoins, onBack: () => Navigator.of(context).maybePop());
    }

    final session = AppScope.of(context).session;
    final t = context.s.home;
    final profile = AppScope.of(context).auth.profile;
    final monsterId = (profile != null && profile.dominantSaboteurs.isNotEmpty) ? profile.dominantSaboteurs.first : 'waswas';
    return Scaffold(
      body: RiungGlassBackdrop(
        night: true,
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
              final elapsedFraction = total.inSeconds == 0 ? 0.0 : 1 - (session.remaining.inSeconds / total.inSeconds);
              final menit = session.remaining.inMinutes.toString().padLeft(2, '0');
              final detik = (session.remaining.inSeconds % 60).toString().padLeft(2, '0');

              return Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: AppNight.card(radius: AppRadius.pill),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.kabutSage),
                          const SizedBox(width: 6),
                          Text(t.appsBlocked, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppNight.teks)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.sessionMinutes(total.inMinutes), style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppNight.teksSekunder)),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _BreathingMonster(
                            child: FocusRing(monsterId: monsterId, time: '$menit:$detik', unit: t.remaining, progress: elapsedFraction, night: true),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: AppNight.card(),
                            child: Row(
                              children: [
                                const Icon(Icons.air_rounded, size: 18, color: AppColors.kabutSage),
                                const SizedBox(width: 10),
                                Expanded(child: Text(t.focusCompanion, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppNight.teksSekunder))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    RiungButton(
                      label: session.isPaused ? t.resume : t.pause,
                      icon: session.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      variant: RiungButtonVariant.night,
                      onPressed: session.isPaused ? session.resume : session.pause,
                    ),
                    TextButton(
                      onPressed: _keluarDarurat,
                      child: Text(t.emergencyExit, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 12, color: AppNight.teksRedup)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Cincin & monster bernapas pelan (skala 1 → 1.03).
class _BreathingMonster extends StatefulWidget {
  const _BreathingMonster({required this.child});

  final Widget child;

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
    _scale = Tween<double>(begin: 1, end: 1.03).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}

class _InsufficientCoinsView extends StatelessWidget {
  const _InsufficientCoinsView({required this.priceCoins, required this.onBack});

  final int priceCoins;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = context.s.home;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RiungIcon3D(RiungIcon.koin, size: 96),
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
