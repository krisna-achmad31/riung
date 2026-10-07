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
    final t = context.s.betterme;
    final next = [for (final l in betterMeLevels) ...l.sessions].where((s) => !progress.isCompleted(s.id)).firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.title),
              Expanded(
                child: ListenableBuilder(
                  listenable: scope.auth,
                  builder: (context, _) {
                    final premiumActive = scope.auth.profile?.premiumNow ?? false;
                    return RiungBleedListView(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
                      children: [
                        Text(t.subtitle, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                        const SizedBox(height: AppSpacing.md),
                        _TotalProgress(
                          done: progress.totalCompleted,
                          total: total,
                          title: t.totalDone(progress.totalCompleted, total),
                          sub: next == null ? null : t.continueWith(t.session(next.id).judul),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final level in betterMeLevels) ...[
                          _LevelCard(
                            level: level,
                            progress: progress,
                            unlocked: progress.isLevelUnlocked(level.number, premiumActive: premiumActive),
                            onTap: () => _bukaLevel(level),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu progres total (frame `Progres total`): cincin + judul + lanjutan.
class _TotalProgress extends StatelessWidget {
  const _TotalProgress({required this.done, required this.total, required this.title, required this.sub});

  final int done;
  final int total;
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.kabutSage, AppColors.kabutLavender]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
        boxShadow: AppGlass.shadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: CircularProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.permukaan,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primer),
                  ),
                ),
                Text('$done/$total', style: AppTextStyles.title.copyWith(fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 16, color: AppColors.teksUtama)),
                if (sub != null) ...[
                  const SizedBox(height: 3),
                  Text(sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu level (frame `Level n`): badge status, judul, daftar sesi bercentang.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.progress, required this.unlocked, required this.onTap});

  final BetterMeLevel level;
  final BetterMeProgress progress;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.betterme;
    final total = level.sessions.length;
    final doneCount = progress.completedInLevel(level.number);
    final selesai = doneCount == total;

    final Widget badge;
    if (!unlocked) {
      badge = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.lock_rounded, size: 16, color: AppColors.teksRedup),
      );
    } else if (selesai) {
      badge = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.primer, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.check_rounded, size: 18, color: AppColors.diAtasTinta),
      );
    } else {
      badge = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.aksenHangatLembut, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: Text('${level.number}', style: AppTextStyles.title.copyWith(fontSize: 16, color: AppColors.aksenHangatGelap)),
      );
    }

    return RiungGlassCard(
      radius: 26,
      color: unlocked ? AppColors.kartu : AppColors.permukaan.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(16),
      onTap: () {
        if (!unlocked) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PremiumLockedScreen(title: t.levelLockedTitle(level.number), freeTierNote: t.levelLockedNote(level.number - 1)),
            ),
          );
          return;
        }
        onTap();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              badge,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.levelTitleWithName(level.number, t.level(level.number).judul), style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                    Text(t.sessionsProgress(doneCount, total), style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!unlocked)
            Text(t.levelLockedNote(level.number - 1), style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4, color: AppColors.teksSekunder))
          else
            for (final session in level.sessions)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(
                      progress.isCompleted(session.id) ? Icons.check_circle_outline_rounded : Icons.circle_outlined,
                      size: 18,
                      color: progress.isCompleted(session.id) ? AppColors.primer : AppColors.teksRedup,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.session(session.id).judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.chipLabel.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: progress.isCompleted(session.id) ? AppColors.teksSekunder : AppColors.teksUtama,
                        ),
                      ),
                    ),
                    Text(t.minutes(session.estimasiMenit), style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
