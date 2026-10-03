import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

// 3 layar "rate us" — dipicu di momen nilai (monster pertama jinak / streak
// 7), BUKAN di tengah onboarding (lihat catatan di
// `design/Onboarding.dc.html`). Belum dipasang ke trigger manapun di M2
// (belum ada event "monster pertama jinak" nyata); widget sudah siap
// dipanggil begitu M4 menambahkan momen itu.

/// Rate us 1/3 — ajakan, muncul setelah momen nilai tercapai.
class RateUsAjakanStep extends StatelessWidget {
  const RateUsAjakanStep({super.key, required this.userName, required this.onLanjut, required this.onNantiSaja});

  final String userName;
  final VoidCallback onLanjut;
  final VoidCallback onNantiSaja;

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: AppColors.monsterKabut,
        alignment: const Alignment(0, -0.6),
        opacity: 0.18,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 120,
                        height: 126,
                        child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 120),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        t.rateKicker,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.monsterKabut,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.rateAsk(userName),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display.copyWith(fontSize: 23),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.rateBody,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
                child: Column(
                  children: [
                    RiungButton(label: t.rateYes, onPressed: onLanjut),
                    TextButton(
                      onPressed: onNantiSaja,
                      child: Text(context.s.common.nantiSaja, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rate us 2/3 — mockup lembar Google Play In-App Review. Di rilis nyata
/// ini digantikan sepenuhnya oleh sheet native (package `in_app_review`) —
/// app tidak pernah menggambar ulang chrome sistem itu sendiri.
class RateUsGooglePlayStep extends StatelessWidget {
  const RateUsGooglePlayStep({super.key, required this.userName, required this.onKirim, required this.onNanti});

  final String userName;
  final VoidCallback onKirim;
  final VoidCallback onNanti;

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Opacity(
                opacity: 0.3,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 120,
                        height: 126,
                        child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 120),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        t.rateAsk(userName),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display.copyWith(fontSize: 23),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _GooglePlaySheet(onKirim: onKirim, onNanti: onNanti),
          ],
        ),
      ),
    );
  }
}

class _GooglePlaySheet extends StatelessWidget {
  const _GooglePlaySheet({required this.onKirim, required this.onNanti});

  final VoidCallback onKirim;
  final VoidCallback onNanti;

  static const _googleGrey900 = Color(0xFF20222B);
  static const _googleGrey700 = Color(0xFF2A2D36);
  static const _googleGreyBorder = Color(0xFF3C4049);
  static const _googleTextPrimary = Color(0xFFE8EAED);
  static const _googleTextSecondary = Color(0xFF9AA0A6);
  static const _googleBlue = Color(0xFF8AB4F8);
  static const _googleStar = Color(0xFFFDD663);

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
      decoration: const BoxDecoration(
        color: _googleGrey900,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: _googleGreyBorder, borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: [AppColors.primer, AppColors.sekunder]),
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 30,
                  height: 32,
                  child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 30, applyBossScale: false),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.ratePlayTitle, style: const TextStyle(color: _googleTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(t.ratePlaySub, style: const TextStyle(color: _googleTextSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 36, color: _googleStar),
              SizedBox(width: 10),
              Icon(Icons.star, size: 36, color: _googleStar),
              SizedBox(width: 10),
              Icon(Icons.star, size: 36, color: _googleStar),
              SizedBox(width: 10),
              Icon(Icons.star, size: 36, color: _googleStar),
              SizedBox(width: 10),
              Icon(Icons.star, size: 36, color: _googleStar),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _googleGrey700,
              border: Border.all(color: _googleGreyBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              t.rateSampleReview,
              style: const TextStyle(color: _googleTextPrimary, fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.ratePublicNote,
            style: const TextStyle(color: _googleTextSecondary, fontSize: 11, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onNanti,
                child: Text(t.rateLater, style: const TextStyle(color: _googleBlue, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: onKirim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _googleBlue,
                  foregroundColor: const Color(0xFF202124),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Text(t.rateSend, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rate us 3/3 — ucapan terima kasih.
class RateUsTerimaKasihStep extends StatelessWidget {
  const RateUsTerimaKasihStep({super.key, required this.userName, required this.onSelesai});

  final String userName;
  final VoidCallback onSelesai;

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(width: 64, height: 67, child: RiungMonster(monsterId: 'mengelak', state: MonsterVisualState.jinak, size: 64)),
                        SizedBox(
                          width: 90,
                          height: 94,
                          child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 90, applyBossScale: false),
                        ),
                        SizedBox(width: 64, height: 67, child: RiungMonster(monsterId: 'meronta', state: MonsterVisualState.jinak, size: 64)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.rateThanks(userName), textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 23)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.rateThanksBody,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
              child: RiungButton(label: t.rateBack, onPressed: onSelesai),
            ),
          ],
        ),
      ),
    );
  }
}
