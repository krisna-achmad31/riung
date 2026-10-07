import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'appbeku_permission_screen.dart';
import '../widgets/app_tile.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(title: t.setupApps),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                  children: [
                    Text(t.setupHeadline, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
                    const SizedBox(height: 6),
                    Text(t.setupBody, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.md),
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
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(color: AppColors.primerLembut.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          const AppTile(entry: AppBekuCatalog.whatsapp, size: 32),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t.whatsappNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.35, fontWeight: FontWeight.w500, color: AppColors.primer))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RiungButton(
                label: jumlahAktif == 0 ? t.pickAtLeastOne : t.freezeCount(jumlahAktif),
                onPressed: jumlahAktif == 0 ? null : _simpan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pilihan aplikasi (frame `Pilih …`): tile, nama, kotak centang; saat
/// dipilih muncul baris batas harian.
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
    final t = context.s.appbeku;
    return GestureDetector(
      onTap: () => onToggle(!enabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? AppColors.permukaanPadat.withValues(alpha: 0.85) : AppColors.kartu,
          border: Border.all(color: enabled ? AppColors.primer : AppColors.garis, width: enabled ? 2 : AppGlass.edgeWidth),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Row(
              children: [
                AppTile(entry: entry),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.name, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama))),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: enabled ? AppColors.primer : Colors.transparent,
                    border: Border.all(color: enabled ? AppColors.primer : AppColors.teksRedup, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: enabled ? const Icon(Icons.check_rounded, size: 14, color: AppColors.diAtasTinta) : null,
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(t.dailyLimit, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final tier in _tiers)
                          GestureDetector(
                            onTap: () => onLimitChanged(tier),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: limit == tier ? AppColors.tinta : AppColors.permukaan,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                t.minutesShort(tier),
                                style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: limit == tier ? AppColors.diAtasTinta : AppColors.teksUtama),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
        return RiungGlassCard(
          radius: 22,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RiungMenuRow.iconBox(on ? Icons.lock_outline_rounded : Icons.lock_open_rounded, background: on ? AppColors.primerLembut : AppColors.netralLembut, color: on ? AppColors.primer : AppColors.teksSekunder),
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
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(on ? t.lockOnBody : t.lockOffBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksSekunder)),
              if (missing) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.aksenHangatGelap),
                    const SizedBox(width: 6),
                    Expanded(child: Text(t.lockNeedsPermission, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.aksenHangatGelap))),
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
