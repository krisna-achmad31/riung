import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/betterme_content.dart';
import '../logic/betterme_progress.dart';
import 'betterme_milestone_screen.dart';
import 'betterme_sesi_selesai_screen.dart';

/// Konten sesi: teks + pertanyaan refleksi + jawaban user. Menyimpan
/// jawaban lokal (bukan lewat `JournalCryptoService` — ini refleksi
/// latihan, bukan jurnal pribadi harian, lihat `LocalPrefsStore`).
class SesiContentScreen extends StatefulWidget {
  const SesiContentScreen({super.key, required this.session});

  final BetterMeSession session;

  @override
  State<SesiContentScreen> createState() => _SesiContentScreenState();
}

class _SesiContentScreenState extends State<SesiContentScreen> {
  late final TextEditingController _controller;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    final saved = BetterMeProgress(AppScope.of(context).prefs).reflectionFor(widget.session.id);
    _controller = TextEditingController(text: saved ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selesai() async {
    setState(() => _menyimpan = true);
    final scope = AppScope.of(context);
    final progress = BetterMeProgress(scope.prefs);
    final sudahSelesaiSebelumnya = progress.isCompleted(widget.session.id);

    await progress.saveReflection(widget.session.id, _controller.text.trim());
    await progress.markCompleted(widget.session.id);
    if (!sudahSelesaiSebelumnya) {
      await scope.wallet.earn(amount: EconomyEarn.betterMeLesson, reason: 'betterme:${widget.session.id}');
    }

    if (!mounted) return;
    final level = betterMeLevels.firstWhere((l) => l.number == widget.session.level);
    final levelSelesai = progress.isLevelComplete(level.number);

    if (levelSelesai) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BetterMeMilestoneScreen(level: level)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BetterMeSesiSelesaiScreen(session: widget.session, sudahDapatKoinSebelumnya: sudahSelesaiSebelumnya)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.betterme;
    final text = t.session(widget.session.id);
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
                  Expanded(child: Text(text.judul, style: AppTextStyles.subtitle.copyWith(fontSize: 15), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 90,
                      height: 94,
                      child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 90, applyBossScale: false),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(text.konten, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.7, color: AppColors.teksUtama)),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.permukaan,
                        border: Border.all(color: AppColors.garis),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text.pertanyaanRefleksi, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, height: 1.5)),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _controller,
                            maxLines: 4,
                            style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: t.reflectionHint,
                              hintStyle: AppTextStyles.caption.copyWith(fontSize: 12),
                              filled: true,
                              fillColor: AppColors.latar,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.garis)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.garis)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primer)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
              child: RiungButton(
                label: _menyimpan ? t.saving : context.s.common.selesai,
                onPressed: _menyimpan ? null : _selesai,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
