import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/journal_entry.dart';
import '../../../core/models/personality_result.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../jurnal/screens/jurnal_pin_unlock_screen.dart';
import '../logic/character_accessory.dart';
import '../logic/character_spec.dart';
import '../logic/journal_signals.dart';
import '../logic/personality_config.dart';
import '../widgets/character_avatar.dart';
import 'kepribadian_hasil_screen.dart';
import 'kepribadian_quiz_screen.dart';

/// Pintu masuk "Kenali dirimu": tiga tes (16 tipe gaya Jung, empat
/// temperamen, gaya keterikatan), karakter hasilnya, dan pola halus dari
/// jurnal (dibuka lewat PIN jurnal, hanya metadata). Semua alat refleksi,
/// bukan diagnosis.
class KepribadianHubScreen extends StatefulWidget {
  const KepribadianHubScreen({super.key});

  @override
  State<KepribadianHubScreen> createState() => _KepribadianHubScreenState();
}

class _KepribadianHubScreenState extends State<KepribadianHubScreen> {
  JournalSignals? _signals;
  bool _loadingSignals = false;

  Future<void> _bukaTes(PersonalityTest test) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => KepribadianQuizScreen(test: test)));
    if (mounted) setState(() {});
  }

  Future<void> _lihatHasil(PersonalityResult result) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => KepribadianHasilScreen(result: result)));
    if (mounted) setState(() {});
  }

  /// Pola jurnal dibuka lewat PIN jurnal (kalau ada): isi jurnal tidak dibaca,
  /// tapi metadata pun dilindungi kunci yang sama.
  Future<void> _muatPola() async {
    final scope = AppScope.of(context);
    setState(() => _loadingSignals = true);
    try {
      if (await scope.pinService.hasPin) {
        if (!mounted) return;
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const JurnalPinUnlockScreen(), fullscreenDialog: true),
        );
        if (ok != true) return;
      }
      final uid = scope.auth.profile?.uid;
      final entries = uid == null ? <JournalEntry>[] : await scope.userRepository.getJournalEntries(uid);
      if (!mounted) return;
      setState(() => _signals = JournalSignals.from(entries));
    } finally {
      if (mounted) setState(() => _loadingSignals = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    return ValueListenableBuilder<int>(
      valueListenable: AppScope.of(context).prefs.personalityRevision,
      builder: (context, _, _) {
        final results = AppScope.of(context).prefs.personalityResults;
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
                  Text(t.title, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  Text(t.subtitle, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
                  const SizedBox(height: AppSpacing.lg),
                  for (final test in PersonalityTest.values) ...[
                    _TestCard(
                      test: test,
                      result: results[test],
                      onStart: () => _bukaTes(test),
                      onSee: () => _lihatHasil(results[test]!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _SignalsCard(signals: _signals, loading: _loadingSignals, onLoad: _muatPola),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.disclaimer, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.5)),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.test, required this.result, required this.onStart, required this.onSee});

  final PersonalityTest test;
  final PersonalityResult? result;
  final VoidCallback onStart;
  final VoidCallback onSee;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    final done = result != null;
    final spec = done ? CharacterSpec.fromResult(result!) : null;
    String? headline;
    if (done) {
      switch (test) {
        case PersonalityTest.jung:
          headline = '${result!.code} · ${t.jungType(result!.code).name}';
        case PersonalityTest.temperament:
          headline = t.temperament(result!.code).name;
        case PersonalityTest.attachment:
          headline = t.attachment(result!.code).name;
      }
    }

    return GestureDetector(
      onTap: done ? onSee : onStart,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: done ? spec!.base.withValues(alpha: 0.6) : AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: done
                  ? CharacterAvatar(spec: spec!, size: 84, accessories: AccessoryLoadout(AppScope.of(context).prefs).of(test))
                  : Container(
                      decoration: BoxDecoration(color: AppColors.kartu, borderRadius: BorderRadius.circular(22)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.help_outline_rounded, size: 32, color: AppColors.teksRedup),
                    ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.testName(test), style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                  const SizedBox(height: 2),
                  Text(done ? headline! : t.testBlurb(test), style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: done ? spec!.base : AppColors.teksRedup, fontWeight: done ? FontWeight.w700 : FontWeight.w400)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        done ? t.seeResult : '${t.startTest} · ${t.questionCount(PersonalityConfig.questionsFor(test).length)}',
                        style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: AppColors.primer),
                      ),
                      const Spacer(),
                      if (done)
                        GestureDetector(
                          onTap: onStart,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(t.retake, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalsCard extends StatelessWidget {
  const _SignalsCard({required this.signals, required this.loading, required this.onLoad});

  final JournalSignals? signals;
  final bool loading;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    final s = signals;
    final lines = <String>[];
    if (s != null && !s.isEmpty) {
      lines.add(t.signalEntries(s.entryCount));
      if (s.topMood != null) lines.add(t.signalMood(t.moodLabel(s.topMood!)));
      if (s.topPeriod != null) lines.add(t.signalPeriod(t.periodLabel(s.topPeriod!)));
      if (s.topTag != null) lines.add(t.signalMonster(s.topTag!));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.sukses),
              const SizedBox(width: AppSpacing.sm),
              Text(t.signalsTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(t.signalsNote, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.5)),
          const SizedBox(height: AppSpacing.sm),
          if (s == null)
            TextButton(
              onPressed: loading ? null : onLoad,
              child: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primer))
                  : Text(t.seeResult, style: AppTextStyles.chipLabel.copyWith(color: AppColors.primer, fontSize: 13)),
            )
          else if (s.isEmpty)
            Text(t.signalsEmpty, style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.5))
          else
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.primer),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(line, style: AppTextStyles.body.copyWith(fontSize: 13))),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
