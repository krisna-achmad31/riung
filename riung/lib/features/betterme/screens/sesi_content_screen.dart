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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(title: text.judul),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                  children: [
                    const Center(child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 110, applyBossScale: false)),
                    const SizedBox(height: AppSpacing.md),
                    RiungGlassCard(
                      radius: 30,
                      color: AppColors.permukaan,
                      padding: const EdgeInsets.all(22),
                      child: Text(text.konten, style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    RiungGlassCard(
                      radius: 28,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text.pertanyaanRefleksi, style: AppTextStyles.title.copyWith(fontSize: 18, height: 1.3)),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _controller,
                            minLines: 5,
                            maxLines: 10,
                            cursorColor: AppColors.primer,
                            style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: t.reflectionHint,
                              hintStyle: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.teksRedup),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RiungButton(label: _menyimpan ? t.saving : context.s.common.selesai, onPressed: _menyimpan ? null : _selesai),
            ],
          ),
        ),
      ),
    );
  }
}
