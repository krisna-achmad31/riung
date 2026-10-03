import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/betterme_content.dart';
import '../logic/betterme_progress.dart';
import 'sesi_detail_screen.dart';

/// Intro satu level: judul, deskripsi, jumlah sesi, estimasi waktu total.
///
/// StatefulWidget (bukan Stateless) supaya bisa dipaksa baca ulang progres
/// setelah kembali dari sesi — Flutter TIDAK otomatis rebuild route yang
/// di-pop-kembali-ke (widget-nya sudah ada di tree sejak awal, cuma
/// tersembunyi di belakang), jadi centang selesai bakal keliatan basi
/// tanpa `setState` manual di sini.
class LevelIntroScreen extends StatefulWidget {
  const LevelIntroScreen({super.key, required this.level});

  final BetterMeLevel level;

  @override
  State<LevelIntroScreen> createState() => _LevelIntroScreenState();
}

class _LevelIntroScreenState extends State<LevelIntroScreen> {
  Future<void> _bukaSesi(BetterMeSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SesiDetailScreen(session: session)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.betterme;
    final level = widget.level;
    final progress = BetterMeProgress(AppScope.of(context).prefs);
    final totalMenit = level.sessions.fold<int>(0, (sum, s) => sum + s.estimasiMenit);
    final selanjutnya = level.sessions.firstWhere(
      (s) => !progress.isCompleted(s.id),
      orElse: () => level.sessions.first,
    );

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
                  Text(t.levelName(level.number), style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t.level(level.number).judul, style: AppTextStyles.display.copyWith(fontSize: 24)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(t.level(level.number).deskripsi, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.6)),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        _MetaChip(icon: Icons.menu_book_rounded, label: t.sessionCount(level.sessions.length)),
                        const SizedBox(width: AppSpacing.sm),
                        _MetaChip(icon: Icons.schedule_rounded, label: t.totalMinutes(totalMenit)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    for (final session in level.sessions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _SessionRow(
                          session: session,
                          done: progress.isCompleted(session.id),
                          onTap: () => _bukaSesi(session),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
              child: RiungButton(
                label: progress.completedInLevel(level.number) == 0 ? t.startLevel : t.continueWith(t.session(selanjutnya.id).judul),
                onPressed: () => _bukaSesi(selanjutnya),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: AppColors.kartu, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.teksSekunder),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.done, required this.onTap});
  final BetterMeSession session;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(done ? Icons.check_circle_rounded : Icons.circle_outlined, size: 18, color: done ? AppColors.sukses : AppColors.teksRedup),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(context.s.betterme.session(session.id).judul, style: AppTextStyles.chipLabel.copyWith(fontSize: 13))),
            Text(context.s.betterme.minutes(session.estimasiMenit), style: AppTextStyles.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
