import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/journal_entry.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'jurnal_detail_screen.dart';
import 'jurnal_pin_recover_screen.dart';
import 'jurnal_pin_setup_screen.dart';
import 'jurnal_pin_unlock_screen.dart';
import 'jurnal_prompt_screen.dart';

/// Gate PIN + daftar entri jurnal. Implement persis `design/Jurnal.dc.html`
/// § Daftar jurnal & § Jurnal kosong.
class JurnalHomeScreen extends StatefulWidget {
  const JurnalHomeScreen({super.key});

  @override
  State<JurnalHomeScreen> createState() => _JurnalHomeScreenState();
}

class _JurnalHomeScreenState extends State<JurnalHomeScreen> {
  bool _unlocked = false;
  bool _checking = true;
  List<JournalEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runGate());
  }

  Future<void> _runGate() async {
    final scope = AppScope.of(context);
    final hasPin = await scope.pinService.hasPin;
    if (!mounted) return;

    Widget gateScreen;
    if (hasPin) {
      gateScreen = const JurnalPinUnlockScreen();
    } else {
      // Belum ada PIN lokal di HP ini — cek apakah user (yang sudah
      // login) pernah bikin PIN di HP lain (lihat Fix: PIN fallback
      // lintas device). Kalau ada, tawarkan pemulihan dulu sebelum
      // dianggap benar-benar belum pernah setup PIN.
      final uid = scope.auth.uid;
      final backup = (uid != null && !scope.auth.isAnonymous) ? await scope.userRepository.getJournalPinBackup(uid) : null;
      if (!mounted) return;
      gateScreen = backup != null ? JurnalPinRecoverScreen(backup: backup) : const JurnalPinSetupScreen();
    }

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => gateScreen,
        fullscreenDialog: true,
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      await _loadEntries();
      setState(() {
        _unlocked = true;
        _checking = false;
      });
    } else if (Navigator.canPop(context)) {
      // Dibuka sebagai layar sendiri: batal berarti kembali.
      Navigator.of(context).maybePop();
    } else {
      // Tab Jurnal di dalam Jelajah: tidak ada layar untuk dikembalikan (pop
      // di sini menutup aplikasi), jadi tetap di tab dengan tombol buka ulang.
      setState(() => _checking = false);
    }
  }

  Future<void> _loadEntries() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.profile?.uid;
    if (uid == null) return;
    final entries = await scope.userRepository.getJournalEntries(uid);
    if (!mounted) return;
    setState(() => _entries = entries);
  }

  Future<void> _mulaiEntriBaru() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.profile?.uid;
    final premiumActive = scope.auth.profile?.premiumNow ?? false;
    if (uid != null && !premiumActive) {
      final hariIni = await scope.userRepository.journalEntryCountForDate(uid, DateTime.now());
      if (!mounted) return;
      if (hariIni >= EconomyFreeTier.jurnalPerHari) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PremiumLockedScreen(
              title: scope.language.strings.jurnal.dailyLimitTitle,
              freeTierNote: scope.language.strings.jurnal.dailyLimitNote,
            ),
          ),
        );
        return;
      }
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const JurnalPromptScreen()),
    );
    if (saved == true) _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.latar,
        body: SizedBox.shrink(),
      );
    }
    if (!_unlocked) {
      return Scaffold(
        backgroundColor: AppColors.latar,
        body: _JurnalTerkunci(onBuka: () {
          setState(() => _checking = true);
          _runGate();
        }),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: _entries.isEmpty ? _JurnalKosong(onTulis: _mulaiEntriBaru) : _JurnalList(entries: _entries, onTulis: _mulaiEntriBaru),
      ),
      floatingActionButton: _entries.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _mulaiEntriBaru,
              backgroundColor: AppColors.aksenHangat,
              foregroundColor: AppColors.latar,
              child: const Icon(Icons.add),
            ),
    );
  }
}

