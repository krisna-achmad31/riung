import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/afirmasi_reminder.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Pengingat notifikasi afirmasi harian. Implement persis
/// `design/Afirmasi.dc.html` § Pengingat afirmasi (visual: `Glass — Afirmasi · Pengingat`).
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

  Future<void> _pilihJam() async {
    final t = context.s.afirmasi;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.sendTime, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              for (final (jam, label) in t.timeOptions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(context).pop(jam),
                  title: Text(label, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                  trailing: Text(jam, style: AppTextStyles.title.copyWith(fontSize: 16, color: jam == _jam ? AppColors.primer : AppColors.teksSekunder)),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _jam = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.afirmasi;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            children: [
              RiungGlassHeader(title: t.reminderTitle),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  children: [
                    RiungGlassCard(
                      radius: 24,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.reminderSwitch, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                                const SizedBox(height: 3),
                                Text(t.reminderNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.teksSekunder)),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Switch(value: _aktif, onChanged: (v) => setState(() => _aktif = v)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RiungGlassCard(
                      radius: 24,
                      padding: const EdgeInsets.all(16),
                      onTap: _pilihJam,
                      child: Row(
                        children: [
                          Expanded(child: Text(t.sendTime, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.primerLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                            child: Text(_jam, style: AppTextStyles.title.copyWith(fontSize: 16, height: 1.2, color: AppColors.primer)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.preview, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.md),
                    _NotifPreview(title: t.cardScreenTitle, body: t.previewSample),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.kartu, borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          const Icon(Icons.shuffle_rounded, size: 16, color: AppColors.teksSekunder),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t.reminderInfo, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.teksSekunder))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RiungButton(label: t.saveReminder, onPressed: _menyimpan ? null : _simpan),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pratinjau notifikasi (frame `Notifikasi`): ikon app gradien "R" + teks.
class _NotifPreview extends StatelessWidget {
  const _NotifPreview({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      radius: 24,
      color: AppColors.permukaan,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primer, AppColors.sekunder]),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text('R', style: AppTextStyles.title.copyWith(fontSize: 18, color: AppColors.diAtasTinta)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksUtama)),
                const SizedBox(height: 2),
                Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
