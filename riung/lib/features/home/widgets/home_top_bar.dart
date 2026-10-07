import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Baris atas Beranda — tanggal + sapaan, chip streak & koin. Dipakai di
/// kedua varian Beranda (normal & tiket serangan).
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.userName,
    required this.streak,
    required this.coins,
    this.onTapStreak,
    this.onTapCoins,
  });

  final String userName;
  final int streak;
  final int coins;
  final VoidCallback? onTapStreak;
  final VoidCallback? onTapCoins;

  @override
  Widget build(BuildContext context) {
    final tanggal = DateFormat('EEEE, d MMMM', context.s.dateLocale).format(DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tanggal, style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.teksSekunder)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  context.s.home.greeting(userName),
                  maxLines: 1,
                  style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: onTapStreak,
          child: StreakChip(days: streak, compact: true),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: onTapCoins,
          child: KoinChip(balance: coins),
        ),
      ],
    );
  }
}
