import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'appbeku_permission_screen.dart';

const _tiers = [15, 30, 60];

/// Pilih aplikasi yang dibekukan + batas harian per aplikasi. Implement
/// persis `design/AppBeku.dc.html` § "Pilih aplikasi yang dibekukan" —
/// tapi diterapkan seragam ke semua aplikasi katalog (mockup cuma
/// menghias Instagram sebagai contoh kartu terbuka; di sini kartu mana
/// pun yang aktif menampilkan pemilih batas yang sama).
class AppBekuSetupScreen extends StatefulWidget {
  const AppBekuSetupScreen({super.key});

  @override
  State<AppBekuSetupScreen> createState() => _AppBekuSetupScreenState();
}

class _AppBekuSetupScreenState extends State<AppBekuSetupScreen> {
  late Map<String, ({bool enabled, int limit})> _draft;

  @override
  void initState() {
    super.initState();
    final existing = AppScope.of(context).appBeku.frozenApps;
    _draft = {
      for (final app in AppBekuCatalog.semua)
        app.packageName: (
          enabled: existing[app.packageName]?.enabled ?? false,
          limit: existing[app.packageName]?.dailyLimitMinutes ?? 30,
        ),
    };
  }

  Future<void> _simpan() async {
    final appBeku = AppScope.of(context).appBeku;
    for (final app in AppBekuCatalog.semua) {
      final draft = _draft[app.packageName]!;
      await appBeku.setFrozenApp(app, limitMinutes: draft.limit, enabled: draft.enabled);
    }
    // Fix 2: minta izin notifikasi (Android 13+ POST_NOTIFICATIONS) saat
    // setup AppBeku, supaya notifikasi limit-tercapai bisa muncul —
    // best-effort, tidak memblokir alur kalau ditolak (mirip
    // IzinNotifikasiScreen saat onboarding).
    await Permission.notification.request();
    if (!mounted) return;
    await appBeku.refreshUsageAccess();
    if (!mounted) return;
    if (appBeku.hasUsageAccess && (!appBeku.lockEnabled || appBeku.hasAccessibilityAccess)) {
      Navigator.of(context).maybePop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppBekuPermissionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.appbeku;
    final jumlahAktif = _draft.values.where((d) => d.enabled).length;
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
                  Text(t.title, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.setupHeadline,
                      style: AppTextStyles.display.copyWith(fontSize: 21, height: 1.3),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.setupBody,
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _LockToggleCard(),
                    const SizedBox(height: AppSpacing.md),
                    for (final app in AppBekuCatalog.semua) ...[
                      _AppRow(
                        entry: app,
                        enabled: _draft[app.packageName]!.enabled,
                        limit: _draft[app.packageName]!.limit,
                        onToggle: (value) => setState(() => _draft[app.packageName] = (enabled: value, limit: _draft[app.packageName]!.limit)),
                        onLimitChanged: (value) => setState(() => _draft[app.packageName] = (enabled: true, limit: value)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.latar,
                        border: Border.all(color: AppColors.garis, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Opacity(
                        opacity: 0.75,
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.sukses.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                AppBekuCatalog.whatsapp.tile,
                                style: AppTextStyles.chipLabel.copyWith(color: AppColors.sukses, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppBekuCatalog.whatsapp.name, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                                  Text(
                                    t.whatsappNote,
                                    style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
              child: Column(
                children: [
                  RiungButton(
                    label: jumlahAktif == 0 ? t.pickAtLeastOne : t.freezeCount(jumlahAktif),
                    onPressed: jumlahAktif == 0 ? null : _simpan,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.footerNote,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
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

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.entry,
    required this.enabled,
    required this.limit,
    required this.onToggle,
    required this.onLimitChanged,
  });

  final AppBekuCatalogEntry entry;
  final bool enabled;
  final int limit;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onLimitChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: enabled ? AppColors.sekunder : AppColors.garis, width: enabled ? 1.5 : 1),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: entry.tileColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(entry.tile, style: AppTextStyles.chipLabel.copyWith(color: entry.tileColor, fontSize: 13)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                    Text(context.s.appbeku.appUsageAverage(entry.avgMinutesPerDay ?? 0), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: AppColors.latar,
                activeTrackColor: AppColors.sekunder,
                inactiveThumbColor: AppColors.teksRedup,
                inactiveTrackColor: AppColors.kartu,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(context.s.appbeku.dailyLimit, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                const SizedBox(width: AppSpacing.sm),
                for (final tier in _tiers) ...[
                  GestureDetector(
                    onTap: () => onLimitChanged(tier),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                      decoration: BoxDecoration(
                        color: limit == tier ? AppColors.sekunder : Colors.transparent,
                        border: Border.all(color: limit == tier ? AppColors.sekunder : AppColors.garis, width: 1.5),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        context.s.appbeku.minutesShort(tier),
                        style: AppTextStyles.chipLabel.copyWith(
                          color: limit == tier ? AppColors.latar : AppColors.teksSekunder,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Saklar kunci/buka: kunci = aplikasi yang melewati batas ditutup Riung;
/// buka (mati) = Riung cuma mengingatkan. Berlaku langsung, tidak menunggu
/// tombol "Bekukan". Menyalakannya tanpa izin tambahan mengarahkan ke layar
/// izin.
class _LockToggleCard extends StatelessWidget {
  const _LockToggleCard();

  @override
  Widget build(BuildContext context) {
    final appBeku = AppScope.of(context).appBeku;
    final t = context.s.appbeku;
    return ListenableBuilder(
      listenable: appBeku,
      builder: (context, _) {
        final on = appBeku.lockEnabled;
        final missing = on && (!appBeku.hasUsageAccess || !appBeku.hasAccessibilityAccess);
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.permukaan,
            border: Border.all(color: on ? AppColors.primer : AppColors.garis, width: on ? 1.5 : 1),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(on ? Icons.lock_rounded : Icons.lock_open_rounded, size: 20, color: on ? AppColors.primer : AppColors.teksRedup),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(t.lockTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 14))),
                  Switch(
                    value: on,
                    onChanged: (value) async {
                      await appBeku.setLockEnabled(value);
                      if (value && context.mounted && (!appBeku.hasUsageAccess || !appBeku.hasAccessibilityAccess)) {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppBekuPermissionScreen()));
                        await appBeku.refreshUsageAccess();
                      }
                    },
                    activeThumbColor: AppColors.latar,
                    activeTrackColor: AppColors.primer,
                    inactiveThumbColor: AppColors.teksRedup,
                    inactiveTrackColor: AppColors.kartu,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(on ? t.lockOnBody : t.lockOffBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5)),
              if (missing) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.peringatan),
                    const SizedBox(width: 6),
                    Expanded(child: Text(t.lockNeedsPermission, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.peringatan))),
                    TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppBekuPermissionScreen()));
                        await appBeku.refreshUsageAccess();
                      },
                      child: Text(t.grantPermission, style: AppTextStyles.chipLabel.copyWith(color: AppColors.primer, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
