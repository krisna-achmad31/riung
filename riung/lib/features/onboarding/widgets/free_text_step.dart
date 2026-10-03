import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';

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
    final terisi = _textController.text.trim().isNotEmpty;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                if (widget.controller.canGoBack)
                  IconButton(
                    onPressed: widget.controller.back,
                    icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: const LinearProgressIndicator(
                      value: 0.98,
                      minHeight: 8,
                      backgroundColor: AppColors.kartu,
                      valueColor: AlwaysStoppedAnimation(AppColors.primer),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.freeTextQuestion,
                    style: AppTextStyles.display.copyWith(fontSize: 23, height: 1.3),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.permukaan,
                        border: Border.all(color: terisi ? AppColors.primer : AppColors.garis, width: 1.5),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        cursorColor: AppColors.primer,
                        style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 15),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: t.freeTextHint,
                          hintStyle: AppTextStyles.body.copyWith(fontSize: 15),
                        ),
                        onChanged: (value) {
                          widget.controller.setFreeText(value);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
            child: RiungButton(
              label: t.freeTextSend,
              onPressed: widget.controller.canProceed ? widget.controller.next : null,
            ),
          ),
        ],
      ),
    );
  }
}
