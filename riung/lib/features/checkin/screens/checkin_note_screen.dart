import 'package:flutter/material.dart';

import '../../../core/config/input_limits.dart';
import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/check_in.dart';
import '../../../core/services/api/api_client.dart';
import '../../../core/widgets/api_error_feedback.dart';
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
    try {
      // Tanpa uid tidak ada yang tersimpan — jangan tampilkan hasil palsu.
      if (uid == null) throw StateError('no uid');
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (e is ApiException) {
        showApiError(context, e);
      } else {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(context.s.common.loadFailed)));
      }
      return;
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
      body: SafeArea(
        child: Column(
          children: [
            CheckInStepHeader(step: 3, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
                children: [
                  Text(t.noteTitle, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.15)),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    constraints: const BoxConstraints(minHeight: 220),
                    padding: const EdgeInsets.all(18),
                    decoration: AppGlass.card(radius: 28, color: AppColors.permukaan),
                    child: TextField(
                      controller: _controller,
                      inputFormatters: InputLimits.formatters(InputLimits.checkinCatatan),
                      maxLines: null,
                      cursorColor: AppColors.primer,
                      style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 15, height: 1.55, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(isDense: true, filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final reply in t.quickReplies)
                        RiungFilterChip(
                          label: reply,
                          selected: _controller.text == reply,
                          onTap: () => setState(() => _controller.text = reply),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.kabutSage.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, size: 16, color: AppColors.primer),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t.noteLock, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.primer))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
              child: Column(
                children: [
                  RiungButton(label: _submitting ? t.saving : t.finish, onPressed: _submitting ? null : _selesai),
                  TextButton(
                    onPressed: _submitting ? null : _selesai,
                    child: Text(t.skipNote, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.teksSekunder)),
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
