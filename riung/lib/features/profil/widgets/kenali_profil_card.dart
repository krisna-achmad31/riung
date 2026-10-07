import 'package:flutter/material.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/kenali_result_repository.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../kenali_dirimu/logic/kenali_progress.dart';
import '../../kenali_dirimu/screens/kenali_hub_screen.dart';

/// Kartu "Kenali Dirimu" di Profil (frame `Glass — Profil`): pil BARU,
/// "n tes & kuis · m selesai", progres, dua monster kebiasaan → hub.
/// Menggantikan baris Kepribadian (tes kepribadian kini ada di hub).
class KenaliProfilCard extends StatelessWidget {
  const KenaliProfilCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    final prefs = AppScope.of(context).prefs;
    final total = KenaliDirimuConfig.entries.length + KenaliDirimuConfig.jumlahTesKepribadian;
    return ListenableBuilder(
      listenable: Listenable.merge([KenaliResultRepository.instance.revision, prefs.personalityRevision]),
      builder: (context, _) {
        final done = KenaliProgress.doneCount(prefs.personalityResults);
        return RiungGlassCard(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KenaliHubScreen())),
          radius: 28,
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(t.title, style: AppTextStyles.title.copyWith(fontSize: 17, color: AppColors.teksUtama))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.aksenHangat, borderRadius: BorderRadius.circular(AppRadius.pill)),
                          child: Text(t.newPill, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.diAtasTinta)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(t.profilCardSub(total, done), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                    const SizedBox(height: 10),
                    RiungProgressBar(value: total == 0 ? 0 : done / total),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const RiungMonster(monsterId: 'nanti', state: MonsterVisualState.liar, size: 56, applyBossScale: false),
              const RiungMonster(monsterId: 'bunglon', state: MonsterVisualState.liar, size: 56, applyBossScale: false),
            ],
          ),
        );
      },
    );
  }
}
