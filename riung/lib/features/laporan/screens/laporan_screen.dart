import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/services.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../toko/screens/paywall_premium_screen.dart';
import '../logic/report_config.dart';
import '../logic/report_engine.dart';
import '../logic/report_models.dart';
import '../widgets/report_body.dart';
import '../widgets/report_notice_card.dart';
import '../widgets/sleep_connect_card.dart';

/// Laporan refleksi dari check-in & metadata jurnal: mingguan (gratis) dan
/// bulanan (Premium). Semua dihitung di perangkat oleh [ReportEngine].
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key, this.sleepService});

  /// Sumber data tidur; default Health Connect (diganti saat tes).
  final SleepDataService? sleepService;

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  List<ReportEntry>? _entries;
  Object? _error;
  bool _monthly = false;
  bool _sleepBusy = false;
  Map<DateTime, int> _sleepMinutes = const {};
  late final SleepDataService _sleep = widget.sleepService ?? HealthConnectSleepService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final scope = AppScope.of(context);
    final uid = scope.auth.uid;
    if (uid == null) return;
    try {
      final checkIns = await scope.userRepository.getCheckIns(uid);
      final journals = await scope.userRepository.getJournalEntries(uid);
      if (!mounted) return;
      setState(() => _entries = ReportEngine.entriesFrom(checkIns, journals));
      await _loadSleep();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  /// Baca malam tidur bila pengguna sudah menghubungkan. Izin yang dicabut di
  /// Health Connect otomatis mematikan sambungan.
  Future<void> _loadSleep() async {
    final prefs = AppScope.of(context).prefs;
    if (!prefs.sleepSyncEnabled) return;
    final access = await _sleep.access();
    if (access != SleepAccess.granted) {
      await prefs.setSleepSyncEnabled(false);
      if (mounted) setState(() => _sleepMinutes = const {});
      return;
    }
    final nights = await _sleep.readNights(days: ReportConfig.monthDays);
    if (!mounted) return;
    setState(() => _sleepMinutes = {for (final n in nights) n.wakeDate: n.minutes});
  }

  Future<void> _connectSleep() async {
    final scope = AppScope.of(context);
    final t = scope.language.strings.laporan;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.permukaan,
        title: Text(t.sleepConsentTitle, style: AppTextStyles.title.copyWith(fontSize: 17)),
        content: Text(t.sleepConsentBody, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(t.sleepConsentLater)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(t.sleepConsentAllow)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _sleepBusy = true);
    var access = await _sleep.access();
    if (access == SleepAccess.notGranted) {
      access = await _sleep.requestAccess() ? SleepAccess.granted : SleepAccess.notGranted;
      if (access == SleepAccess.notGranted) messenger.showSnackBar(SnackBar(content: Text(t.sleepDenied)));
    } else if (access == SleepAccess.unsupported) {
      messenger.showSnackBar(SnackBar(content: Text(t.sleepUnsupported)));
    } else if (access == SleepAccess.needsInstall) {
      messenger.showSnackBar(SnackBar(
        content: Text(t.sleepInstallBody),
        action: SnackBarAction(label: t.sleepInstallCta, onPressed: _sleep.openInstall),
      ));
    }
    if (access == SleepAccess.granted) {
      await scope.prefs.setSleepSyncEnabled(true);
      await _loadSleep();
    }
    if (mounted) setState(() => _sleepBusy = false);
  }

  Future<void> _disconnectSleep() async {
    await AppScope.of(context).prefs.setSleepSyncEnabled(false);
    await _sleep.revoke();
    if (mounted) setState(() => _sleepMinutes = const {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.laporan;
    final sleepEnabled = AppScope.of(context).prefs.sleepSyncEnabled;
    final premium = AppScope.of(context).auth.profile?.premiumNow ?? false;
    final entries = _entries;

    Widget content;
    if (_error != null) {
      content = Center(child: TextButton(onPressed: _load, child: Text(context.s.common.cobaLagi)));
    } else if (entries == null) {
      content = const Center(child: CircularProgressIndicator(color: AppColors.primer));
    } else if (_monthly && !premium) {
      content = ReportNoticeCard(
        icon: Icons.workspace_premium,
        accent: AppColors.aksenHangat,
        title: t.lockedTitle,
        body: t.monthLockedBody,
        cta: t.lockedCta,
        onCta: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPremiumScreen())),
      );
    } else {
      final report = ReportEngine.build(
        entries,
        now: DateTime.now(),
        windowDays: _monthly ? ReportConfig.monthDays : ReportConfig.weekDays,
        sleepMinutes: _sleepMinutes,
      );
      content = ReportBody(report: report, premium: premium);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.title),
              const SizedBox(height: AppSpacing.md),
              RiungSegmentedTabs(
                labels: [t.weekTab, premium ? t.monthTab : '${t.monthTab} 🔒'],
                index: _monthly ? 1 : 0,
                onChanged: (i) => setState(() => _monthly = i == 1),
              ),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
                  children: [
                    content,
                    const SizedBox(height: AppSpacing.md),
                    SleepConnectCard(
                      connected: sleepEnabled,
                      busy: _sleepBusy,
                      noData: sleepEnabled && _sleepMinutes.isEmpty && _entries != null,
                      onConnect: _connectSleep,
                      onDisconnect: _disconnectSleep,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.disclaimer, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, color: AppColors.teksRedup)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
