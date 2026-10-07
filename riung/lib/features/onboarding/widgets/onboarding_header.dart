import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Header langkah onboarding (frame `Header` di Kuis/Cerita/Nama): tombol
/// kembali kaca, bar progres gradien, dan teks kecil di kanan.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, required this.progress, this.onBack, this.trailing});

  final double progress;
  final VoidCallback? onBack;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          if (onBack != null) RiungGlassIconButton(icon: Icons.chevron_left_rounded, onTap: onBack!) else const SizedBox(width: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                heightFactor: 1,
                // Minimal sedikit terisi supaya langkah pertama tetap terlihat maju.
                widthFactor: progress.clamp(0.08, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primerTerang, AppColors.sekunderTerang]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 42,
            child: Text(trailing ?? '', textAlign: TextAlign.right, style: AppTextStyles.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teksSekunder)),
          ),
        ],
      ),
    );
  }
}
