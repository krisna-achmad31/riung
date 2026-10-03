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
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder)),
                  Text(t.reminderTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
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
                      t.reminderIntro,
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.xxl)),
                      child: Column(
                        children: [
                          Text(t.targetKicker, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${(_targetMinutes ~/ 60).toString().padLeft(2, '0')}:${(_targetMinutes % 60).toString().padLeft(2, '0')}',
                            style: AppTextStyles.display.copyWith(fontSize: 48, letterSpacing: -1, color: AppColors.primer),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AdjustChip(label: t.adjustMinutes(-15), onTap: () => _adjust(-15)),
                              const SizedBox(width: AppSpacing.sm),
                              _AdjustChip(label: t.adjustMinutes(15), onTap: () => _adjust(15)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.lg)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.remindBefore(SleepReminderSettings.leadMinutes), style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 13)),
                                Text('"${context.s.notif.sleepBody(userName)}"', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _aktif,
                            onChanged: (v) => setState(() => _aktif = v),
                            activeTrackColor: AppColors.primer,
                            thumbColor: const WidgetStatePropertyAll(AppColors.latar),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.lg)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.activeDays, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 13)),
                                Text(t.daysSummary(_activeDays, context.s.profil.weekdayShort), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              for (var i = 0; i < 7; i++)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _activeDays.contains(i) ? _activeDays.remove(i) : _activeDays.add(i)),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: _activeDays.contains(i) ? AppColors.primer : AppColors.kartu),
                                      alignment: Alignment.center,
                                      child: Text(t.dayInitials[i], style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: _activeDays.contains(i) ? AppColors.latar : AppColors.teksRedup)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.sekunder.withValues(alpha: 0.08), border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.25)), borderRadius: BorderRadius.circular(AppRadius.lg)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 17, color: AppColors.sekunder),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(t.streakNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: RiungButton(label: t.saveReminder, onPressed: _simpan),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustChip extends StatelessWidget {
  const _AdjustChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.garis)),
        child: Text(label, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 12)),
      ),
    );
  }
}
