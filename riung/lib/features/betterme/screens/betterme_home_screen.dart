import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/betterme_content.dart';
import '../logic/betterme_progress.dart';
import 'level_intro_screen.dart';

/// Path map Better Me — 3 level, tiap level 6-8 sesi. Tidak ada mockup
/// desain terpisah untuk layar ini (`design/Profil.dc.html` § "Better
/// Me" menggambarkan dashboard statistik yang butuh data historis
/// fokus/tidur yang tidak pernah dicatat di app ini, lihat laporan
/// deviasi) — dibangun mengikuti bahasa visual Vault/Toko yang sudah ada.
class BetterMeHomeScreen extends StatefulWidget {
  const BetterMeHomeScreen({super.key});

  @override
  State<BetterMeHomeScreen> createState() => _BetterMeHomeScreenState();
}

class _BetterMeHomeScreenState extends State<BetterMeHomeScreen> {
  Future<void> _bukaLevel(BetterMeLevel level) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LevelIntroScreen(level: level)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final progress = BetterMeProgress(scope.prefs);
    final total = betterMeTotalSessions;

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
                  ),
                  Text(context.s.betterme.title, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: scope.auth,
                builder: (context, _) {
                  final premiumActive = scope.auth.profile?.premiumNow ?? false;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.s.betterme.subtitle, style: AppTextStyles.body.copyWith(fontSize: 13)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(context.s.betterme.totalDone(progress.totalCompleted, total), style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sekunder)),
                        const SizedBox(height: AppSpacing.lg),
                        for (final level in betterMeLevels) ...[
                          _LevelCard(
                            level: level,
                            completedCount: progress.completedInLevel(level.number),
                            unlocked: progress.isLevelUnlocked(level.number, premiumActive: premiumActive),
                            onTap: () => _bukaLevel(level),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.completedCount, required this.unlocked, required this.onTap});

  final BetterMeLevel level;
  final int completedCount;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = level.sessions.length;
    final selesai = completedCount == total;

    return GestureDetector(
      onTap: () {
        if (!unlocked) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PremiumLockedScreen(
                title: context.s.betterme.levelLockedTitle(level.number),
                freeTierNote: context.s.betterme.levelLockedNote(level.number - 1),
              ),
            ),
          );
          return;
        }
        onTap();
      },
      child: Opacity(
        opacity: unlocked ? 1 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.permukaan,
            border: Border.all(color: selesai ? AppColors.sukses : AppColors.garis, width: selesai ? 1.5 : 1),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (selesai ? AppColors.sukses : AppColors.primer).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      unlocked ? (selesai ? Icons.check_rounded : Icons.auto_awesome_rounded) : Icons.lock_rounded,
                      size: 19,
                      color: selesai ? AppColors.sukses : AppColors.primer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.s.betterme.levelTitleWithName(level.number, context.s.betterme.level(level.number).judul), style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                        Text(context.s.betterme.sessionsProgress(completedCount, total), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.teksRedup),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(context.s.betterme.level(level.number).deskripsi, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5)),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : completedCount / total,
                  minHeight: 6,
                  backgroundColor: AppColors.latar,
                  valueColor: AlwaysStoppedAnimation(selesai ? AppColors.sukses : AppColors.primer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
