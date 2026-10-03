import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/afirmasi_reminder.dart';
import '../../../core/services/services.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';

class _NotifSetting {
  const _NotifSetting(this.key, this.defaultOn);
  final String key;
  final bool defaultOn;
}

const _settings = [
  _NotifSetting('checkin_pagi', true),
  _NotifSetting('afirmasi_harian', true),
  _NotifSetting('pengingat_tidur', true),
  _NotifSetting('tiket_serangan', false),
  _NotifSetting('kabar_riung', false),
];

(String, String) _textFor(ProfilStrings t, String key) {
  switch (key) {
    case 'checkin_pagi':
      return (t.notifCheckinTitle, t.notifCheckinSub);
    case 'afirmasi_harian':
      return (t.notifAffirmationTitle, t.notifAffirmationSub);
    case 'pengingat_tidur':
      return (t.notifSleepTitle, t.notifSleepSub);
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

  @override
  void initState() {
    super.initState();
    final saved = AppScope.of(context).prefs.notifSettingsJson;
    _state = {for (final s in _settings) s.key: saved[s.key] as bool? ?? s.defaultOn};
  }

  void _ubah(String key, bool value) {
    setState(() => _state[key] = value);
    AppScope.of(context).prefs.setNotifSettingsJson(_state);
    final scope = AppScope.of(context);
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

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
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
                  Text(t.notifScreenTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
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
                      t.notifIntro,
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final setting in _settings) ...[
                      _ToggleRow(
                        title: _textFor(t, setting.key).$1,
                        sub: _textFor(t, setting.key).$2,
                        value: _state[setting.key] ?? setting.defaultOn,
                        onChanged: (v) => _ubah(setting.key, v),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.sekunder.withValues(alpha: 0.08),
                        border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.25)),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.nightlight_round, size: 16, color: AppColors.sekunder),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              t.notifQuiet,
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
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.title, required this.sub, required this.value, required this.onChanged});

  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                const SizedBox(height: 3),
                Text(sub, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.latar,
            activeTrackColor: AppColors.primer,
            inactiveThumbColor: AppColors.teksRedup,
            inactiveTrackColor: AppColors.kartu,
          ),
        ],
      ),
    );
  }
}
