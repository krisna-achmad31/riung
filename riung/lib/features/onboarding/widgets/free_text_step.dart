import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';
import 'onboarding_header.dart';
import 'onboarding_tag.dart';

/// Jawaban bebas — teks panjang tanpa dinilai. State kosong vs terisi
/// mengubah warna border & tombol Kirim. Implement persis
/// `design/Onboarding.dc.html` § Jawaban bebas.
class FreeTextStep extends StatefulWidget {
  const FreeTextStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  State<FreeTextStep> createState() => _FreeTextStepState();
}

class _FreeTextStepState extends State<FreeTextStep> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.freeText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, AppSpacing.sm, 24, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnboardingHeader(progress: 0.8, onBack: widget.controller.canGoBack ? widget.controller.back : null),
            const SizedBox(height: AppSpacing.md),
            OnboardingTag(t.freeTextTag),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 72, applyBossScale: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.permukaanPadat.withValues(alpha: 0.8),
                      border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomRight: Radius.circular(24), bottomLeft: Radius.circular(6)),
                    ),
                    child: Text(t.freeTextQuestion, style: AppTextStyles.title.copyWith(fontSize: 17, height: 1.3)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.permukaan,
                  border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  cursorColor: AppColors.primer,
                  style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: t.freeTextHint,
                    hintStyle: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.teksRedup),
                  ),
                  onChanged: (value) {
                    widget.controller.setFreeText(value);
                    setState(() {});
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.teksRedup),
                const SizedBox(width: 6),
                Expanded(child: Text(t.freeTextPrivate, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.teksRedup))),
                SizedBox(
                  width: 110,
                  child: RiungButton(label: t.freeTextSend, onPressed: widget.controller.canProceed ? widget.controller.next : null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