/// Tampilan tab Jurnal saat gerbang PIN dibatalkan: kunci + tombol buka ulang.
class _JurnalTerkunci extends StatelessWidget {
  const _JurnalTerkunci({required this.onBuka});

  final VoidCallback onBuka;

  @override
  Widget build(BuildContext context) {
    final t = context.s.jurnal;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 40, color: AppColors.primer),
              const SizedBox(height: AppSpacing.lg),
              Text(t.lockedTitle, style: AppTextStyles.title.copyWith(fontSize: 20)),
              const SizedBox(height: AppSpacing.sm),
              Text(t.lockedBody, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13)),
              const SizedBox(height: AppSpacing.xl),
              RiungButton(label: t.unlockCta, onPressed: onBuka),
            ],
          ),
        ),
      ),
    );
  }
}

class _JurnalKosong extends StatelessWidget {
  const _JurnalKosong({required this.onTulis});

  final VoidCallback onTulis;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (Navigator.canPop(context)) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(context.s.jurnal.title, style: AppTextStyles.display),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Opacity(
                  opacity: 0.85,
                  child: SizedBox(
                    width: 114,
                    height: 120,
                    child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.liar, size: 114),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(context.s.jurnal.emptyTitle, textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 19)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.s.jurnal.emptyBody,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onTulis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.aksenHangat,
                      foregroundColor: AppColors.latar,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    icon: const Icon(Icons.edit, size: 15),
                    label: Text(context.s.jurnal.writeFirst(EconomyEarn.jurnal), style: AppTextStyles.chipLabel.copyWith(color: AppColors.latar, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 13, color: AppColors.teksRedup),
                    const SizedBox(width: 6),
                    Text(context.s.jurnal.encryptedNote, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _JurnalList extends StatelessWidget {
  const _JurnalList({required this.entries, required this.onTulis});

  final List<JournalEntry> entries;
  final VoidCallback onTulis;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 90),
      children: [
        Row(
          children: [
            if (Navigator.canPop(context)) ...[
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.s.jurnal.title, style: AppTextStyles.display),
                  Text(context.s.jurnal.lockedSubtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.kartu, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text(context.s.jurnal.entryCount(entries.length), style: AppTextStyles.caption.copyWith(color: AppColors.aksenHangat, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _WeekStrip(entries: entries),
        const SizedBox(height: AppSpacing.lg),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _EntryCard(entry: entry),
          ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.entries});

  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final dayLabels = context.s.profil.weekdayShort;
    final entryDates = entries.map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day)).toSet();

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Builder(builder: (context) {
            final date = monday.add(Duration(days: i));
            final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
            final hasEntry = entryDates.contains(date);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primer.withValues(alpha: 0.14) : AppColors.permukaan,
                    border: Border.all(color: isToday ? AppColors.primer : AppColors.garis),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(dayLabels[i], style: AppTextStyles.caption.copyWith(fontSize: 10, color: isToday ? AppColors.primer : AppColors.teksRedup)),
                      const SizedBox(height: 3),
                      Text('${date.day}', style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: isToday ? AppColors.primer : AppColors.teksUtama)),
                      const SizedBox(height: 3),
                      Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: hasEntry ? AppColors.aksenHangat : Colors.transparent)),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final JournalEntry entry;

  static const _moodEmoji = {'berat': '😞', 'agak_berat': '😕', 'datar': '😟', 'cukup_baik': '🙂', 'senang': '😄'};

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEEE, HH:mm', context.s.dateLocale);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => JurnalDetailScreen(entry: entry))),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.xxl)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_moodEmoji[entry.mood] ?? '🙂', style: const TextStyle(fontSize: 17)),
                const SizedBox(width: 8),
                Expanded(child: Text(formatter.format(entry.createdAt), style: AppTextStyles.caption.copyWith(fontSize: 11))),
                if (entry.tags.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.sekunder), borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text(entry.tags.first, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.sekunder)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
