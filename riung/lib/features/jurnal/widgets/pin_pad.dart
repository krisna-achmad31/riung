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
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? AppColors.primer : AppColors.permukaan.withValues(alpha: 0.6),
                border: Border.all(color: i < filled ? AppColors.primer : AppColors.teksRedup, width: 1.5),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 4; row++)
          Padding(
            padding: EdgeInsets.only(bottom: row == 3 ? 0 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final key in _keys.sublist(row * 3, row * 3 + 3))
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: key.isEmpty
                        ? null
                        : key == '⌫'
                            ? IconButton(
                                onPressed: onBackspace,
                                icon: const Icon(Icons.backspace_outlined, color: AppColors.teksSekunder),
                              )
                            : GestureDetector(
                                onTap: () => onDigit(key),
                                child: Container(
                                  decoration: AppGlass.card(radius: 36, color: AppColors.permukaan),
                                  alignment: Alignment.center,
                                  child: Text(key, style: AppTextStyles.title.copyWith(fontSize: 26, color: AppColors.teksUtama)),
                                ),
                              ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
