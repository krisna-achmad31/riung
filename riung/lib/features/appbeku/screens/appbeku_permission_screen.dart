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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(title: usage ? t.permissionTitle : t.accessibilityTitle),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                  children: [
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.permukaan,
                          border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                          boxShadow: AppGlass.shadow,
                        ),
                        child: Icon(usage ? Icons.bar_chart_rounded : Icons.lock_outline_rounded, size: 48, color: usage ? AppColors.langit : AppColors.sekunder),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(usage ? t.permissionHeadline : t.accessibilityHeadline, style: AppTextStyles.display.copyWith(fontSize: 22, height: 1.2)),
                    const SizedBox(height: AppSpacing.md),
                    Text(usage ? t.permissionBody : t.accessibilityBody, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.md),
                    _InfoCard(
                      title: usage ? t.readTitle : t.accessibilityReadTitle,
                      color: AppColors.primer,
                      icon: Icons.visibility_outlined,
                      items: usage ? t.readItems : t.accessibilityReadItems,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InfoCard(
                      title: t.cannotSeeTitle,
                      color: AppColors.aksenHangatGelap,
                      icon: Icons.visibility_off_outlined,
                      items: usage ? t.cannotSeeItems : t.accessibilityCannotItems,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(usage ? t.permissionRevoke : t.accessibilityRevoke, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksRedup)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RiungButton(
                label: usage ? t.openAndroidSettings : t.openAccessibilitySettings,
                onPressed: () => usage ? appBeku.openUsageAccessSettings() : appBeku.openAccessibilitySettings(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu "yang Riung baca / nggak bisa lihat" (frame `YANG RIUNG …`).
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.color, required this.icon, required this.items});

  final String title;
  final Color color;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5)),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 16, color: color)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksUtama))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
