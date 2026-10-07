import 'package:flutter/material.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Ikon 3D pengganti ilustrasi untuk tes tanpa monster, per topik.
RiungIcon kenaliTopicIcon(KenaliTopic topic) => switch (topic) {
      KenaliTopic.kebiasaan || KenaliTopic.perhatian => RiungIcon.fokus,
      KenaliTopic.tidur => RiungIcon.tidur,
      KenaliTopic.emosi => RiungIcon.checkin,
      KenaliTopic.relasi || KenaliTopic.diri => RiungIcon.afirmasi,
      KenaliTopic.pikiran || KenaliTopic.masaLalu => RiungIcon.jurnal,
      KenaliTopic.kepribadian => RiungIcon.kepribadian,
      KenaliTopic.kesejahteraan => RiungIcon.meditasi,
    };

/// Baris satu tes/kuis di hub (frame `Baris …`): ilustrasi di kotak kaca,
/// kicker topik, judul, dan pil status (meta soal, monster, lencana, hasil).
class KenaliEntryRow extends StatelessWidget {
  const KenaliEntryRow({
    super.key,
    required this.leading,
    required this.kicker,
    required this.title,
    required this.status,
    required this.onTap,
    this.highlight = false,
  });

  final Widget leading;
  final String kicker;
  final String title;
  final String? status;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusText = status;
    return RiungGlassCard(
      onTap: onTap,
      radius: 24,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: leading,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kicker, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup)),
                const SizedBox(height: 2),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                if (statusText != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: highlight ? AppColors.primerLembut : AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: highlight ? AppColors.primer : AppColors.teksSekunder),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.teksRedup),
        ],
      ),
    );
  }
}
