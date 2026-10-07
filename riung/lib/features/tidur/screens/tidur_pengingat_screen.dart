import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/services/sleep_reminder.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Pengingat tidur — target jam mulai tidur + hari aktif. Implement
/// persis `design/Tidur.dc.html` § Pengingat tidur. "Simpan pengingat"
/// menyimpan ke [LocalPrefsStore] & menjadwalkan notifikasi mingguan lewat
/// [SleepReminder].
class TidurPengingatScreen extends StatefulWidget {
  const TidurPengingatScreen({super.key});

  @override
  State<TidurPengingatScreen> createState() => _TidurPengingatScreenState();
}

class _TidurPengingatScreenState extends State<TidurPengingatScreen> {
  late int _targetMinutes;
  late bool _aktif;
  late Set<int> _activeDays;

  @override
  void initState() {
    super.initState();
    final prefs = AppScope.of(context).prefs;
    final saved = prefs.sleepReminder;
    _targetMinutes = saved.targetMinutes;
    // Belum pernah disimpan → switch tampil aktif seperti di desain.
    _aktif = prefs.hasSleepReminder ? saved.enabled : true;
    _activeDays = {...saved.days};
  }

  void _adjust(int minutes) {
    setState(() => _targetMinutes = (_targetMinutes + minutes + 1440) % 1440);
  }

  Future<void> _simpan() async {
    final scope = AppScope.of(context);
    final strings = scope.language.strings;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await scope.prefs.setSleepReminder(
      SleepReminderSettings(enabled: _aktif, targetMinutes: _targetMinutes, days: _activeDays),
    );
    await SleepReminder.refresh(prefs: scope.prefs, strings: strings.notif, userName: scope.auth.profile?.displayName);
    final on = _aktif && _activeDays.isNotEmpty;
    messenger.showSnackBar(SnackBar(content: Text(on ? strings.tidur.reminderSaved : strings.tidur.reminderOff)));
    navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.tidur;
    final userName = AppScope.of(context).auth.profile?.displayName;
    final time = '${(_targetMinutes ~/ 60).toString().padLeft(2, '0')}:${(_targetMinutes % 60).toString().padLeft(2, '0')}';
    return Scaffold(
      body: RiungGlassBackdrop(
        night: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              children: [
                RiungGlassHeader(title: t.reminderTitle, night: true),
                Expanded(
                  child: RiungBleedListView(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    children: [
                      Text(t.reminderIntro, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppNight.teksSekunder)),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                        decoration: AppNight.card(radius: 30),
                        child: Column(
                          children: [
                            Text(t.targetKicker, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppNight.aksen)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RiungGlassIconButton(icon: Icons.remove_rounded, night: true, semanticLabel: t.adjustMinutes(-15), onTap: () => _adjust(-15)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(time, style: AppTextStyles.display.copyWith(fontSize: 52, height: 1.15, color: AppNight.teks)),
                                ),
                                RiungGlassIconButton(icon: Icons.add_rounded, night: true, semanticLabel: t.adjustMinutes(15), onTap: () => _adjust(15)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        decoration: AppNight.card(),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_none_rounded, size: 18, color: AppNight.aksen),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.remindBefore(SleepReminderSettings.leadMinutes), style: AppTextStyles.chipLabel.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: AppNight.teks)),
                                  Text('"${context.s.notif.sleepBody(userName)}"', style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppNight.teksRedup)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _aktif,
                              onChanged: (v) => setState(() => _aktif = v),
                              activeTrackColor: AppColors.kabutSage,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(t.activeDays, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppNight.teksSekunder)),
                      const SizedBox(height: 4),
                      Text(t.daysSummary(_activeDays, context.s.profil.weekdayShort), style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppNight.teksRedup)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          for (var i = 0; i < 7; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _activeDays.contains(i) ? _activeDays.remove(i) : _activeDays.add(i)),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _activeDays.contains(i) ? AppNight.aksen : AppNight.kaca,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: _activeDays.contains(i) ? AppNight.aksen : AppNight.tepi),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    t.dayInitials[i],
                                    style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: _activeDays.contains(i) ? AppNight.latarBawah : AppNight.teksSekunder),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.kabutSage.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_border_rounded, size: 16, color: AppColors.kabutSage),
                            const SizedBox(width: 10),
                            Expanded(child: Text(t.streakNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.primerLembut))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                RiungButton(label: t.saveReminder, variant: RiungButtonVariant.night, onPressed: _simpan),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
