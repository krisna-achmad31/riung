import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';
import '../logic/scoring_engine.dart';
import '../../profil/screens/bantuan_krisis_screen.dart';

/// Hasil asesmen — Si Hakim sebagai "Sang Bos" di atas, 6 anak buah
/// diurutkan skor tertinggi (dari [ScoringEngine], persis
/// `docs/assessment-scoring-spec.md`), disclaimer non-diagnosis di bawah.
/// Implement persis `design/Onboarding.dc.html` § Hasil asesmen.
class HasilAsesmenStep extends StatefulWidget {
  const HasilAsesmenStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  State<HasilAsesmenStep> createState() => _HasilAsesmenStepState();
}

class _HasilAsesmenStepState extends State<HasilAsesmenStep> {
  bool _menyimpan = false;

  Future<void> _mulai() async {
    setState(() => _menyimpan = true);
    await widget.controller.completeOnboarding(AppScope.of(context));
    if (!mounted) return;
    widget.controller.next();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.controller.result ?? const ScoringEngine().score(const {});
    final t = context.s.onboarding;
    final nama = widget.controller.nama.trim();
    return SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    RiungGlowBackground(
                      glowColor: AppColors.monsterHakim,
                      alignment: const Alignment(0, -1),
                      opacity: 0.3,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.sm),
                        child: Column(
                          children: [
                            Text(
                              t.resultLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.monsterCermin,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              t.resultIntro(nama.isEmpty ? t.defaultName : nama),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.display.copyWith(fontSize: 24),
                            ),
                            const SizedBox(
                              width: 170,
                              height: 178,
                              child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.liar, size: 170, applyBossScale: false),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(context.s.common.monsterName('hakim'), style: AppTextStyles.title.copyWith(fontSize: 22)),
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.monsterHakim),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    t.bossBadge,
                                    style: AppTextStyles.caption.copyWith(color: AppColors.monsterCermin, fontWeight: FontWeight.w700, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Text(
                                t.bossTagline,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.permukaan,
                              border: Border.all(color: AppColors.garis),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            child: Column(
                              children: [
                                _ScoreRow(
                                  monsterId: 'hakim',
                                  name: context.s.common.monsterName('hakim'),
                                  pct: result.hakimScore,
                                  size: 46,
                                  isBoss: true,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  child: Divider(color: AppColors.garis, height: 1),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    t.minionsHeading,
                                    style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                for (final id in result.dominantSaboteurs)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: _ScoreRow(
                                      monsterId: id,
                                      name: context.s.common.monsterName(id),
                                      pct: result.scoreOf(id),
                                      size: 34,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TahukahKamuCard(
                            text: t.didYouKnow,
                            source: t.didYouKnowSource,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _DisclaimerCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: RiungButton(
                label: _menyimpan ? t.saving : t.startTaming,
                onPressed: _menyimpan ? null : _mulai,
              ),
            ),
          ],
        ),
      );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.monsterId,
    required this.name,
    required this.pct,
    required this.size,
    this.isBoss = false,
  });

  final String monsterId;
  final String name;
  final int pct;
  final double size;
  final bool isBoss;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.monsterColors[monsterId] ?? AppColors.primer;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size * 210 / 200,
          child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.liar, size: size, applyBossScale: false),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTextStyles.chipLabel.copyWith(
                        color: AppColors.teksUtama,
                        fontSize: 12.5,
                        fontWeight: isBoss ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: AppTextStyles.chipLabel.copyWith(color: color, fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 7,
                  backgroundColor: AppColors.latar,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontSize: 12, height: 1.55),
                children: [
                  TextSpan(text: t.disclaimerText),
                  // Tampil seperti tautan, jadi harus benar-benar bisa
                  // diketuk: buka halaman bantuan krisis.
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BantuanKrisisScreen()),
                      ),
                      child: Text(
                        t.disclaimerLink,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
