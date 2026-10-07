import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Kalender latihan bulanan — 3 state netral dari data sungguhan
/// (check-in & entri jurnal), tidak ada state "gagal"/merah. Implement
/// persis `design/Profil.dc.html` § "Kalender latihan bulanan".
///
/// CATATAN: penanda "pakai koin secara sadar" (dot amber) di desain butuh
/// riwayat transaksi koin per tanggal yang belum ada sumber datanya di
/// app ini (cuma saldo & lifetime total yang tersimpan, bukan log
/// per-hari) — sengaja dilewati daripada dikarang, lihat laporan deviasi.
class KalenderLatihanScreen extends StatefulWidget {
  const KalenderLatihanScreen({super.key});

  @override
  State<KalenderLatihanScreen> createState() => _KalenderLatihanScreenState();
}

class _KalenderLatihanScreenState extends State<KalenderLatihanScreen> {
  DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);
  Set<DateTime> _tanggalCheckin = {};
  Set<DateTime> _tanggalJurnal = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  DateTime _tanpaWaktu(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _muat() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.uid;
    if (uid == null) return;
    final checkIns = await scope.userRepository.getCheckIns(uid);
    final jurnal = await scope.userRepository.getJournalEntries(uid);
    if (!mounted) return;
    setState(() {
      _tanggalCheckin = checkIns.map((c) => _tanpaWaktu(c.date)).toSet();
      _tanggalJurnal = jurnal.map((j) => _tanpaWaktu(j.createdAt)).toSet();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.profil;
    final now = DateTime.now();
    final today = _tanpaWaktu(now);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final daysThisWeekPracticed = List.generate(7, (i) => startOfWeek.add(Duration(days: i)))
        .where((d) => !d.isAfter(today) && (_tanggalCheckin.contains(d) || _tanggalJurnal.contains(d)))
        .length;

    final firstOfMonth = DateTime(_bulan.year, _bulan.month, 1);
    final daysInMonth = DateTime(_bulan.year, _bulan.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.calendarScreenTitle),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primer))
                    : RiungBleedListView(
                        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
                        children: [
                          ListenableBuilder(
                            listenable: scope.streak,
                            builder: (context, _) => Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _StatBox(
                                    leading: const RiungIcon3D(RiungIcon.streak, size: 28),
                                    value: t.daysCount(scope.streak.current),
                                    label: t.streakNow,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: _StatBox(value: t.daysCount(scope.streak.longest), label: t.streakBest)),
                                const SizedBox(width: 10),
                                Expanded(child: _StatBox(value: t.daysCount(daysThisWeekPracticed), label: t.thisWeek)),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          RiungGlassCard(
                            radius: 28,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _MonthArrow(icon: Icons.chevron_left_rounded, onTap: () => setState(() => _bulan = DateTime(_bulan.year, _bulan.month - 1))),
                                    Expanded(
                                      child: Text(
                                        '${t.monthNames[_bulan.month - 1]} ${_bulan.year}',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.title.copyWith(fontSize: 15),
                                      ),
                                    ),
                                    _MonthArrow(icon: Icons.chevron_right_rounded, onTap: () => setState(() => _bulan = DateTime(_bulan.year, _bulan.month + 1))),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    for (final wd in t.weekdayShort)
                                      Expanded(
                                        child: Text(wd, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teksRedup)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                GridView.count(
                                  crossAxisCount: 7,
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 4,
                                  childAspectRatio: 42 / 38,
                                  children: [
                                    for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
                                    for (var d = 1; d <= daysInMonth; d++)
                                      _DayCell(
                                        day: d,
                                        isToday: DateTime(_bulan.year, _bulan.month, d) == today,
                                        checkin: _tanggalCheckin.contains(DateTime(_bulan.year, _bulan.month, d)),
                                        jurnal: _tanggalJurnal.contains(DateTime(_bulan.year, _bulan.month, d)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _LegendRow(color: AppColors.primer, label: t.legendFull),
                          _LegendRow(color: AppColors.primerLembut, label: t.legendPracticed),
                          _LegendRow(color: AppColors.permukaan, label: t.legendEmpty),
                          const SizedBox(height: AppSpacing.md),
                          Text(t.calendarNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600, color: AppColors.primer)),
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

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 18, color: AppColors.teksSekunder)),
    );
  }
}

/// Sel tanggal (frame `Tgl`): penuh = primer, latihan = primer lembut,
/// kosong = kaca tipis. Tidak ada state "gagal".
class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.isToday, required this.checkin, required this.jurnal});

  final int day;
  final bool isToday;
  final bool checkin;
  final bool jurnal;

  @override
  Widget build(BuildContext context) {
    final penuh = checkin && jurnal;
    final latihan = checkin || jurnal;
    final bg = penuh ? AppColors.primer : (latihan ? AppColors.primerLembut : AppColors.kartu);
    final textColor = penuh ? AppColors.diAtasTinta : (latihan ? AppColors.primer : AppColors.teksRedup);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: isToday ? Border.all(color: AppColors.tinta, width: 1.5) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text('$day', style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label, this.leading});

  final Widget? leading;
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
          if (leading != null) ...[leading!, const SizedBox(height: 2)],
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: AppTextStyles.title.copyWith(fontSize: 18, height: 1.2))),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}
