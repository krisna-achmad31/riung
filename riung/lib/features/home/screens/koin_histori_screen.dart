import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Riwayat transaksi koin (earn/spend), dari sub-koleksi audit
/// `coinRequests` (lihat `FirestoreWalletFunctionsService._writeAudit`).
/// Tidak ada file `design/*.dc.html` khusus buat layar ini — dibangun
/// mengikuti pola kartu & tipografi layar riwayat lain (mis. Riwayat mood
/// di Checkin.dc.html) supaya tetap konsisten dengan sistem desain.
class KoinHistoriScreen extends StatefulWidget {
  const KoinHistoriScreen({super.key});

  @override
  State<KoinHistoriScreen> createState() => _KoinHistoriScreenState();
}

class _KoinHistoriScreenState extends State<KoinHistoriScreen> {
  List<CoinTransaction>? _transactions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    final list = await scope.wallet.getTransactions();
    if (!mounted) return;
    setState(() => _transactions = list);
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _transactions;
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
                    child: Text(context.s.home.historyTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactions == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primer))
                  : transactions.isEmpty
                      ? const _EmptyHistori()
                      : _HistoriList(transactions: transactions),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistori extends StatelessWidget {
  const _EmptyHistori();

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
              context.s.home.historyEmpty,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoriList extends StatelessWidget {
  const _HistoriList({required this.transactions});

  final List<CoinTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<CoinTransaction>>{};
    final order = <String>[];
    for (final tx in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(tx.createdAt);
      if (!groups.containsKey(key)) order.add(key);
      groups.putIfAbsent(key, () => []).add(tx);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      children: [
        for (final key in order) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(_labelForDate(context, groups[key]!.first.createdAt), style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          for (final tx in groups[key]!)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _TransactionRow(tx: tx),
            ),
        ],
      ],
    );
  }

  String _labelForDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return context.s.home.today;
    if (target == today.subtract(const Duration(days: 1))) return context.s.home.yesterday;
    return DateFormat('EEEE, d MMMM', context.s.dateLocale).format(date);
  }
}

class _TransactionInfo {
  const _TransactionInfo(this.label, this.icon);
  final String label;
  final IconData icon;
}

String _labelOfReason(HomeStrings t, String key) {
  switch (key) {
    case 'daily_checkin':
      return t.reasonCheckin;
    case 'jurnal':
      return t.reasonJournal;
    case 'meditasi':
      return t.reasonMeditation;
    case 'minigame_win':
      return t.reasonMinigame;
    case 'betterme':
      return t.reasonBetterMe;
    case 'monster_tamed':
      return t.reasonTamed;
    case 'focus_':
      return t.reasonFocus;
    case 'prepaid_focus_sessions':
      return t.reasonPrepaidFocus;
    case 'purchase':
      return t.reasonPurchase;
    case 'cosmetic':
      return t.reasonCosmetic;
    case 'streak_shield':
      return t.reasonStreakShield;
    case 'scroll_unlock':
      return t.reasonScrollUnlock;
    case 'misi_harian':
      return t.reasonMission;
  }
  return key;
}

/// Cocok prefix `reason` (mis. `meditasi:sesi_id` → `meditasi`) ke label &
/// ikon yang enak dibaca. Prefix diambil dari string `reason` sungguhan
/// yang dipakai di seluruh app (grep `reason: '...'`), bukan dikarang.
const Map<String, IconData> _reasonPrefixIcon = {
  'daily_checkin': Icons.wb_sunny_outlined,
  'jurnal': Icons.edit_note,
  'meditasi': Icons.self_improvement,
  'minigame_win': Icons.sports_esports_outlined,
  'betterme': Icons.psychology_outlined,
  'monster_tamed': Icons.emoji_events_outlined,
  'focus_': Icons.center_focus_strong,
  'prepaid_focus_sessions': Icons.confirmation_number_outlined,
  'purchase': Icons.add_card_outlined,
  'cosmetic': Icons.checkroom_outlined,
  'streak_shield': Icons.shield_outlined,
  'scroll_unlock': Icons.lock_open_outlined,
  'misi_harian': Icons.task_alt,
};

_TransactionInfo _infoForReason(HomeStrings t, String reason, bool isEarn) {
  for (final entry in _reasonPrefixIcon.entries) {
    if (reason.startsWith(entry.key)) return _TransactionInfo(_labelOfReason(t, entry.key), entry.value);
  }
  return _TransactionInfo(isEarn ? t.coinIn : t.coinOut, isEarn ? Icons.add_circle_outline : Icons.remove_circle_outline);
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});

  final CoinTransaction tx;

  @override
  Widget build(BuildContext context) {
    final info = _infoForReason(context.s.home, tx.reason, tx.isEarn);
    final color = tx.isEarn ? AppColors.sukses : AppColors.teksSekunder;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
            alignment: Alignment.center,
            child: Icon(info.icon, size: 19, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.label, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 13)),
                Text(DateFormat('HH:mm').format(tx.createdAt), style: AppTextStyles.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${tx.isEarn ? '+' : '-'}${tx.amount}',
            style: AppTextStyles.chipLabel.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
