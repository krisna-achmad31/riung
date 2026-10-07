import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Grup menu kaca (frame `Menu` / `Grup …` di `design/riung.pen`): kartu
/// kaca berisi baris-baris dengan garis pemisah tipis, plus judul seksi
/// opsional di atasnya ("AKUN", "APLIKASI", …).
class RiungMenuGroup extends StatelessWidget {
  const RiungMenuGroup({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title!.toUpperCase(), style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup)),
          ),
        Container(
          decoration: AppGlass.card(radius: 26),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.garis),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
