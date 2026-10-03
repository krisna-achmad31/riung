import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Penjelasan jujur soal izin "Akses data penggunaan" sebelum membuka
/// Settings Android. Implement persis `design/AppBeku.dc.html` §
/// "Izin akses — penjelasan jujur".
class AppBekuPermissionScreen extends StatefulWidget {
  const AppBekuPermissionScreen({super.key});

  @override
  State<AppBekuPermissionScreen> createState() => _AppBekuPermissionScreenState();
}

class _AppBekuPermissionScreenState extends State<AppBekuPermissionScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static bool _needsUsage(AppBekuNotifier a) => !a.hasUsageAccess;
  static bool _needsAccessibility(AppBekuNotifier a) => a.lockEnabled && !a.hasAccessibilityAccess;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User balik dari Settings Android — cek ulang statusnya, langsung
    // lanjut kalau sudah diizinkan.
    if (state == AppLifecycleState.resumed) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final appBeku = AppScope.of(context).appBeku;
        await appBeku.refreshUsageAccess();
        if (!mounted) return;
        // Izin pertama bisa saja sudah diberikan lalu izin kedua masih
        // kurang — layar ini menyesuaikan diri; tutup hanya kalau semua ada.
        if (!_needsUsage(appBeku) && !_needsAccessibility(appBeku)) {
          Navigator.of(context).maybePop();
        } else {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBeku = AppScope.of(context).appBeku;
    final t = context.s.appbeku;
    final usage = _needsUsage(appBeku);
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
                  ),
                  Text(usage ? t.permissionTitle : t.accessibilityTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 104,
                      height: 109,
                      child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 104),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      usage ? t.permissionHeadline : t.accessibilityHeadline,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display.copyWith(fontSize: 22, height: 1.3),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      usage ? t.permissionBody : t.accessibilityBody,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _InfoCard(
                      title: usage ? t.readTitle : t.accessibilityReadTitle,
                      titleColor: AppColors.sukses,
                      items: [for (final item in (usage ? t.readItems : t.accessibilityReadItems)) (Icons.check_rounded, item)],
                      itemColor: AppColors.sukses,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InfoCard(
                      title: t.cannotSeeTitle,
                      titleColor: AppColors.error,
                      items: [for (final item in (usage ? t.cannotSeeItems : t.accessibilityCannotItems)) (Icons.close_rounded, item)],
                      itemColor: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primer.withValues(alpha: 0.08),
                        border: Border.all(color: AppColors.primer.withValues(alpha: 0.25)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded, size: 17, color: AppColors.primer),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              usage ? t.permissionRevoke : t.accessibilityRevoke,
                              style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
              child: Column(
                children: [
                  RiungButton(
                    label: usage ? t.openAndroidSettings : t.openAccessibilitySettings,
                    onPressed: () => usage ? appBeku.openUsageAccessSettings() : appBeku.openAccessibilitySettings(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(context.s.common.nantiSaja, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.titleColor, required this.items, required this.itemColor});

  final String title;
  final Color titleColor;
  final List<(IconData, String)> items;
  final Color itemColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption.copyWith(color: titleColor, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6)),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$1, size: 15, color: itemColor),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item.$2, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5, color: AppColors.teksSekunder))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
