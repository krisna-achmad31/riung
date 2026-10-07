import 'package:flutter/widgets.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Resep visual kaca Riung Glass (komponen `Kartu Kaca`, `KoinChip`,
/// `Tombol Kaca`, `Tab Bar Kaca` di `design/riung.pen`): isi putih tembus,
/// tepi putih 1.5, bayangan lembut, blur latar 28.
abstract final class AppGlass {
  static const double blur = 28;
  static const double edgeWidth = 1.5;

  static const List<BoxShadow> shadow = [
    BoxShadow(color: AppColors.bayangan, offset: Offset(0, 12), blurRadius: 36),
  ];

  static const List<BoxShadow> inkShadow = [
    BoxShadow(color: AppColors.bayanganTinta, offset: Offset(0, 10), blurRadius: 24),
  ];

  /// Dekorasi kartu kaca standar (radius 28 seperti `Kartu Kaca`).
  static BoxDecoration card({
    double radius = 28,
    Color color = AppColors.kartu,
    bool shadowed = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.garis, width: edgeWidth),
      boxShadow: shadowed ? shadow : null,
    );
  }

  /// Dekorasi pil kaca kuat (chip, tombol kaca).
  static BoxDecoration pill({Color color = AppColors.permukaan}) =>
      card(radius: AppRadius.pill, color: color);

  /// Gradien kabut latar (pendekatan mesh 3×3 `Glass — Beranda`).
  static const LinearGradient backdrop = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.kabutSage,
      AppColors.latar,
      AppColors.kabutLavender,
      AppColors.kabutPersik,
      AppColors.kabutBiru,
    ],
    stops: [0, 0.32, 0.55, 0.78, 1],
  );
}
