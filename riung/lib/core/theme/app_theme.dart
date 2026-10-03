import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// ThemeData Riung — tema gelap "Twilight Calm", satu-satunya tempat
/// ThemeData dirakit dari token di [AppColors] & [AppTextStyles].
abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.latar,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primer,
        onPrimary: AppColors.latar,
        secondary: AppColors.sekunder,
        onSecondary: AppColors.latar,
        surface: AppColors.permukaan,
        onSurface: AppColors.teksUtama,
        error: AppColors.error,
        onError: AppColors.latar,
      ),
      fontFamily: AppTextStyles.body.fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: AppTextStyles.display,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.subtitle,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.buttonLabel,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.latar,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTextStyles.subtitle,
        iconTheme: const IconThemeData(color: AppColors.teksSekunder),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.garis,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
