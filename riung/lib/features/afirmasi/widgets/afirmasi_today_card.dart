import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Kartu "Afirmasi hari ini" di koleksi (frame `Hari ini` di
/// `Glass — Afirmasi · Kategori`): gradien persik→lavender, kutipan besar,
/// ikon afirmasi 3D di kanan.
class AfirmasiTodayCard extends StatelessWidget {
  const AfirmasiTodayCard({
    super.key,
    required this.eyebrow,
    required this.quote,
    required this.meta,
    required this.onTap,
  });

  final String eyebrow;
  final String quote;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 170),
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.aksenHangatLembut, AppColors.kabutLavender],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
          boxShadow: AppGlass.shadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.aksenHangatGelap)),
                  const SizedBox(height: 6),
                  Text(quote, style: AppTextStyles.title.copyWith(fontSize: 19, height: 1.25, color: AppColors.teksUtama)),
                  const SizedBox(height: 6),
                  Text(meta, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                ],
              ),
            ),
            const RiungIcon3D(RiungIcon.afirmasi, size: 120),
          ],
        ),
      ),
    );
  }
}
