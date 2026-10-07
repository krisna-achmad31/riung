import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';
import 'onboarding_header.dart';
import 'onboarding_tag.dart';

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, AppSpacing.sm, 24, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnboardingHeader(progress: 0.92, onBack: widget.controller.canGoBack ? widget.controller.back : null),
            const SizedBox(height: AppSpacing.md),
            OnboardingTag(t.nameTag),
            Expanded(
              child: RiungBleedListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  SizedBox(
                    height: 170,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 170,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                        ),
                        const RiungMonster(monsterId: 'cermin', state: MonsterVisualState.jinak, size: 160, applyBossScale: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.nameQuestion, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.permukaanPadat.withValues(alpha: 0.8),
                      border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      cursorColor: AppColors.primer,
                      style: AppTextStyles.display.copyWith(fontSize: 22, color: AppColors.teksUtama),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (value) {
                        widget.controller.setNama(value);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(t.nameHint, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.teksRedup)),
                ],
              ),
            ),
            RiungButton(label: context.s.common.lanjut, onPressed: widget.controller.canProceed ? widget.controller.next : null),
          ],
        ),
      ),
    );
  }
}
