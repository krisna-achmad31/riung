import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/riung_glass_backdrop.dart';
import '../widgets/riung_tap_origin.dart';
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
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.diAtasTinta,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
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
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primer
              : AppColors.teksRedup.withValues(alpha: 0.35),
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

/// Halaman membesar dari titik yang disentuh, seperti transisi zoom iOS.
/// Usap dari tepi kiri tetap berfungsi: saat itu halaman digeser mengikuti jari.
class _GlassPageTransitionsBuilder extends CupertinoPageTransitionsBuilder {
  const _GlassPageTransitionsBuilder();

  static final _origins = Expando<Offset>();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 340);

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
    final size = MediaQuery.sizeOf(context);
    final origin = _origins[route] ??= RiungTapOrigin.recent ?? size.center(Offset.zero);
    return super.buildTransitions(
      route,
      context,
      _SwipeOnlyAnimation(route, animation),
      const AlwaysStoppedAnimation(0),
      _ZoomFromOrigin(route: route, animation: animation, origin: origin, size: size, child: page),
    );
  }
}

/// Menggerakkan geser Cupertino hanya selama usap kembali berlangsung.
class _SwipeOnlyAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  _SwipeOnlyAnimation(this.route, this.parent);

  final PageRoute<dynamic> route;

  @override
  final Animation<double> parent;

  @override
  double get value => route.popGestureInProgress ? parent.value : 1;
}

class _ZoomFromOrigin extends StatelessWidget {
  const _ZoomFromOrigin({
    required this.route,
    required this.animation,
    required this.origin,
    required this.size,
    required this.child,
  });

  final PageRoute<dynamic> route;
  final Animation<double> animation;
  final Offset origin;
  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutQuart, reverseCurve: Curves.easeInCubic);
    final alignment = Alignment(origin.dx / size.width * 2 - 1, origin.dy / size.height * 2 - 1);
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final t = route.popGestureInProgress ? 1.0 : curved.value;
        return Opacity(
          opacity: (t / 0.3).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.08 + 0.92 * t,
            alignment: alignment,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32 * (1 - t)),
              clipBehavior: t == 1 ? Clip.none : Clip.antiAlias,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
