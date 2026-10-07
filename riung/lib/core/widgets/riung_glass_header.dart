import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'riung_glass_icon_button.dart';

/// Header layar Riung Glass: tombol kembali bulat kaca 44dp di kiri, judul
/// di tengah, ruang kosong seimbang (atau [trailing]) di kanan — frame
/// `Header` di `design/riung.pen`.
class RiungGlassHeader extends StatelessWidget {
  const RiungGlassHeader({super.key, required this.title, this.subtitle, this.onBack, this.trailing, this.night = false});

  final String title;

  /// Baris kecil di bawah judul (mis. `Afirmasi` · "Kalimat kecil…").
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Varian malam (alur Tidur).
  final bool night;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          RiungGlassIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
            night: night,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitle == null
                      ? AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700, color: night ? AppNight.teks : AppColors.teksUtama)
                      : AppTextStyles.title.copyWith(fontSize: 18, height: 1.2, color: night ? AppNight.teks : AppColors.teksUtama),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(fontSize: 11, color: night ? AppNight.teksSekunder : AppColors.teksSekunder),
                  ),
              ],
            ),
          ),
          // Trailing boleh lebih lebar dari 44 (mis. chip koin di Toko).
          if (trailing == null) const SizedBox(width: 44, height: 44) else ConstrainedBox(constraints: const BoxConstraints(minWidth: 44), child: Center(child: trailing)),
        ],
      ),
    );
  }
}
