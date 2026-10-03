import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// 6 titik indikator PIN — terisi (primer) vs kosong (outline).
class PinDots extends StatelessWidget {
  const PinDots({super.key, this.length = 6, required this.filled});

  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? AppColors.primer : Colors.transparent,
                border: i < filled ? null : Border.all(color: AppColors.garis, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// Numpad 3 kolom (1-9, kosong, 0, backspace) untuk input PIN.
class PinNumpad extends StatelessWidget {
  const PinNumpad({super.key, required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final key in _keys)
          if (key.isEmpty)
            const SizedBox.shrink()
          else
            GestureDetector(
              onTap: () => key == '⌫' ? onBackspace() : onDigit(key),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.permukaan,
                  border: Border.all(color: AppColors.garis),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                alignment: Alignment.center,
                child: Text(
                  key,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 20,
                    color: key == '⌫' ? AppColors.teksRedup : AppColors.teksUtama,
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
