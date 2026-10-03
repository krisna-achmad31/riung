import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/check_in.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/checkin_draft.dart';
import '../widgets/checkin_step_header.dart';
import 'checkin_hasil_screen.dart';

/// Langkah 3/3 — catatan singkat opsional. Implement persis
/// `design/Checkin.dc.html` § Catatan singkat.
class CheckInNoteScreen extends StatefulWidget {
  const CheckInNoteScreen({super.key, required this.draft});

  final CheckInDraft draft;

  @override
  State<CheckInNoteScreen> createState() => _CheckInNoteScreenState();
}

class _CheckInNoteScreenState extends State<CheckInNoteScreen> {
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.draft.note);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selesai() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    widget.draft.note = _controller.text.trim();

    final scope = AppScope.of(context);
    final uid = scope.auth.uid;
    if (uid != null) {
      await scope.userRepository.saveCheckIn(
        uid,
        CheckIn(
          date: DateTime.now(),
          mood: widget.draft.moodId ?? '',
          factors: widget.draft.factorIds,
          intention: widget.draft.note,
        ),
      );
      scope.streak.checkInHariIni();
      await scope.wallet.earn(amount: EconomyEarn.checkinHarian, reason: 'daily_checkin');
      await scope.wallet.addTickets(1);
      await scope.analytics.checkinDone(mood: widget.draft.moodId ?? '');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CheckInHasilScreen(draft: widget.draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.checkin;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            CheckInStepHeader(step: 3, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.noteTitle,
                      style: AppTextStyles.display.copyWith(fontSize: 20, height: 1.3),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      constraints: const BoxConstraints(minHeight: 120),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.permukaan,
                        border: Border.all(color: AppColors.primer, width: 1.5),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        cursorColor: AppColors.primer,
                        style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 15, height: 1.65),
                        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final reply in t.quickReplies)
                          GestureDetector(
                            onTap: () {
                              _controller.text = reply;
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: AppColors.garis),
                              ),
                              child: Text(
                                reply,
                                style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(Icons.lock, size: 13, color: AppColors.teksRedup),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            t.noteLock,
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: Column(
                children: [
                  RiungButton(
                    label: _submitting ? t.saving : t.finish,
                    onPressed: _submitting ? null : _selesai,
                  ),
                  TextButton(
                    onPressed: _submitting ? null : _selesai,
                    child: Text(
                      t.skipNote,
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
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
