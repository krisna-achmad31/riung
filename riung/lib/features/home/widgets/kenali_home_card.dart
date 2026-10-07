import 'package:flutter/material.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/kenali_result_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../kenali_dirimu/logic/kenali_content.dart';
import '../../kenali_dirimu/logic/kenali_navigator.dart';

/// Pintasan Kenali Dirimu di Beranda (frame `Glass — Beranda · Kenali
/// Dirimu`): "Sering bilang 'iya' padahal ingin bilang 'tidak'?" + Si
/// Bunglon liar → Kuis Pandangan Orang. Hilang setelah kuis itu selesai.
class KenaliHomeCard extends StatefulWidget {
  const KenaliHomeCard({super.key});

  static const quizId = 'people_pleaser_test';
  static const monsterId = 'bunglon';

  @override
  State<KenaliHomeCard> createState() => _KenaliHomeCardState();
}

class _KenaliHomeCardState extends State<KenaliHomeCard> {
  int? _minutes;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final entry = KenaliDirimuConfig.byId(KenaliHomeCard.quizId);
    if (_loading || entry == null) return;
    _loading = true;
    // Jumlah soal sama di semua bahasa; cukup dimuat sekali.
    KenaliContent.load(entry, context.s.language).then((test) {
      if (mounted) setState(() => _minutes = KenaliDirimuConfig.menitUntuk(test.questions.length));
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    final repo = KenaliResultRepository.instance;
    return ValueListenableBuilder<int>(
      valueListenable: repo.revision,
      builder: (context, _, _) {
        if (repo.resultOf(KenaliHomeCard.quizId) != null) return const SizedBox.shrink();
        final minutes = _minutes;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: RiungGlassCard(
            onTap: () => KenaliNavigator.openById(context, KenaliHomeCard.quizId),
            radius: 32,
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.homeKicker, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup)),
                      const SizedBox(height: 4),
                      Text(t.homeTitle, style: AppTextStyles.title.copyWith(fontSize: 16, height: 1.3, color: AppColors.teksUtama)),
                      if (minutes != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          t.homeMeta(t.entryTitle(KenaliHomeCard.quizId), minutes),
                          style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primer),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const RiungMonster(monsterId: KenaliHomeCard.monsterId, state: MonsterVisualState.liar, size: 92, applyBossScale: false),
              ],
            ),
          ),
        );
      },
    );
  }
}
