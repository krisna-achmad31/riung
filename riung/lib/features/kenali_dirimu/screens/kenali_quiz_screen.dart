import 'package:flutter/material.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/kenali_test.dart';
import '../../../core/models/personality_result.dart';
import '../../../core/services/kenali_result_repository.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../kepribadian/logic/character_spec.dart';
import '../../kepribadian/widgets/character_avatar.dart';
import '../logic/kenali_navigator.dart';
import '../logic/kenali_progress.dart';
import '../logic/kenali_scoring.dart';

/// Soal satu per layar (frame `Glass — Kenali Dirimu · Soal`): progres
/// "8 dari 24", kicker judul tes, karakter pendamping, opsi dari JSON.
/// Jawaban mentah TIDAK disimpan — hanya hasil skor (terenkripsi).
class KenaliQuizScreen extends StatefulWidget {
  const KenaliQuizScreen({super.key, required this.entry, required this.test});

  final KenaliEntry entry;
  final KenaliTest test;

  @override
  State<KenaliQuizScreen> createState() => _KenaliQuizScreenState();
}

class _KenaliQuizScreenState extends State<KenaliQuizScreen> {
  final Map<String, int> _answers = {};
  int _index = 0;
  bool _saving = false;

  List<KenaliQuestion> get _questions => widget.test.questions;
  bool get _last => _index == _questions.length - 1;

  void _answer(int position) {
    setState(() => _answers[_questions[_index].id] = position);
    if (!_last) {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted && _index < _questions.length - 1) setState(() => _index++);
      });
    }
  }

  Future<void> _selesai() async {
    if (_saving || !KenaliScoring.isComplete(widget.test, _answers)) return;
    setState(() => _saving = true);
    final scope = AppScope.of(context);
    final result = KenaliScoring.score(widget.test, _answers);
    await KenaliResultRepository.instance.save(scope.prefs, result);
    final woke = KenaliProgress.monsterOf(widget.entry, result);
    if (woke != null && widget.entry.wakesMonster) scope.monsterProgress.ensureAllSaboteurs([woke]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => KenaliNavigator.resultScreen(widget.entry, widget.test, result)));
  }

  Future<void> _konfirmasiKeluar() async {
    if (_answers.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final t = context.s.kenali;
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

  /// Label opsi dalam huruf kalimat ("Tidak pernah", bukan "Tidak Pernah").
  static String _sentenceCase(String label) => label.isEmpty ? label : label[0].toUpperCase() + label.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    final q = _questions[_index];
    final selected = _answers[q.id];
    final answered = selected != null;
    final progress = (_index + (answered ? 1 : 0)) / _questions.length;
    final jung = AppScope.of(context).prefs.personalityResults[PersonalityTest.jung];

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
                    Expanded(child: RiungProgressBar(value: progress.clamp(0.02, 1.0), height: 8, colors: const [AppColors.sekunder, AppColors.sekunder])),
                    const SizedBox(width: 12),
                    Text(t.progress(_index + 1, _questions.length), style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksSekunder)),
                  ],
                ),
                Expanded(
                  child: RiungBleedListView(
                    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                    children: [
                      Center(child: CharacterAvatar(spec: jung == null ? CharacterSpec.jung('INFP') : CharacterSpec.fromResult(jung), size: 120)),
                      const SizedBox(height: AppSpacing.md),
                      RiungGlassCard(
                        radius: 30,
                        color: AppColors.permukaan,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            Text(
                              t.entryTitle(widget.entry.id).toUpperCase(),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup),
                            ),
                            const SizedBox(height: 8),
                            Text(q.text, textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 19, height: 1.3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (var i = 0; i < widget.test.options.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RiungScaleOption(
                            label: _sentenceCase(widget.test.options[i].label),
                            selected: selected == i,
                            onTap: () => _answer(i),
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
                          ? RiungButton(label: t.finish, onPressed: KenaliScoring.isComplete(widget.test, _answers) && !_saving ? _selesai : null)
                          : RiungButton(label: context.s.common.lanjut, onPressed: answered ? () => setState(() => _index++) : null),
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
