import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/journal_entry.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
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
      backgroundColor: AppColors.permukaan,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.garis, borderRadius: BorderRadius.circular(AppRadius.pill))),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.wifi_off, size: 22, color: AppColors.error),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.syncFailedTitle, style: AppTextStyles.title.copyWith(fontSize: 16)),
                      Text(t.syncFailedSub, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text.rich(
              TextSpan(
                style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.55),
                children: [
                  TextSpan(text: t.syncFailedPrefix),
                  TextSpan(text: t.syncFailedSafe, style: AppTextStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sukses)),
                  TextSpan(text: t.syncFailedSuffix),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primer,
                  foregroundColor: AppColors.latar,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                child: Text(t.syncFailedOk, style: AppTextStyles.chipLabel.copyWith(color: AppColors.latar, fontSize: 14)),
              ),
            ),
          ],
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
    final formatter = DateFormat('EEEE, d MMMM · HH:mm', context.s.dateLocale);
    final prompt = widget.prompt;

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder)),
                  const Spacer(),
                  Text(t.autoSaved, style: AppTextStyles.caption.copyWith(fontSize: 12)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _sentenceCount > 0 ? _selesai : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _sentenceCount > 0 ? AppColors.primer : AppColors.garis,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(t.done, style: AppTextStyles.chipLabel.copyWith(color: AppColors.latar, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (prompt != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.monsterHakim.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.monsterHakim.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 34, height: 36, child: Icon(Icons.pest_control, size: 20, color: AppColors.monsterHakim)),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45),
                                  children: [
                                    TextSpan(text: t.guidePrefix, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.monsterHakim)),
                                    TextSpan(text: t.prompt(prompt.id).guideQuestion),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(formatter.format(_createdAt), style: AppTextStyles.caption.copyWith(fontSize: 12)),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _controller,
                      maxLines: null,
                      minLines: 8,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.body.copyWith(fontSize: 15, color: AppColors.teksUtama, height: 1.75),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: t.editorHint,
                        hintStyle: AppTextStyles.body.copyWith(fontSize: 15, color: AppColors.teksRedup),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.garis))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(t.moodLabel, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(width: AppSpacing.sm),
                      for (final option in _moods)
                        GestureDetector(
                          onTap: () => setState(() => _mood = option.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Opacity(
                              opacity: _mood == option.id ? 1 : 0.4,
                              child: Text(option.emoji, style: TextStyle(fontSize: _mood == option.id ? 22 : 18)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (prompt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.monsterHakim), borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(t.monsterDetected(context.s.common.monsterName(prompt.monsterId)), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.monsterHakim)),
                      ),
                    ),
                  ],
                  if (prompt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.monsterMarked(context.s.common.monsterName(prompt.monsterId)),
                      style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
