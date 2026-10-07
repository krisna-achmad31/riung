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
    final scope = AppScope.of(context);
    final t = context.s.home;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.historyTitle),
              const SizedBox(height: AppSpacing.md),
              ListenableBuilder(
                listenable: scope.wallet,
                builder: (context, _) => RiungGlassCard(
                  radius: 30,
                  color: AppColors.permukaan,
                  child: Row(
                    children: [
                      const RiungIcon3D(RiungIcon.koin, size: 72),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${scope.wallet.coins}', style: AppTextStyles.display.copyWith(fontSize: 36, height: 1.15)),
                          Text(t.coinsUnit, style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.teksSekunder)),
                        ],
                      ),
                    ],
                  ),
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

    return RiungBleedListView(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xxl),
      children: [
        for (final key in order) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
            child: Text(_labelForDate(context, groups[key]!.first.createdAt), style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksSekunder)),
          ),
          for (final tx in groups[key]!)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
  final RiungIcon icon;
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
/// ikon 3D. Prefix diambil dari string `reason` sungguhan yang dipakai di
/// seluruh app (grep `reason: '...'`), bukan dikarang.
const Map<String, RiungIcon> _reasonPrefixIcon = {
  'daily_checkin': RiungIcon.checkin,
  'jurnal': RiungIcon.jurnal,
  'meditasi': RiungIcon.meditasi,
  'minigame_win': RiungIcon.tiket,
  'betterme': RiungIcon.kepribadian,
  'monster_tamed': RiungIcon.premium,
  'focus_': RiungIcon.fokus,
  'prepaid_focus_sessions': RiungIcon.fokus,
  'purchase': RiungIcon.koin,
  'cosmetic': RiungIcon.premium,
  'streak_shield': RiungIcon.pelindung,
  'scroll_unlock': RiungIcon.aplikasiBeku,
  'misi_harian': RiungIcon.streak,
};

_TransactionInfo _infoForReason(HomeStrings t, String reason, bool isEarn) {
  for (final entry in _reasonPrefixIcon.entries) {
    if (reason.startsWith(entry.key)) return _TransactionInfo(_labelOfReason(t, entry.key), entry.value);
  }
  return _TransactionInfo(isEarn ? t.coinIn : t.coinOut, RiungIcon.koin);
}

/// Baris transaksi (frame `Transaksi …`): thumbnail ikon 3D, label, waktu,
/// nilai (+ primer / − persik tua).
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});

  final CoinTransaction tx;

  @override
  Widget build(BuildContext context) {
    final t = context.s.home;
    final info = _infoForReason(t, tx.reason, tx.isEarn);
    return RiungGlassCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: RiungIcon3D(info.icon, size: 38),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.label, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                Text(
                  '${tx.isEarn ? t.coinIn : t.coinOut} · ${DateFormat('HH.mm').format(tx.createdAt)}',
                  style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isEarn ? '+' : '−'}${tx.amount}',
            style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: tx.isEarn ? AppColors.primer : AppColors.aksenHangatGelap),
          ),
        ],
      ),
    );
  }
}
