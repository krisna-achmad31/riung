import 'package:flutter/material.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/app_tile.dart';
import 'appbeku_setup_screen.dart';

/// Rekap harian Aplikasi Beku — pintu masuk fitur ini dari Pengaturan.
/// Implement persis `design/AppBeku.dc.html` § "Rekap harian".
class AppBekuRekapScreen extends StatefulWidget {
  const AppBekuRekapScreen({super.key});

  @override
  State<AppBekuRekapScreen> createState() => _AppBekuRekapScreenState();
}

class _AppBekuRekapScreenState extends State<AppBekuRekapScreen> {
  @override
  void initState() {
    super.initState();
    AppScope.of(context).appBeku.checkUsageAndMaybeTrigger();
  }

  @override
  Widget build(BuildContext context) {
    final appBeku = AppScope.of(context).appBeku;
    final t = context.s.appbeku;
    void bukaSetup() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppBekuSetupScreen()));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.title, trailing: RiungGlassIconButton(icon: Icons.tune_rounded, onTap: bukaSetup)),
              Expanded(
                child: ListenableBuilder(
                  listenable: appBeku,
                  builder: (context, _) {
                    if (appBeku.enabledFrozenApps.isEmpty) return _EmptyState(onSetup: bukaSetup);
                    final totalUsed = appBeku.enabledFrozenApps.fold<int>(0, (sum, a) => sum + appBeku.usageMinutesOf(a.packageName));
                    final totalLimit = appBeku.enabledFrozenApps.fold<int>(0, (sum, a) => sum + appBeku.effectiveLimitOf(a.packageName));
                    final sisa = (totalLimit - totalUsed).clamp(0, totalLimit == 0 ? 0 : 1 << 30);

                    return RiungBleedListView(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
                      children: [
                        _HariIniCard(
                          eyebrow: t.today,
                          total: t.scrollMinutes(totalUsed),
                          sub: sisa > 0 ? t.underLimit(sisa) : t.totalLimitReached,
                          progress: totalLimit == 0 ? 0 : (totalUsed / totalLimit).clamp(0.0, 1.0),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(t.perApp, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final setting in appBeku.enabledFrozenApps) ...[
                          _RecapBar(
                            entry: AppBekuCatalog.byPackage(setting.packageName),
                            used: appBeku.usageMinutesOf(setting.packageName),
                            limit: appBeku.effectiveLimitOf(setting.packageName),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(color: AppColors.primerLembut.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            children: [
                              const AppTile(entry: AppBekuCatalog.whatsapp, size: 28),
                              const SizedBox(width: 10),
                              Expanded(child: Text(t.whatsappNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.35, fontWeight: FontWeight.w500, color: AppColors.primer))),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _StatBox(
                                  leading: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(color: AppColors.primerLembut, borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.air_rounded, size: 16, color: AppColors.primer),
                                  ),
                                  value: t.breathsTaken(appBeku.breathTakenToday),
                                  label: t.breathsLabel,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _StatBox(leading: const RiungIcon3D(RiungIcon.koin, size: 30), value: '${appBeku.scrollCoinsToday}', label: t.coinsLabel)),
                              const SizedBox(width: 10),
                              Expanded(child: _StatBox(leading: const RiungIcon3D(RiungIcon.streak, size: 30), value: t.streakDays(appBeku.streakDays), label: t.streakLabel)),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(t.footerNote, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksRedup)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu "Hari ini" (frame `Hari ini`): gradien langit, total menit, ikon
/// beku 3D, progres terhadap total batas.
class _HariIniCard extends StatelessWidget {
  const _HariIniCard({required this.eyebrow, required this.total, required this.sub, required this.progress});

  final String eyebrow;
  final String total;
  final String sub;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.langitLembut, AppColors.permukaanPadat]),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
        boxShadow: AppGlass.shadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.langitGelap)),
                    const SizedBox(height: 2),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(total, style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.2))),
                    const SizedBox(height: 2),
                    Text(sub, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const RiungIcon3D(RiungIcon.aplikasiBeku, size: 76),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 10,
            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(5)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              heightFactor: 1,
              widthFactor: progress,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.langitMuda, AppColors.langit]), borderRadius: BorderRadius.circular(5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris per aplikasi (frame `Per app …`): tile, nama, pemakaian, bar.
class _RecapBar extends StatelessWidget {
  const _RecapBar({required this.entry, required this.used, required this.limit});

  final AppBekuCatalogEntry? entry;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final t = context.s.appbeku;
    final overLimit = limit > 0 && used >= limit;
    final pct = limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return RiungGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          AppTile(entry: entry),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(entry?.name ?? '?', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama))),
                    Text(
                      '${t.usedMinutes(used)}${t.ofLimit(limit)}${overLimit ? ' ${t.limitReachedInline}' : ''}',
                      style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: overLimit ? AppColors.aksenHangatGelap : AppColors.teksSekunder),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(3)),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    heightFactor: 1,
                    widthFactor: pct,
                    child: DecoratedBox(decoration: BoxDecoration(color: overLimit ? AppColors.aksenHangat : AppColors.langit, borderRadius: BorderRadius.circular(3))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.leading, required this.value, required this.label});

  final Widget leading;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: AppTextStyles.title.copyWith(fontSize: 18, height: 1.2))),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.3, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 110,
              height: 116,
              child: RiungIcon3D(RiungIcon.aplikasiBeku, size: 110),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(context.s.appbeku.emptyTitle, textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 20)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.s.appbeku.emptyBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            RiungButton(label: context.s.appbeku.setupApps, onPressed: onSetup),
          ],
        ),
      ),
    );
  }
}
