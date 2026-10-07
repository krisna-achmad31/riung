import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/check_in.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/checkin_options.dart';

const Map<String, double> _moodWeight = {
  'berat': 0.28,
  'agak_berat': 0.4,
  'datar': 0.55,
  'cukup_baik': 0.72,
  'senang': 0.9,
};

const Map<String, String> _moodEmoji = {
  'berat': '😞',
  'agak_berat': '😟',
  'datar': '😐',
  'cukup_baik': '🙂',
  'senang': '😄',
};

/// Riwayat mood 7 hari terakhir, dari data check-in nyata. Implement
/// persis `design/Checkin.dc.html` § Riwayat mood.
class CheckInRiwayatScreen extends StatefulWidget {
  const CheckInRiwayatScreen({super.key});

  @override
  State<CheckInRiwayatScreen> createState() => _CheckInRiwayatScreenState();
}

class _CheckInRiwayatScreenState extends State<CheckInRiwayatScreen> {
  List<CheckIn>? _checkIns;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.uid;
    if (uid == null) return;
    final list = await scope.userRepository.getCheckIns(uid);
    if (!mounted) return;
    setState(() => _checkIns = list);
  }

  @override
  Widget build(BuildContext context) {
    final checkIns = _checkIns;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
              child: RiungGlassHeader(title: context.s.checkin.historyTitle),
            ),
            Expanded(
              child: checkIns == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primer))
                  : checkIns.isEmpty
                      ? const _EmptyRiwayat()
                      : _RiwayatBody(checkIns: checkIns),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRiwayat extends StatelessWidget {
  const _EmptyRiwayat();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 130),
            const SizedBox(height: AppSpacing.md),
            Text(context.s.checkin.historyEmpty, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.teksSekunder)),
          ],
        ),
      ),
    );
  }
}

class _RiwayatBody extends StatelessWidget {
  const _RiwayatBody({required this.checkIns});

  final List<CheckIn> checkIns;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last7 = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final byDate = {for (final c in checkIns) c.date.toIso8601String().split('T').first: c};

    final factorCounts = <String, int>{};
    for (final c in checkIns) {
      for (final f in c.factors) {
        factorCounts[f] = (factorCounts[f] ?? 0) + 1;
      }
    }
    final topFactors = factorCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = topFactors.isEmpty ? 1 : topFactors.first.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
      children: [
        RiungGlassCard(
          radius: 30,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.s.checkin.last7Days, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 170,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < last7.length; i++)
                      Expanded(
                        child: _DayBar(
                          date: last7[i],
                          isToday: i == last7.length - 1,
                          checkIn: byDate[last7[i].toIso8601String().split('T').first],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (topFactors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(context.s.checkin.mostFrequent, style: AppTextStyles.title.copyWith(fontSize: 17)),
          const SizedBox(height: AppSpacing.md),
          for (final entry in topFactors.take(3)) _FactorSummaryRow(factorId: entry.key, count: entry.value, fraction: entry.value / maxCount),
        ],
      ],
    );
  }
}

/// Batang mood harian (frame `Hari …`): emoji di atas batang kaca; hari ini
/// bergradien primer.
class _DayBar extends StatelessWidget {
  const _DayBar({required this.date, required this.isToday, required this.checkIn});

  final DateTime date;
  final bool isToday;
  final CheckIn? checkIn;

  @override
  Widget build(BuildContext context) {
    final weight = checkIn == null ? 0.0 : (_moodWeight[checkIn!.mood] ?? 0.4);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(checkIn == null ? '' : (_moodEmoji[checkIn!.mood] ?? ''), style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: 110 * weight + 10,
            decoration: BoxDecoration(
              color: isToday && checkIn != null ? null : AppColors.permukaan,
              gradient: isToday && checkIn != null
                  ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.kabutSage, AppColors.primer])
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.garis),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.s.profil.weekdayShort[date.weekday - 1],
            style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: isToday ? FontWeight.w700 : FontWeight.w500, color: isToday ? AppColors.primer : AppColors.teksSekunder),
          ),
        ],
      ),
    );
  }
}

class _FactorSummaryRow extends StatelessWidget {
  const _FactorSummaryRow({required this.factorId, required this.count, required this.fraction});

  final String factorId;
  final int count;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final factor = checkInFactors.where((f) => f.id == factorId);
    final label = context.s.checkin.factorLabel(factorId);
    final icon = factor.isEmpty ? Icons.circle_outlined : factor.first.icon;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: RiungGlassCard(
        radius: 20,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.primerLembut, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: AppColors.primer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.s.checkin.factorCount(label, count), style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                  const SizedBox(height: 6),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(3)),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      heightFactor: 1,
                      widthFactor: fraction.clamp(0.05, 1.0),
                      child: DecoratedBox(decoration: BoxDecoration(color: AppColors.sekunder, borderRadius: BorderRadius.circular(3))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
