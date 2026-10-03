import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';

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
                  Expanded(child: Text(t.calendarScreenTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15))),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primer))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => setState(() => _bulan = DateTime(_bulan.year, _bulan.month - 1)),
                                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.teksRedup),
                              ),
                              Text('${t.monthNames[_bulan.month - 1]} ${_bulan.year}', style: AppTextStyles.title.copyWith(fontSize: 16)),
                              IconButton(
                                onPressed: () => setState(() => _bulan = DateTime(_bulan.year, _bulan.month + 1)),
                                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.teksRedup),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ListenableBuilder(
                                listenable: scope.streak,
                                builder: (context, _) => _StatBox(
                                  icon: Icons.local_fire_department,
                                  color: AppColors.aksenHangat,
                                  value: t.daysCount(scope.streak.current),
                                  label: t.streakNow,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              ListenableBuilder(
                                listenable: scope.streak,
                                builder: (context, _) => _StatBox(
                                  icon: Icons.star_rounded,
                                  color: AppColors.monsterCermin,
                                  value: t.daysCount(scope.streak.longest),
                                  label: t.streakBest,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _StatBox(
                                icon: Icons.calendar_today_rounded,
                                color: AppColors.sekunder,
                                value: '$daysThisWeekPracticed/7',
                                label: t.thisWeek,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.permukaan,
                              border: Border.all(color: AppColors.garis),
                              borderRadius: BorderRadius.circular(AppRadius.xxl),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    for (final wd in t.weekdayShort)
                                      Expanded(
                                        child: Text(wd, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                GridView.count(
                                  crossAxisCount: 7,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  childAspectRatio: 0.95,
                                  children: [
                                    for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
                                    for (var d = 1; d <= daysInMonth; d++)
                                      _DayCell(
                                        day: d,
                                        isToday: DateTime(_bulan.year, _bulan.month, d) == today,
                                        isFuture: DateTime(_bulan.year, _bulan.month, d).isAfter(today),
                                        checkin: _tanggalCheckin.contains(DateTime(_bulan.year, _bulan.month, d)),
                                        jurnal: _tanggalJurnal.contains(DateTime(_bulan.year, _bulan.month, d)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.permukaan,
                              border: Border.all(color: AppColors.garis),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LegendRow(color: AppColors.sekunder, label: t.legendFull),
                                _LegendRow(color: AppColors.primer.withValues(alpha: 0.22), border: AppColors.primer.withValues(alpha: 0.35), label: t.legendPracticed),
                                _LegendRow(color: Colors.transparent, border: AppColors.garis, label: t.legendEmpty),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            t.calendarNote,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
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

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.isToday, required this.isFuture, required this.checkin, required this.jurnal});

  final int day;
  final bool isToday;
  final bool isFuture;
  final bool checkin;
  final bool jurnal;

  @override
  Widget build(BuildContext context) {
    final penuh = checkin && jurnal;
    final latihan = checkin || jurnal;
    final bg = penuh ? AppColors.sekunder : (latihan ? AppColors.primer.withValues(alpha: 0.22) : Colors.transparent);
    final border = isToday
        ? AppColors.teksUtama
        : isFuture
            ? AppColors.kartu
            : penuh
                ? AppColors.sekunder
                : latihan
                    ? AppColors.primer.withValues(alpha: 0.35)
                    : AppColors.garis;
    final textColor = penuh ? AppColors.latar : (isFuture ? AppColors.kartu : AppColors.teksSekunder);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: isToday ? 1.5 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: penuh ? FontWeight.w800 : FontWeight.w500, color: textColor),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.chipLabel.copyWith(fontSize: 15)),
            Text(label, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, this.border});

  final Color color;
  final Color? border;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, border: Border.all(color: border ?? Colors.transparent), borderRadius: BorderRadius.circular(6)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}
