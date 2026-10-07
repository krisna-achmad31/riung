import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Teman kecil di dalam app (bukan monster, bukan karaktermu sendiri) —
/// komponen "Teman" Riung Glass di `design/riung.pen`: avatar bulat gradien
/// sage→lavender berikon burung + balon kaca berisi satu kalimat dorongan.
class RiungOwlTip extends StatelessWidget {
  const RiungOwlTip({super.key, required this.message, this.size = 44});

  final String message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.kabutSage, AppColors.kabutLavender],
            ),
            border: Border.all(color: AppColors.diAtasTinta, width: 2),
            boxShadow: AppGlass.shadow,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.flutter_dash, size: size * 0.55, color: AppColors.primer),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.permukaan,
              border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
              boxShadow: AppGlass.shadow,
            ),
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksUtama),
            ),
          ),
        ),
      ],
    );
  }
}
