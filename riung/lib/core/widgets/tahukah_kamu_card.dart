import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';

/// Kartu "Tahukah kamu?" — fakta riset bersumber, dipakai di Beranda, hasil
/// asesmen, dan layar lain. Lihat §05 Komponen inti di
/// `design/Design System.dc.html`.
class TahukahKamuCard extends StatelessWidget {
  const TahukahKamuCard({super.key, required this.text, required this.source});

  final String text;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppGlass.card(radius: 28, color: AppColors.sekunderLembut.withValues(alpha: 0.7)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡  ${context.s.common.didYouKnow.replaceAll('?', '').toUpperCase()}',
            style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.sekunder),
          ),
          const SizedBox(height: 8),
          Text(text, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
          const SizedBox(height: 8),
          Text(source, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
        ],
      ),
    );
  }
}
