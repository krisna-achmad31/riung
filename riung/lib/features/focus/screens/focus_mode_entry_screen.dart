import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
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

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: scope.wallet,
          builder: (context, _) {
            final adaGratis = scope.wallet.freeFocusAvailable(premium: scope.auth.profile?.premiumNow ?? false);
            final adaSesiPrabayar = scope.wallet.prepaidFocusSessions > 0;
            final cukupKoin = adaGratis || adaSesiPrabayar || scope.wallet.coins >= option.priceCoins;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: AppTextStyles.display.copyWith(fontSize: 24)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(t.subtitle, style: AppTextStyles.body.copyWith(fontSize: 13)),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.kartu,
                          border: Border.all(color: AppColors.garis),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.sekunder),
                            const SizedBox(width: 6),
                            Text(t.worksOffline, style: AppTextStyles.caption.copyWith(color: AppColors.sekunder, fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.kartu,
                          border: Border.all(color: AppColors.garis),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.confirmation_number, size: 14, color: AppColors.monsterHakim),
                            const SizedBox(width: 6),
                            Text(t.attackTickets(scope.wallet.tickets), style: AppTextStyles.caption.copyWith(color: AppColors.monsterHakim, fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (adaSesiPrabayar)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.sekunder.withValues(alpha: 0.14),
                            border: Border.all(color: AppColors.sekunder),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_activity, size: 14, color: AppColors.sekunder),
                              const SizedBox(width: 6),
                              Text(
                                t.prepaidSessions(scope.wallet.prepaidFocusSessions),
                                style: AppTextStyles.caption.copyWith(color: AppColors.sekunder, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      for (var i = 0; i < _durations.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i == _durations.length - 1 ? 0 : AppSpacing.sm),
                            child: _DurationCard(
                              minutes: _durations[i].minutes,
                              priceCoins: _durations[i].priceCoins,
                              selected: _selected == i,
                              onTap: () => setState(() => _selected = i),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (!cukupKoin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        t.notEnoughCoins,
                        style: AppTextStyles.caption.copyWith(color: AppColors.error, fontSize: 12, height: 1.5),
                      ),
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
                                builder: (_) => FocusTimerScreen(
                                  duration: Duration(minutes: option.minutes),
                                  priceCoins: option.priceCoins,
                                ),
                              ),
                            )
                        : null,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  const _DurationCard({
    required this.minutes,
    required this.priceCoins,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final int priceCoins;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.sekunder.withValues(alpha: 0.14) : AppColors.permukaan,
          border: Border.all(color: selected ? AppColors.sekunder : AppColors.garis, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          children: [
            Text('$minutes', style: AppTextStyles.title.copyWith(fontSize: 26, color: selected ? AppColors.sekunder : AppColors.teksUtama)),
            Text(context.s.focus.minutesUnit, style: AppTextStyles.caption.copyWith(fontSize: 11)),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, size: 12, color: AppColors.aksenHangat),
                const SizedBox(width: 3),
                Text('$priceCoins', style: AppTextStyles.caption.copyWith(color: AppColors.aksenHangat, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
