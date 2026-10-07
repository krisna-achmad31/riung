import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/riung_glass_backdrop.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// ThemeData Riung — tema terang **Riung Glass 2026**, satu-satunya tempat
/// ThemeData dirakit dari token di [AppColors] & [AppTextStyles].
///
/// Scaffold transparan; latar kabut dipasang per halaman oleh
/// [_GlassPageTransitionsBuilder] supaya transisi antarhalaman tetap rapi.
abstract final class AppTheme {
  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: AppColors.permukaanPadat,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primer,
        onPrimary: AppColors.latar,
        primaryContainer: AppColors.primerLembut,
        onPrimaryContainer: AppColors.primerGelap,
        secondary: AppColors.sekunder,
        onSecondary: AppColors.latar,
        surface: AppColors.permukaanPadat,
        onSurface: AppColors.teksUtama,
        onSurfaceVariant: AppColors.teksSekunder,
        outline: AppColors.teksRedup,
        outlineVariant: AppColors.garis,
        error: AppColors.error,
        onError: AppColors.latar,
      ),
      fontFamily: AppTextStyles.body.fontFamily,
    );

    final sheetShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: AppTextStyles.subtitle,
        iconTheme: const IconThemeData(color: AppColors.teksUtama),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.garis,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.permukaanPadat,
        modalBackgroundColor: AppColors.permukaanPadat,
        surfaceTintColor: Colors.transparent,
        shape: sheetShape,
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.permukaanPadat,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: AppTextStyles.subtitle,
        contentTextStyle: AppTextStyles.body,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.tinta,
        contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.diAtasTinta),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.permukaan,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.teksRedup),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.garis, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.garis, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.primer, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.diAtasTinta),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primer : AppColors.teksRedup.withValues(alpha: 0.35),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primer,
        linearTrackColor: AppColors.kartu,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _GlassPageTransitionsBuilder(),
          TargetPlatform.iOS: _GlassPageTransitionsBuilder(),
          TargetPlatform.windows: _GlassPageTransitionsBuilder(),
          TargetPlatform.linux: _GlassPageTransitionsBuilder(),
          TargetPlatform.macOS: _GlassPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Transisi halaman Riung: halaman baru masuk dengan pudar + naik sedikit
/// (24dp), halaman lama mundur pelan. Ringan — hanya Fade/Slide (tanpa blur
/// atau saveLayer besar). Latar kabut dipasang di belakang tiap halaman,
/// jadi Scaffold transparan tidak pernah tembus ke halaman di bawahnya.
class _GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  const _GlassPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final page = RiungGlassBackdrop(child: child);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return page;
    final masuk = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final mundur = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return SlideTransition(
      position: Tween(begin: Offset.zero, end: const Offset(-0.06, 0)).animate(mundur),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.7, curve: Curves.easeOut)),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.035), end: Offset.zero).animate(masuk),
          child: page,
        ),
      ),
    );
  }
}
