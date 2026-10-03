import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';

/// Input nama panggilan — layar terakhir sebelum analisis. Implement
/// persis `design/Onboarding.dc.html` § Nama.
class NamaStep extends StatefulWidget {
  const NamaStep({super.key, required this.controller});

  final OnboardingController controller;

  @override
  State<NamaStep> createState() => _NamaStepState();
}

class _NamaStepState extends State<NamaStep> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.nama);
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 88,
              height: 92,
              child: RiungMonster(monsterId: 'mengelak', state: MonsterVisualState.jinak, size: 88),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              t.nameQuestion,
              style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.permukaan,
                border: Border.all(color: terisi ? AppColors.primer : AppColors.garis, width: 1.5),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: TextField(
                controller: _textController,
                autofocus: true,
                cursorColor: AppColors.primer,
                style: AppTextStyles.subtitle.copyWith(color: AppColors.teksUtama, fontSize: 16),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: t.nameHint,
                  hintStyle: AppTextStyles.subtitle.copyWith(color: AppColors.teksRedup, fontSize: 16),
                ),
                onChanged: (value) {
                  widget.controller.setNama(value);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RiungButton(
              label: context.s.common.simpan,
              onPressed: widget.controller.canProceed ? widget.controller.next : null,
            ),
          ],
        ),
      ),
    );
  }
}
