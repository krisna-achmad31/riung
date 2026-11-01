import 'package:flutter/material.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/installed_app.dart';
import '../../../core/services/app_usage_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/app_tile.dart';

/// Pilih aplikasi di luar katalog. Aplikasi yang dilindungi tetap terlihat,
/// redup dan tidak bisa dipilih, dengan alasannya.
class AppBekuPickerScreen extends StatefulWidget {
  const AppBekuPickerScreen({super.key, required this.alreadyListed});

  final Set<String> alreadyListed;

  @override
  State<AppBekuPickerScreen> createState() => _AppBekuPickerScreenState();
}

class _AppBekuPickerScreenState extends State<AppBekuPickerScreen> {
  List<InstalledApp>? _apps;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await AppUsageService().getInstalledApps();
    if (!mounted) return;
    setState(() {
      _apps = apps?.where((a) => !widget.alreadyListed.contains(a.packageName)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.appbeku;
    final q = _query.trim().toLowerCase();
    final shown = (_apps ?? const <InstalledApp>[]).where((a) => a.name.toLowerCase().contains(q)).toList();
    final ordered = [...shown.where((a) => !a.isProtected), ...shown.where((a) => a.isProtected)];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.pickAppTitle),
              const SizedBox(height: AppSpacing.md),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(hintText: t.searchAppHint, prefixIcon: const Icon(Icons.search_rounded)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _loading
                    ? const RiungSkeletonList()
                    : ordered.isEmpty
                        ? Center(child: Text(_apps == null ? t.appsLoadFailed : t.noAppsFound, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.teksSekunder)))
                        : ListView.builder(
                            itemCount: ordered.length,
                            itemBuilder: (context, i) => _PickerRow(key: ValueKey(ordered[i].packageName), app: ordered[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({super.key, required this.app});

  final InstalledApp app;

  @override
  Widget build(BuildContext context) {
    final entry = AppBekuCatalog.custom(app.packageName, app.name);
    final reason = app.protectedReason;
    return Opacity(
      opacity: reason == null ? 1 : 0.55,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        enabled: reason == null,
        leading: AppTile(entry: entry),
        title: Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
        subtitle: reason == null ? null : Text(context.s.appbeku.protectedAppReason(reason), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
        trailing: reason == null ? null : const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.teksSekunder),
        onTap: reason == null ? () => Navigator.of(context).pop(entry) : null,
      ),
    );
  }
}
