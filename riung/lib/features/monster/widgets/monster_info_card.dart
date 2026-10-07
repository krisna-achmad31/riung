import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Kartu info kaca dengan eyebrow (DI DUNIA NYATA / FAKTANYA / …).
class MonsterInfoCard extends StatelessWidget {
  const MonsterInfoCard({super.key, required this.eyebrow, required this.child, this.eyebrowColor = AppColors.teksRedup, this.color = AppColors.kartu});

  final String eyebrow;
  final Widget child;
  final Color eyebrowColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      radius: 24,
      color: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: eyebrowColor)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
