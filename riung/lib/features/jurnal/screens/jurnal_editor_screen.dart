import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/journal_entry.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/journal_prompts.dart';
import 'jurnal_simpan_screen.dart';

class _MoodOption {
  const _MoodOption(this.id, this.emoji);
  final String id;
  final String emoji;
}

const _moods = [
  _MoodOption('berat', '😞'),
  _MoodOption('agak_berat', '😕'),
  _MoodOption('datar', '😟'),
  _MoodOption('cukup_baik', '🙂'),
  _MoodOption('senang', '😄'),
];

/// Menulis entri jurnal — otomatis tersimpan sebagai draf lokal, mood
/// picker, deteksi monster dari prompt CBT. Implement persis
/// `design/Jurnal.dc.html` § Menulis jurnal & § Jurnal gagal simpan.
class JurnalEditorScreen extends StatefulWidget {
  const JurnalEditorScreen({super.key, this.prompt});

  final JournalPrompt? prompt;

  @override
  State<JurnalEditorScreen> createState() => _JurnalEditorScreenState();
}

class _JurnalEditorScreenState extends State<JurnalEditorScreen> {
  final _controller = TextEditingController();
  final _createdAt = DateTime.now();
  String _mood = 'datar';
  static const _uuid = Uuid();

  bool get _isCbt => widget.prompt != null;

  int get _sentenceCount {
    final text = _controller.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'[.!?\n]+')).where((s) => s.trim().isNotEmpty).length;
  }

  Future<void> _selesai() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final scope = AppScope.of(context);
    final uid = scope.auth.profile?.uid;
    if (uid == null) return;

    final entry = JournalEntry(
      entryId: _uuid.v4(),
      promptId: widget.prompt?.id ?? '',
      mood: _mood,
      text: text,
      tags: _isCbt ? [scope.language.strings.common.monsterName(widget.prompt!.monsterId)] : const [],
      createdAt: _createdAt,
    );

    try {
      await scope.userRepository.saveJournalEntry(uid, entry);
      await scope.wallet.earn(amount: EconomyEarn.jurnal, reason: 'jurnal:${entry.entryId}');
      await scope.wallet.addTickets(1);
      if (_isCbt) {
        await scope.monsterProgress.tambahProgres(saboteurId: widget.prompt!.monsterId, delta: 2);
      }
      if (!mounted) return;
      final backOk = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => JurnalSimpanScreen(prompt: widget.prompt)),
      );
      if (!mounted) return;
      Navigator.of(context).pop(backOk ?? true);
    } catch (_) {
      if (!mounted) return;
      _showGagalSimpanSheet(scope.language.strings.jurnal);
    }
  }

  void _showGagalSimpanSheet(JurnalStrings t) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: AppGlass.card(radius: 55, color: AppColors.permukaan),
                child: const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.langit),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.langitLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(t.syncFailedTitle, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.langit)),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(t.syncFailedSub, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
              const SizedBox(height: AppSpacing.md),
              Text.rich(
                TextSpan(
                  style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, color: AppColors.teksSekunder),
                  children: [
                    TextSpan(text: t.syncFailedPrefix),
                    TextSpan(text: t.syncFailedSafe, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primer)),
                    TextSpan(text: t.syncFailedSuffix),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              RiungButton(label: t.syncFailedOk, onPressed: () => Navigator.of(sheetContext).pop()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.jurnal;
    final formatter = DateFormat('EEEE, d MMMM · HH.mm', context.s.dateLocale);
    final prompt = widget.prompt;
    final canFinish = _sentenceCount > 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    RiungGlassIconButton(icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).maybePop()),
                    const Spacer(),
                    GestureDetector(
                      onTap: canFinish ? _selesai : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: canFinish ? AppColors.tinta : AppColors.kartu, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        alignment: Alignment.center,
                        child: Text(t.done, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: canFinish ? AppColors.diAtasTinta : AppColors.teksRedup)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (prompt != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppGlass.card(radius: 22, color: (AppColors.monsterLembut[prompt.monsterId] ?? AppColors.sekunderLembut).withValues(alpha: 0.7), shadowed: false),
                  child: Row(
                    children: [
                      RiungMonster(monsterId: prompt.monsterId, state: MonsterVisualState.jinak, size: 48, applyBossScale: false),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.guidePrefix}${t.prompt(prompt.id).title}', style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sekunder)),
                            const SizedBox(height: 2),
                            Text(t.prompt(prompt.id).guideQuestion, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  Text(t.moodLabel, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teksRedup)),
                  const SizedBox(width: 8),
                  for (final option in _moods)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _mood = option.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _mood == option.id ? AppColors.garis : AppColors.kartu,
                            shape: BoxShape.circle,
                            border: Border.all(color: _mood == option.id ? AppColors.primer : AppColors.garis, width: _mood == option.id ? 2 : 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(option.emoji, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  decoration: AppGlass.card(radius: 28, color: AppColors.permukaan),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatter.format(_createdAt), style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksRedup)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          expands: true,
                          autofocus: true,
                          textAlignVertical: TextAlignVertical.top,
                          onChanged: (_) => setState(() {}),
                          style: AppTextStyles.body.copyWith(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500, color: AppColors.teksUtama),
                          cursorColor: AppColors.primer,
                          decoration: InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: t.editorHint,
                            hintStyle: AppTextStyles.body.copyWith(fontSize: 15, color: AppColors.teksRedup),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (prompt != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.sekunderLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(
                        t.monsterDetected(context.s.common.monsterName(prompt.monsterId)),
                        style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sekunder),
                      ),
                    ),
                  const Spacer(),
                  Text(t.autoSaved, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primer)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
