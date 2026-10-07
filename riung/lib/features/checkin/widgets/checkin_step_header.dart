import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Header 3 langkah wizard check-in — ikon kembali/tutup, 3 titik progres,
/// label "n/3". Dipakai di ketiga layar pertanyaan check-in.
class CheckInStepHeader extends StatelessWidget {
  const CheckInStepHeader({super.key, required this.step, this.showClose = false, this.onBack});

  final int step;
  final bool showClose;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            RiungGlassIconButton(
              icon: showClose ? Icons.close_rounded : Icons.chevron_left_rounded,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == step ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i <= step ? AppColors.primer : AppColors.permukaan,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}
