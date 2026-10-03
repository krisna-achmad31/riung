import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: Icon(
              showClose ? Icons.close : Icons.arrow_back,
              color: AppColors.teksSekunder,
              size: showClose ? 20 : 22,
            ),
          ),
          Row(
            children: [
              for (var i = 1; i <= 3; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 22,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    color: i <= step ? AppColors.primer : AppColors.kartu,
                  ),
                ),
            ],
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$step/3',
              textAlign: TextAlign.end,
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
