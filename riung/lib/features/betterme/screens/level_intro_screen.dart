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
    final selanjutnya = level.sessions.firstWhere((s) => !progress.isCompleted(s.id), orElse: () => level.sessions.first);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(title: t.levelName(level.number)),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                  children: [
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.sekunderLembut, AppColors.kabutSage]),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                        boxShadow: AppGlass.shadow,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                          ),
                          const RiungIcon3D(RiungIcon.kepribadian, size: 170),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.level(level.number).judul, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.2)),
                    const SizedBox(height: 6),
                    Text(t.level(level.number).deskripsi, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _MetaChip(label: t.sessionCount(level.sessions.length)),
                        const SizedBox(width: 8),
                        _MetaChip(label: t.totalMinutes(totalMenit)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < level.sessions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _SessionRow(index: i + 1, session: level.sessions[i], done: progress.isCompleted(level.sessions[i].id), onTap: () => _bukaSesi(level.sessions[i])),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RiungButton(
                label: progress.completedInLevel(level.number) == 0 ? t.startLevel : t.continueWith(t.session(selanjutnya.id).judul),
                onPressed: () => _bukaSesi(selanjutnya),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksUtama)),
        ],
      ),
    );
  }
}

/// Baris sesi (frame `Sesi …`): kotak nomor / centang, judul, menit · tipe.
class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.index, required this.session, required this.done, required this.onTap});
  final int index;
  final BetterMeSession session;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.betterme;
    return RiungGlassCard(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: done ? AppColors.primer : AppColors.primerLembut, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: AppColors.diAtasTinta)
                : Text('$index', style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.primer)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.session(session.id).judul, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                Text('${t.minutes(session.estimasiMenit)} · ${t.typeLabel(session.tipe.name)}', style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
