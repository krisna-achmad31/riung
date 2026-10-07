import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Tag kategori (frame `Tag`): pil kaca kecil, huruf besar primer.
class OnboardingTag extends StatelessWidget {
  const OnboardingTag(this.text, {super.key, this.color = AppColors.primer});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text.toUpperCase(), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: color)),
    );
  }
}
