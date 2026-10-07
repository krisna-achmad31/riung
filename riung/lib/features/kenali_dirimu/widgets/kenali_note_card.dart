import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Kartu catatan kecil berikon (privasi, catatan wujud, disclaimer).
class KenaliNoteCard extends StatelessWidget {
  const KenaliNoteCard({super.key, required this.text, this.icon = Icons.lock_outline_rounded, this.color = AppColors.kartu});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      radius: 20,
      color: color,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primer),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksUtama))),
        ],
      ),
    );
  }
}
