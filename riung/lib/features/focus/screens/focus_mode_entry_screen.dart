import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/focus_ring.dart';
import '../../home/screens/focus_timer_screen.dart';

class _DurationOption {
  const _DurationOption(this.minutes, this.priceCoins);
  final int minutes;
  final int priceCoins;
}

const _durations = [
  _DurationOption(25, EconomySpend.fokus25Menit),
  _DurationOption(45, EconomySpend.fokus45Menit),
  _DurationOption(60, EconomySpend.fokus60Menit),
];

/// Pintu masuk tab "Fokus" — pilih durasi sebelum sesi jalan. Bukan bagian
/// dari `design/Home.dc.html` (yang langsung lompat dari kartu "Mode Fokus"
/// ke timer 25 menit tetap), tapi diperlukan supaya tab Fokus di navbar
/// punya isi sendiri yang masuk akal, bukan langsung memulai sesi.
class FocusModeEntryScreen extends StatefulWidget {
  const FocusModeEntryScreen({super.key});

  @override
  State<FocusModeEntryScreen> createState() => _FocusModeEntryScreenState();
}

class _FocusModeEntryScreenState extends State<FocusModeEntryScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.focus;
    final option = _durations[_selected];
    final profile = scope.auth.profile;
    final monsterId = (profile != null && profile.dominantSaboteurs.isNotEmpty) ? profile.dominantSaboteurs.first : 'waswas';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: scope.wallet,
          builder: (context, _) {
            final adaGratis = scope.wallet.freeFocusAvailable(premium: profile?.premiumNow ?? false);
            final adaSesiPrabayar = scope.wallet.prepaidFocusSessions > 0;
            final cukupKoin = adaGratis || adaSesiPrabayar || scope.wallet.coins >= option.priceCoins;
            return ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl + MediaQuery.paddingOf(context).bottom),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(t.subtitle, style: AppTextStyles.caption.copyWith(fontSize: 13, height: 1.4, color: AppColors.teksSekunder)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    KoinChip(balance: scope.wallet.coins),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FocusRing(monsterId: monsterId, time: '${option.minutes}:00', unit: t.minutesUnit, progress: 0.78),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    for (var i = 0; i < _durations.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _DurationCard(
                          minutes: _durations[i].minutes,
                          price: i == 0 && adaGratis ? t.freeToday : t.coinsPrice(_durations[i].priceCoins),
                          free: i == 0 && adaGratis,
                          selected: _selected == i,
                          onTap: () => setState(() => _selected = i),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(icon: Icons.wifi_off_rounded, label: t.worksOffline),
                    _InfoPill(icon: Icons.confirmation_number_outlined, label: t.attackTickets(scope.wallet.tickets)),
                    if (adaSesiPrabayar) _InfoPill(icon: Icons.local_activity_outlined, label: t.prepaidSessions(scope.wallet.prepaidFocusSessions)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppGlass.card(radius: 22, color: AppColors.kabutSage.withValues(alpha: 0.5), shadowed: false),
                  child: Row(
                    children: [
                      const Icon(Icons.air_rounded, size: 18, color: AppColors.primer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.companionNote(context.s.common.monsterName(monsterId)),
                          style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.primer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!cukupKoin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(t.notEnoughCoins, style: AppTextStyles.caption.copyWith(color: AppColors.error, fontSize: 12, height: 1.5)),
                  ),
                RiungButton(
                  label: adaGratis
                      ? t.startFree(option.minutes)
                      : adaSesiPrabayar
                          ? t.startPrepaid(option.minutes)
                          : t.startPaid(option.minutes, option.priceCoins),
                  onPressed: cukupKoin
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FocusTimerScreen(duration: Duration(minutes: option.minutes), priceCoins: option.priceCoins),
                            ),
                          )
                      : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: AppColors.kartu, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.garis)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.teksSekunder),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}

/// Kartu durasi (frame `Durasi …`): angka besar, "menit", pil harga.
class _DurationCard extends StatelessWidget {
  const _DurationCard({required this.minutes, required this.price, required this.free, required this.selected, required this.onTap});

  final int minutes;
  final String price;
  final bool free;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.permukaanPadat.withValues(alpha: 0.9) : AppColors.kartu,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: selected ? 2 : 1.5),
          ),
          child: Column(
            children: [
              Text('$minutes', style: AppTextStyles.title.copyWith(fontSize: 26, height: 1.15, color: selected ? AppColors.primer : AppColors.teksUtama)),
              Text(context.s.focus.minutesUnit, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: free ? AppColors.primerLembut : AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!free) ...[const RiungIcon3D(RiungIcon.koin, size: 14), const SizedBox(width: 4)],
                    Flexible(
                      child: Text(
                        price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: free ? AppColors.primer : AppColors.teksSekunder),
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
