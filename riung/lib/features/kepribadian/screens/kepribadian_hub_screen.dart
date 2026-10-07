import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/journal_entry.dart';
import '../../../core/models/personality_result.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
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
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
              child: Column(
                children: [
                  RiungGlassHeader(title: t.title),
                  Expanded(
                    child: RiungBleedListView(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
                      children: [
                        Text(t.subtitle, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
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
                        _SignalsCard(signals: _signals, loading: _loadingSignals, onLoad: _muatPola),
                        const SizedBox(height: AppSpacing.lg),
                        Text(t.disclaimer, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, color: AppColors.teksRedup)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Kartu tes (frame `Tes …`): karakter 3D di kotak kaca, judul, blurb, pil
/// status (hasil / jumlah pertanyaan).
class _TestCard extends StatelessWidget {
  const _TestCard({required this.test, required this.result, required this.onStart, required this.onSee});

  final PersonalityTest test;
  final PersonalityResult? result;
  final VoidCallback onStart;
  final VoidCallback onSee;

  /// Karakter contoh untuk tes yang belum diisi.
  static CharacterSpec _placeholder(PersonalityTest test) => switch (test) {
        PersonalityTest.jung => CharacterSpec.jung('INFP'),
        PersonalityTest.temperament => CharacterSpec.temperament('melankolis'),
        PersonalityTest.attachment => CharacterSpec.attachment('aman'),
      };

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    final done = result != null;
    final spec = done ? CharacterSpec.fromResult(result!) : _placeholder(test);
    String status;
    if (done) {
      status = switch (test) {
        PersonalityTest.jung => '${result!.code} · ${t.jungType(result!.code).name}',
        PersonalityTest.temperament => t.temperament(result!.code).name,
        PersonalityTest.attachment => t.attachment(result!.code).name,
      };
    } else {
      status = '${t.startTest} · ${t.questionCount(PersonalityConfig.questionsFor(test).length)}';
    }

    return RiungGlassCard(
      onTap: done ? onSee : onStart,
      radius: 28,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 93,
            height: 93,
            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(24)),
            alignment: Alignment.center,
            child: Opacity(
              opacity: done ? 1 : 0.55,
              child: CharacterAvatar(spec: spec, size: 78, accessories: done ? AccessoryLoadout(AppScope.of(context).prefs).of(test) : const []),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.testName(test), style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                const SizedBox(height: 4),
                Text(t.testBlurb(test), style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4, color: AppColors.teksSekunder)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(color: done ? AppColors.primerLembut : AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: done ? AppColors.primer : AppColors.teksSekunder),
                        ),
                      ),
                    ),
                    if (done) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onStart,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(t.retake, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu "Pola dari jurnalmu" (frame `Pola jurnal`).
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
    return RiungGlassCard(
      radius: 26,
      color: AppColors.sekunderLembut.withValues(alpha: 0.7),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.signalsTitle, style: AppTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: 8),
          if (s == null)
            GestureDetector(
              onTap: loading ? null : onLoad,
              child: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sekunder))
                  : Text(t.seeResult, style: AppTextStyles.chipLabel.copyWith(color: AppColors.sekunder, fontSize: 13)),
            )
          else if (s.isEmpty)
            Text(t.signalsEmpty, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.45, color: AppColors.teksUtama))
          else
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.sekunder, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(line, style: AppTextStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.teksUtama))),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          Text(t.signalsNote, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}
