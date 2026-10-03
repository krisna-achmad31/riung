import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../betterme/data/betterme_content.dart';
import '../../betterme/screens/betterme_home_screen.dart';
import '../../betterme/screens/level_intro_screen.dart';
import '../../minigame/screens/minigame_intro_screen.dart';
import '../logic/saboteur_content.dart';
import 'waswas_stage_map_screen.dart';

/// Detail satu saboteur (bukan bos). Implement persis
/// `design/Monster.dc.html` § Detail — Si Waswas.
///
/// Tombol "Serang" tidak ada di mockup desain (yang hanya menggambar
/// contoh Si Waswas dengan satu CTA "Latihan yang dia takuti"), tapi
/// ditambahkan di sini supaya mini-game bisa dipicu dari monster mana pun
/// yang sedang aktif dijinakkan — bukan cuma dari Si Hakim — sesuai
/// `docs/riung-cara-kerja-lengkap.md` §5 ("serangan ke monster aktif").
class SaboteurDetailScreen extends StatelessWidget {
  const SaboteurDetailScreen({super.key, required this.saboteur});

  final Saboteur saboteur;

  /// Si Hakim → langsung ke Level 1 ("Kenalan sama Si Hakim", lihat
  /// `betterme_content.dart`) karena judulnya cocok persis dengan monster
  /// ini. Saboteur lain belum punya level Better me yang didedikasikan
  /// khusus untuknya, jadi cukup ke home Better me (sesuai fallback yang
  /// diminta).
  void _bukaLatihanCbt(BuildContext context) {
    if (saboteur.id == 'hakim') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LevelIntroScreen(level: betterMeLevels.first)));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BetterMeHomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.monster;
    final content = saboteurContentFor(saboteur.id, t);
    final color = AppColors.monsterColors[saboteur.id] ?? AppColors.primer;

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: scope.monsterProgress,
          builder: (context, _) {
            final progress = scope.monsterProgress.progressOf(saboteur.id) ?? MonsterProgress.initial(saboteur.id);
            final isTamed = progress.state == MonsterState.tamed;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder)),
                      Expanded(child: Text(context.s.common.monsterName(saboteur.id), style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(
                          isTamed ? t.tamedBadge : t.tamedPercent(progress.progress),
                          style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              width: 140,
                              height: 147,
                              child: RiungMonster(
                                monsterId: saboteur.id,
                                state: isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar,
                                size: 140,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(t.saboteurDescription(saboteur.id, saboteur.deskripsi), textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.55)),
                            const SizedBox(height: AppSpacing.sm),
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  child: LinearProgressIndicator(
                                    value: progress.progress / 100,
                                    minHeight: 9,
                                    backgroundColor: AppColors.permukaan,
                                    valueColor: AlwaysStoppedAnimation(color),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(t.wild, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                                    Text('${progress.progress}%', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
                                    Text(t.tamed, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (content != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.xl)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.realWorld, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 12)),
                                const SizedBox(height: AppSpacing.sm),
                                Text(content.duniaNyata, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.6)),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.08), border: Border.all(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(AppRadius.xl)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.whatItSays, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 11)),
                                      const SizedBox(height: 7),
                                      Text('"${content.apaKatanya}"', style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.55, color: AppColors.teksUtama, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(color: AppColors.sekunder.withValues(alpha: 0.08), border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(AppRadius.xl)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.theFact, style: AppTextStyles.caption.copyWith(color: AppColors.sekunder, fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 11)),
                                      const SizedBox(height: 7),
                                      Text(content.faktanya, style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.55)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.xl)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.antidotes, style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontWeight: FontWeight.w700, letterSpacing: 0.6, fontSize: 12)),
                                const SizedBox(height: AppSpacing.sm),
                                for (final teknik in content.techniques) _TeknikRow(teknik: teknik, color: color),
                                const Divider(color: AppColors.garis, height: 20),
                                Row(
                                  children: [
                                    const Icon(Icons.bolt, size: 14, color: AppColors.monsterHakim),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        t.antidoteNote,
                                        style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            // Si Waswas punya peta latihan (uji coba per-monster,
                            // lihat WaswasStageMapScreen); saboteur lain masih
                            // langsung ke intro serangan seperti sebelumnya.
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => saboteur.id == 'waswas'
                                    ? WaswasStageMapScreen(saboteur: saboteur)
                                    : MinigameIntroScreen(saboteur: saboteur),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: AppColors.latar,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                            ),
                            icon: const Icon(Icons.bolt, size: 17),
                            label: Text(t.attack, style: AppTextStyles.chipLabel.copyWith(color: AppColors.latar, fontSize: 15)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => _bukaLatihanCbt(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.garis, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                            ),
                            child: Text(t.cbtPractice, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TeknikRow extends StatelessWidget {
  const _TeknikRow({required this.teknik, required this.color});

  final SaboteurTechnique teknik;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: Icon(teknik.icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(teknik.label, style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.45)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text('${teknik.multiplier}×', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
