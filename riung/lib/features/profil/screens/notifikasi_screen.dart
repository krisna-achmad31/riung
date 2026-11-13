import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/afirmasi_reminder.dart';
import '../../../core/services/services.dart';
import '../../../core/services/sleep_reminder.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../tidur/screens/tidur_pengingat_screen.dart';

const _sleepKey = 'pengingat_tidur';

class _NotifSetting {
  const _NotifSetting(this.key, this.defaultOn);
  final String key;
  final bool defaultOn;
}

const _settings = [
  _NotifSetting('checkin_pagi', true),
  _NotifSetting('afirmasi_harian', true),
  _NotifSetting(_sleepKey, false),
  _NotifSetting('tiket_serangan', false),
  _NotifSetting('kabar_riung', false),
];

(String, String) _textFor(ProfilStrings t, String key) {
  switch (key) {
    case 'checkin_pagi':
      return (t.notifCheckinTitle, t.notifCheckinSub);
    case 'afirmasi_harian':
      return (t.notifAffirmationTitle, t.notifAffirmationSub);
    case 'tiket_serangan':
      return (t.notifTicketTitle, t.notifTicketSub);
    default:
      return (t.notifNewsTitle, t.notifNewsSub);
  }
}

/// Pengaturan notifikasi — cuma preferensi on/off tersimpan lokal, BELUM
/// tersambung ke pengiriman push FCM sungguhan (butuh scheduler
/// server-side, di luar cakupan M6, lihat laporan deviasi). Implement
/// persis `design/Profil.dc.html` § "Notifikasi".
class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  late Map<String, bool> _state;
  bool _updatingSleep = false;

  @override
  void initState() {
    super.initState();
    final saved = AppScope.of(context).prefs.notifSettingsJson;
    _state = {
      for (final s in _settings)
        if (s.key != _sleepKey) s.key: saved[s.key] as bool? ?? s.defaultOn,
    };
  }

  void _ubah(String key, bool value) {
    setState(() => _state[key] = value);
    final scope = AppScope.of(context);
    scope.prefs.setNotifSettingsJson({...scope.prefs.notifSettingsJson, ..._state});
    if (key == 'afirmasi_harian') {
      AfirmasiReminder.refresh(
        prefs: scope.prefs,
        content: scope.contentRepository,
        users: scope.userRepository,
        uid: scope.auth.uid,
        strings: scope.language.strings.notif,
        afirmasi: scope.language.strings.afirmasi,
      );
      return;
    }
    if (key != 'checkin_pagi') return;
    // Fix 3: toggle "Check-in pagi" & "Afirmasi harian" yang benar-benar
    // tersambung ke notifikasi lokal — misi harian & streak saver tidak
    // punya toggle sendiri, jadi tidak ada yang perlu dihubungkan buat mereka.
    final sudahCheckin = scope.streak.sudahCheckinHariIni;
    if (value && !sudahCheckin) {
      LocalNotificationService.instance.scheduleCheckinPagi(strings: scope.language.strings.notif);
    } else {
      LocalNotificationService.instance.cancel(LocalNotificationService.idCheckinPagi);
    }
  }

  Future<void> _openSleepSchedule() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TidurPengingatScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleSleep(bool enabled) async {
    final scope = AppScope.of(context);
    final settings = scope.prefs.sleepReminder;
    if (enabled && settings.days.isEmpty) {
      await _openSleepSchedule();
      return;
    }

    setState(() => _updatingSleep = true);
    try {
      await scope.prefs.setSleepReminder(settings.copyWith(enabled: enabled));
      await SleepReminder.refresh(
        prefs: scope.prefs,
        strings: scope.language.strings.notif,
        userName: scope.auth.profile?.displayName,
      );
    } finally {
      if (mounted) setState(() => _updatingSleep = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    final sleep = AppScope.of(context).prefs.sleepReminder;
    final sleepEnabled = sleep.enabled && sleep.days.isNotEmpty;
    final sleepTime = TimeOfDay(
      hour: sleep.notifyMinutes ~/ 60,
      minute: sleep.notifyMinutes % 60,
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.notifScreenTitle),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
                  children: [
                    RiungMenuGroup(
                      children: [
                        for (final setting in _settings)
                          if (setting.key == _sleepKey)
                            RiungMenuRow(
                              leading: const RiungIcon3D(RiungIcon.tidur, size: 38),
                              title: t.notifSleepTitle,
                              subtitle: t.notifSleepSchedule(
                                sleepEnabled ? sleepTime.format(context) : null,
                              ),
                              onTap: _updatingSleep ? null : _openSleepSchedule,
                              trailing: Switch(
                                value: sleepEnabled,
                                onChanged: _updatingSleep ? null : _toggleSleep,
                              ),
                            )
                          else
                            RiungMenuRow(
                              leading: RiungIcon3D(_iconFor(setting.key), size: 38),
                              title: _textFor(t, setting.key).$1,
                              subtitle: _textFor(t, setting.key).$2,
                              trailing: Switch(
                                value: _state[setting.key] ?? setting.defaultOn,
                                onChanged: (v) => _ubah(setting.key, v),
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.sekunderLembut.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.dark_mode_outlined, size: 16, color: AppColors.sekunder),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(t.notifQuiet, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600, color: AppColors.sekunder)),
                          ),
                        ],
                      ),
                    ),
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

RiungIcon _iconFor(String key) => switch (key) {
      'checkin_pagi' => RiungIcon.checkin,
      'afirmasi_harian' => RiungIcon.afirmasi,
      'tiket_serangan' => RiungIcon.tiket,
      _ => RiungIcon.beranda,
    };
