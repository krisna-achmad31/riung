import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Opsi skala kuis/tes (frame `Opsi …`): radio + label; terpilih = tepi lavender.
class RiungScaleOption extends StatelessWidget {
  const RiungScaleOption({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.garis : AppColors.kartu,
            border: Border.all(color: selected ? AppColors.sekunder : AppColors.garis, width: selected ? 2 : 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.sekunder : AppColors.sekunder.withValues(alpha: 0),
                  border: Border.all(color: selected ? AppColors.sekunder : AppColors.teksRedup, width: 1.5),
                ),
                child: selected ? const Icon(Icons.check_rounded, size: 12, color: AppColors.diAtasTinta) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: AppColors.teksUtama)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
