import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/afirmasi_reminder.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Pengingat notifikasi afirmasi harian. Implement persis
/// `design/Afirmasi.dc.html` § Pengingat afirmasi.
class AfirmasiPengingatScreen extends StatefulWidget {
  const AfirmasiPengingatScreen({super.key});

  @override
  State<AfirmasiPengingatScreen> createState() => _AfirmasiPengingatScreenState();
}

class _AfirmasiPengingatScreenState extends State<AfirmasiPengingatScreen> {
  late bool _aktif;
  late String _jam;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    final prefs = AppScope.of(context).prefs;
    _aktif = prefs.notifSettingsJson['afirmasi_harian'] as bool? ?? true;
    _jam = prefs.afirmasiReminderTime;
  }

  /// Simpan sungguhan: toggle & jam masuk ke prefs (toggle yang sama dengan
  /// "Afirmasi harian" di layar Notifikasi), lalu notifikasi harian
  /// dijadwal ulang / dibatalkan.
  Future<void> _simpan() async {
    if (_menyimpan) return;
    setState(() => _menyimpan = true);
    final scope = AppScope.of(context);
    final message = context.s.afirmasi.reminderSaved;
    await scope.prefs.setNotifSettingsJson({...scope.prefs.notifSettingsJson, 'afirmasi_harian': _aktif});
    await scope.prefs.setAfirmasiReminderTime(_jam);
    await AfirmasiReminder.refresh(
      prefs: scope.prefs,
      content: scope.contentRepository,
      users: scope.userRepository,
      uid: scope.auth.uid,
      strings: scope.language.strings.notif,
      afirmasi: scope.language.strings.afirmasi,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.afirmasi;
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.xxl)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(t.reminderSwitch, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14))),
                            Switch(
                              value: _aktif,
                              onChanged: (v) => setState(() => _aktif = v),
                              activeTrackColor: AppColors.primer,
                              thumbColor: const WidgetStatePropertyAll(AppColors.latar),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(t.reminderNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.sendTime, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      for (final option in t.timeOptions)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: GestureDetector(
                              onTap: () => setState(() => _jam = option.$1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _jam == option.$1 ? AppColors.primer : AppColors.garis, width: 1.5),
                                  color: _jam == option.$1 ? AppColors.primer.withValues(alpha: 0.12) : Colors.transparent,
                                ),
                                child: Column(
                                  children: [
                                    Text(option.$1, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: _jam == option.$1 ? AppColors.primer : AppColors.teksSekunder)),
                                    const SizedBox(height: 2),
                                    Text(option.$2, style: AppTextStyles.caption.copyWith(fontSize: 10, color: _jam == option.$1 ? AppColors.primer : AppColors.teksRedup)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.preview, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(color: AppColors.kartu, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primer, AppColors.sekunder]), borderRadius: BorderRadius.circular(11)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.auto_awesome, size: 18, color: AppColors.latar),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Riung', style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksUtama)),
                                  Text(_jam, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(t.previewSample, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.sekunder.withValues(alpha: 0.08), border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.25)), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 17, color: AppColors.sekunder),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(t.reminderInfo, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5))),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: RiungButton(label: context.s.common.simpan, onPressed: _menyimpan ? null : _simpan),
            ),
          ],
        ),
      ),
    );
  }
}
