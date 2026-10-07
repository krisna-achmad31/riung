import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';
import '../logic/scoring_engine.dart';
import '../../profil/screens/bantuan_krisis_screen.dart';
import 'onboarding_tag.dart';

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, AppSpacing.sm, 24, AppSpacing.md),
        child: Column(
          children: [
            Expanded(
              child: RiungBleedListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                children: [
                  Align(alignment: Alignment.centerLeft, child: OnboardingTag(t.resultLabel)),
                  const SizedBox(height: AppSpacing.md),
                  Text(t.resultIntro(nama.isEmpty ? t.defaultName : nama), style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
                  const SizedBox(height: AppSpacing.md),
                  _BossCard(name: context.s.common.monsterName('hakim'), badge: t.bossBadge, tagline: t.bossTagline, pct: result.hakimScore),
                  const SizedBox(height: AppSpacing.md),
                  Text(t.minionsHeading, style: AppTextStyles.title.copyWith(fontSize: 16)),
                  const SizedBox(height: AppSpacing.md),
                  RiungGlassCard(
                    radius: 26,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < result.dominantSaboteurs.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _ScoreRow(
                            monsterId: result.dominantSaboteurs[i],
                            name: context.s.common.monsterName(result.dominantSaboteurs[i]),
                            pct: result.scoreOf(result.dominantSaboteurs[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TahukahKamuCard(text: t.didYouKnow, source: t.didYouKnowSource),
                  const SizedBox(height: AppSpacing.md),
                  const _Disclaimer(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            RiungButton(label: _menyimpan ? t.saving : t.startTaming, onPressed: _menyimpan ? null : _mulai),
          ],
        ),
      ),
    );
  }
}

/// Kartu bos (frame `Kartu bos`): gradien lavender, Si Hakim liar di
/// panggung, badge "SANG BOS", nama + skor bos, tagline.
class _BossCard extends StatelessWidget {
  const _BossCard({required this.name, required this.badge, required this.tagline, required this.pct});

  final int pct;
  final String name;
  final String badge;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.sekunderPucat, AppColors.sekunderMuda]),
        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
        borderRadius: BorderRadius.circular(34),
        boxShadow: AppGlass.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 190,
                  height: 180,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.permukaan, AppColors.permukaan.withValues(alpha: 0)])),
                ),
                const RiungMonster(monsterId: 'hakim', state: MonsterVisualState.liar, size: 180, applyBossScale: false),
                Positioned(
                  left: 0,
                  top: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.sekunderGelap, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text(badge, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.diAtasTinta)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(name, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2))),
              Text('$pct%', style: AppTextStyles.title.copyWith(fontSize: 18, color: AppColors.sekunderGelap)),
            ],
          ),
          const SizedBox(height: 6),
          Text(tagline, style: AppTextStyles.caption.copyWith(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}

/// Baris anak buah (frame `Baris …`): thumb kaca, nama, %, bar.
class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.monsterId, required this.name, required this.pct});

  final String monsterId;
  final String name;
  final int pct;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.monsterColors[monsterId] ?? AppColors.primer;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.center,
          child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.liar, size: 40, applyBossScale: false),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(name, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14))),
                  Text('$pct%', style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksSekunder)),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                height: 6,
                decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(3)),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  heightFactor: 1,
                  widthFactor: (pct / 100).clamp(0.0, 1.0),
                  child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Disclaimer non-diagnosis (frame `Disclaimer`) + tautan bantuan krisis.
class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.disclaimerText.trim(), style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BantuanKrisisScreen())),
          child: Text(t.disclaimerLink, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primer)),
        ),
      ],
    );
  }
}
