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
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder),
                  ),
                  Expanded(
                    child: Text(context.s.checkin.historyTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: checkIns == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primer))
                  : checkIns.isEmpty
                      ? _EmptyRiwayat()
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
            const SizedBox(
              width: 100,
              height: 105,
              child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 100),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.s.checkin.historyEmpty,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.permukaan,
              border: Border.all(color: AppColors.garis),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.s.checkin.last7Days, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final date in last7)
                        Expanded(
                          child: _DayBar(
                            date: date,
                            checkIn: byDate[date.toIso8601String().split('T').first],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (topFactors.isNotEmpty) ...[
            Text(context.s.checkin.mostFrequent, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in topFactors.take(3)) _FactorSummaryRow(factorId: entry.key, count: entry.value),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.date, required this.checkIn});

  final DateTime date;
  final CheckIn? checkIn;

  @override
  Widget build(BuildContext context) {
    final weight = checkIn == null ? 0.0 : (_moodWeight[checkIn!.mood] ?? 0.4);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(checkIn == null ? '' : (_moodEmoji[checkIn!.mood] ?? ''), style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 60 * weight + 4,
            decoration: BoxDecoration(
              color: checkIn == null ? AppColors.garis : AppColors.primer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(3)),
            ),
          ),
          const SizedBox(height: 4),
          Text(context.s.profil.weekdayShort[date.weekday - 1], style: AppTextStyles.caption.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

class _FactorSummaryRow extends StatelessWidget {
  const _FactorSummaryRow({required this.factorId, required this.count});

  final String factorId;
  final int count;

  @override
  Widget build(BuildContext context) {
    final factor = checkInFactors.where((f) => f.id == factorId);
    final label = context.s.checkin.factorLabel(factorId);
    final icon = factor.isEmpty ? Icons.circle : factor.first.icon;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.teksSekunder),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.s.checkin.factorCount(label, count),
                style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
