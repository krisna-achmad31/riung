import 'package:flutter/material.dart';

import '../../../core/config/appbeku_catalog.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
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
                  Expanded(child: Text(t.title, style: AppTextStyles.subtitle.copyWith(fontSize: 15))),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AppBekuSetupScreen()),
                    ),
                    icon: const Icon(Icons.settings_rounded, size: 19, color: AppColors.teksRedup),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: appBeku,
                builder: (context, _) {
                  if (appBeku.enabledFrozenApps.isEmpty) {
                    return _EmptyState(
                      onSetup: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AppBekuSetupScreen()),
                      ),
                    );
                  }
                  final totalUsed = appBeku.enabledFrozenApps.fold<int>(0, (sum, a) => sum + appBeku.usageMinutesOf(a.packageName));
                  final totalLimit = appBeku.enabledFrozenApps.fold<int>(0, (sum, a) => sum + appBeku.effectiveLimitOf(a.packageName));
                  final sisa = (totalLimit - totalUsed).clamp(0, totalLimit == 0 ? 0 : 1 << 30);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.sekunder.withValues(alpha: 0.14), AppColors.kartu.withValues(alpha: 0.9)],
                            ),
                            border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.35)),
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.today, style: AppTextStyles.caption.copyWith(color: AppColors.sekunder, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6)),
                                    const SizedBox(height: 6),
                                    Text(t.scrollMinutes(totalUsed), style: AppTextStyles.display.copyWith(fontSize: 24)),
                                    const SizedBox(height: 6),
                                    Text(
                                      sisa > 0 ? t.underLimit(sisa) : t.totalLimitReached,
                                      style: AppTextStyles.body.copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: 76,
                                height: 80,
                                child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 76),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.permukaan,
                            border: Border.all(color: AppColors.garis),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.perApp, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6)),
                              const SizedBox(height: AppSpacing.md),
                              for (final setting in appBeku.enabledFrozenApps) ...[
                                _RecapBar(
                                  entry: AppBekuCatalog.byPackage(setting.packageName),
                                  used: appBeku.usageMinutesOf(setting.packageName),
                                  limit: appBeku.effectiveLimitOf(setting.packageName),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            _StatBox(icon: Icons.spa_rounded, color: AppColors.sekunder, value: t.breathsTaken(appBeku.breathTakenToday), label: t.breathsLabel),
                            const SizedBox(width: AppSpacing.sm),
                            _StatBox(icon: Icons.monetization_on, color: AppColors.aksenHangat, value: '${appBeku.scrollCoinsToday}', label: t.coinsLabel),
                            const SizedBox(width: AppSpacing.sm),
                            _StatBox(icon: Icons.local_fire_department, color: AppColors.aksenHangat, value: t.streakDays(appBeku.streakDays), label: t.streakLabel),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TahukahKamuCard(text: t.didYouKnowText, source: t.didYouKnowSource),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          t.footerNote,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapBar extends StatelessWidget {
  const _RecapBar({required this.entry, required this.used, required this.limit});

  final AppBekuCatalogEntry? entry;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final overLimit = limit > 0 && used >= limit;
    final pct = limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final color = overLimit ? AppColors.peringatan : AppColors.sekunder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(entry?.name ?? '?', style: AppTextStyles.chipLabel.copyWith(fontSize: 12)),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: context.s.appbeku.usedMinutes(used), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                  TextSpan(
                    text: overLimit ? context.s.appbeku.limitReachedInline : context.s.appbeku.ofLimit(limit),
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(value: pct, minHeight: 7, backgroundColor: AppColors.latar, valueColor: AlwaysStoppedAnimation(color)),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.chipLabel.copyWith(color: color, fontSize: 15)),
            Text(label, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 10)),
          ],
        ),
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
              child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.liar, size: 110),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(context.s.appbeku.emptyTitle, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
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
