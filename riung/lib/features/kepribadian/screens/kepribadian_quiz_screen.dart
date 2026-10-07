import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/personality_result.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/character_avatar.dart';
import '../logic/character_spec.dart';
import '../logic/personality_config.dart';
import '../logic/personality_scoring.dart';
import 'kepribadian_hasil_screen.dart';

/// Satu tes, satu pertanyaan per layar dengan skala setuju 1..5. Jawaban
/// terpilih langsung maju ke pertanyaan berikutnya; bisa kembali mengubah.
/// Hanya skor yang disimpan (bukan jawaban mentah).
class KepribadianQuizScreen extends StatefulWidget {
  const KepribadianQuizScreen({super.key, required this.test});

  final PersonalityTest test;

  @override
  State<KepribadianQuizScreen> createState() => _KepribadianQuizScreenState();
}

class _KepribadianQuizScreenState extends State<KepribadianQuizScreen> {
  late final List<PersonalityQuestion> _questions = PersonalityConfig.questionsFor(widget.test);
  final Map<String, int> _answers = {};
  int _index = 0;

  bool get _last => _index == _questions.length - 1;
  bool get _answeredCurrent => _answers[_questions[_index].id] != null;

  void _answer(int value) {
    setState(() => _answers[_questions[_index].id] = value);
    if (!_last) {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted && _index < _questions.length - 1) setState(() => _index++);
      });
    }
  }

  Future<void> _selesai() async {
    if (!PersonalityScoring.isComplete(widget.test, _answers)) return;
    final scope = AppScope.of(context);
    final result = PersonalityScoring.score(widget.test, _answers);
    await scope.prefs.setPersonalityResult(result);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => KepribadianHasilScreen(result: result)));
  }

  Future<void> _konfirmasiKeluar() async {
    if (_answers.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final t = context.s.kepribadian;
    final keluar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.permukaan,
        title: Text(t.exitTitle, style: AppTextStyles.title.copyWith(fontSize: 17)),
        content: Text(t.exitBody, style: AppTextStyles.body.copyWith(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(dialogContext.s.common.batal)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(dialogContext.s.common.keluar)),
        ],
      ),
    );
    if (keluar == true && mounted) Navigator.of(context).pop();
  }

  /// Karakter ilustrasi per tes (sama dengan contoh di hub).
  static CharacterSpec _illustration(PersonalityTest test) => switch (test) {
        PersonalityTest.jung => CharacterSpec.jung('INFP'),
        PersonalityTest.temperament => CharacterSpec.temperament('melankolis'),
        PersonalityTest.attachment => CharacterSpec.attachment('aman'),
      };

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    final q = _questions[_index];
    final selected = _answers[q.id];
    final progress = (_index + (_answeredCurrent ? 1 : 0)) / _questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _konfirmasiKeluar();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    RiungGlassIconButton(icon: Icons.close_rounded, onTap: _konfirmasiKeluar),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(4)),
                        alignment: Alignment.centerLeft,
                        child: AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 220),
                          widthFactor: progress.clamp(0.02, 1.0),
                          child: DecoratedBox(decoration: BoxDecoration(color: AppColors.sekunder, borderRadius: BorderRadius.circular(4))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(t.progress(_index + 1, _questions.length), style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksSekunder)),
                  ],
                ),
                Expanded(
                  child: RiungBleedListView(
                    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                    children: [
                      Center(child: CharacterAvatar(spec: _illustration(widget.test), size: 140)),
                      const SizedBox(height: AppSpacing.md),
                      RiungGlassCard(
                        radius: 30,
                        color: AppColors.permukaan,
                        padding: const EdgeInsets.all(22),
                        child: Text(t.question(q.id), textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 20, height: 1.3)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (var v = PersonalityConfig.scaleMin; v <= PersonalityConfig.scaleMax; v++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RiungScaleOption(
                            label: t.scaleLabels[v - PersonalityConfig.scaleMin],
                            selected: selected == v,
                            onTap: () => _answer(v),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: RiungButton(
                        label: t.previous,
                        variant: RiungButtonVariant.secondary,
                        onPressed: _index > 0 ? () => setState(() => _index--) : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _last
                          ? RiungButton(label: t.finish, onPressed: PersonalityScoring.isComplete(widget.test, _answers) ? _selesai : null)
                          : RiungButton(label: context.s.common.lanjut, onPressed: selected == null ? null : () => setState(() => _index++)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
