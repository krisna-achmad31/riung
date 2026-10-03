import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/personality_result.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    final q = _questions[_index];
    final selected = _answers[q.id];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _konfirmasiKeluar();
      },
      child: Scaffold(
        backgroundColor: AppColors.latar,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    IconButton(onPressed: _konfirmasiKeluar, icon: const Icon(Icons.close, color: AppColors.teksSekunder)),
                    Expanded(
                      child: Text(t.testName(widget.test), textAlign: TextAlign.center, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: (_index + (_answeredCurrent ? 1 : 0)) / _questions.length,
                        minHeight: 5,
                        backgroundColor: AppColors.kartu,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primer),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(t.progress(_index + 1, _questions.length), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.question(q.id), style: AppTextStyles.display.copyWith(fontSize: 21, height: 1.4)),
                      const SizedBox(height: AppSpacing.xl),
                      for (var v = PersonalityConfig.scaleMin; v <= PersonalityConfig.scaleMax; v++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ScaleOption(
                            label: t.scaleLabels[v - PersonalityConfig.scaleMin],
                            selected: selected == v,
                            onTap: () => _answer(v),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                child: Row(
                  children: [
                    if (_index > 0)
                      TextButton(
                        onPressed: () => setState(() => _index--),
                        child: Text(t.previous, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
                      ),
                    const Spacer(),
                    if (_last)
                      SizedBox(
                        width: 190,
                        child: RiungButton(label: t.finish, onPressed: PersonalityScoring.isComplete(widget.test, _answers) ? _selesai : null),
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

class _ScaleOption extends StatelessWidget {
  const _ScaleOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primer.withValues(alpha: 0.14) : AppColors.permukaan,
          border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18, color: selected ? AppColors.primer : AppColors.teksRedup),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: selected ? AppColors.teksUtama : AppColors.teksSekunder))),
          ],
        ),
      ),
    );
  }
}
