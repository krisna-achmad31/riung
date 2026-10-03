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
  final IconData statIcon;
  final String statValue;
  final String statLabel;

  /// true untuk paket sesi fokus — CTA utama langsung ke Mode Fokus.
  final bool ctaMulaiFokus;

  @override
  Widget build(BuildContext context) {
    final coins = AppScope.of(context).wallet.coins;
    final t = context.s.toko;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: AppColors.sekunder,
        alignment: const Alignment(0, -0.6),
        opacity: 0.16,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sukses.withValues(alpha: 0.14),
                          border: Border.all(color: AppColors.sukses, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.check_rounded, size: 38, color: AppColors.sukses),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(title, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 23)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.body),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatBox(icon: statIcon, iconColor: AppColors.sekunder, value: statValue, label: statLabel),
                          const SizedBox(width: AppSpacing.sm),
                          _StatBox(icon: Icons.monetization_on, iconColor: AppColors.aksenHangat, value: '$coins', label: t.coinsLeft),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
                child: Column(
                  children: [
                    RiungButton(
                      label: ctaMulaiFokus ? t.startFirstSession : context.s.common.selesai,
                      onPressed: () {
                        if (ctaMulaiFokus) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const FocusModeEntryScreen()),
                          );
                        } else {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                      },
                    ),
                    if (ctaMulaiFokus)
                      TextButton(
                        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                        child: Text(context.s.common.nantiSaja, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
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

class _StatBox extends StatelessWidget {
  const _StatBox({required this.icon, required this.iconColor, required this.value, required this.label});

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.chipLabel.copyWith(color: iconColor, fontSize: 16)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
