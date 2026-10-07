import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../focus/screens/focus_mode_entry_screen.dart';

/// Pembelian berhasil — dipakai untuk paket sesi fokus & kosmetik (bukan
/// koin/Premium, yang punya alur Play Billing-nya sendiri lewat
/// [BillingService]). Implement persis `design/Toko.dc.html` §
/// "Pembelian sukses".
class PembelianSuksesScreen extends StatelessWidget {
  const PembelianSuksesScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statIcon,
    required this.statValue,
    required this.statLabel,
    this.ctaMulaiFokus = false,
  });

  final String title;
  final String subtitle;
  final RiungIcon statIcon;
  final String statValue;
  final String statLabel;

  /// true untuk paket sesi fokus — CTA utama langsung ke Mode Fokus.
  final bool ctaMulaiFokus;

  @override
  Widget build(BuildContext context) {
    final coins = AppScope.of(context).wallet.coins;
    final t = context.s.toko;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RiungSparkleHero(child: RiungIcon3D(statIcon, size: 170)),
                    const SizedBox(height: AppSpacing.md),
                    Text(title, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.teksSekunder)),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(child: RiungStatTile(leading: RiungIcon3D(statIcon, size: 40), value: statValue, label: statLabel)),
                        const SizedBox(width: 10),
                        Expanded(child: RiungStatTile(leading: const RiungIcon3D(RiungIcon.koin, size: 40), value: '$coins', label: t.coinsLeft)),
                      ],
                    ),
                  ],
                ),
              ),
              RiungButton(
                label: ctaMulaiFokus ? t.startFirstSession : context.s.common.selesai,
                onPressed: () {
                  if (ctaMulaiFokus) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const FocusModeEntryScreen()));
                  } else {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              ),
              if (ctaMulaiFokus) ...[
                const SizedBox(height: 10),
                RiungButton(
                  label: t.backToHome,
                  variant: RiungButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
