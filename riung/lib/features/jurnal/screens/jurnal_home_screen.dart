import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/journal_entry.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/journal_prompts.dart';
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
        body: SizedBox.shrink(),
      );
    }
    if (!_unlocked) {
      return Scaffold(
        body: _JurnalTerkunci(onBuka: () {
          setState(() => _checking = true);
          _runGate();
        }),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _JurnalBeranda(entries: _entries, onTulis: _mulaiEntriBaru),
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

/// Beranda jurnal (frame `Glass — Jurnal`): judul + jumlah entri, kartu
/// "Tulis bebas" berikon jurnal 3D, dua panduan CBT, lalu entri terakhir.
class _JurnalBeranda extends StatelessWidget {
  const _JurnalBeranda({required this.entries, required this.onTulis});

  final List<JournalEntry> entries;
  final VoidCallback onTulis;

  @override
  Widget build(BuildContext context) {
    final t = context.s.jurnal;
    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl + MediaQuery.paddingOf(context).bottom),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (Navigator.canPop(context)) ...[
              RiungGlassIconButton(icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.2)),
                  const SizedBox(height: 4),
                  Text(t.lockedSubtitle, style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.teksSekunder)),
                ],
              ),
            ),
            if (entries.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: AppGlass.pill(),
                child: Text(t.entryCount(entries.length), style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksUtama)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _TulisCard(onTap: onTulis),
        const SizedBox(height: AppSpacing.lg),
        Text(t.orCbtGuide, style: AppTextStyles.title.copyWith(fontSize: 17)),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < 2 && i < journalPrompts.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _GuideTile(prompt: journalPrompts[i], onTap: onTulis)),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(t.recentEntries, style: AppTextStyles.title.copyWith(fontSize: 17)),
        const SizedBox(height: AppSpacing.md),
        if (entries.isEmpty)
          RiungGlassCard(
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 96),
                const SizedBox(height: AppSpacing.sm),
                Text(t.emptyTitle, textAlign: TextAlign.center, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                const SizedBox(height: 6),
                Text(t.emptyBody, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5, color: AppColors.teksSekunder)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 13, color: AppColors.teksRedup),
                    const SizedBox(width: 6),
                    Text(t.encryptedNote, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ],
            ),
          )
        else
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _EntryCard(entry: entry),
            ),
      ],
    );
  }
}

/// Kartu "Tulis bebas" (frame `Kartu tulis`).
class _TulisCard extends StatelessWidget {
  const _TulisCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.jurnal;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 190),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.sekunderLembut, AppColors.aksenHangatLembut]),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
          boxShadow: AppGlass.shadow,
        ),
        child: Stack(
          children: [
            const Positioned(right: 10, top: 20, child: RiungIcon3D(RiungIcon.jurnal, size: 150)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 150, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.freeWriteKicker, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.sekunder)),
                  const SizedBox(height: 6),
                  Text(t.freeWriteTitle, style: AppTextStyles.title.copyWith(fontSize: 21, height: 1.15)),
                  const SizedBox(height: 6),
                  Text(t.freeWriteBody, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                  const SizedBox(height: 14),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.tinta, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded, size: 14, color: AppColors.diAtasTinta),
                        const SizedBox(width: 6),
                        Text(t.writeCta(EconomyEarn.jurnal), style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.diAtasTinta)),
                      ],
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

/// Ubin panduan CBT (frame `Panduan …`): thumbnail monster + judul + sub.
class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.prompt, required this.onTap});

  final JournalPrompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.jurnal;
    return RiungGlassCard(
      onTap: onTap,
      radius: 24,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AppColors.monsterLembut[prompt.monsterId] ?? AppColors.kabutSage, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: RiungMonster(monsterId: prompt.monsterId, state: MonsterVisualState.jinak, size: 48, applyBossScale: false),
          ),
          const SizedBox(height: 8),
          Text(t.prompt(prompt.id).title, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, height: 1.25, color: AppColors.teksUtama)),
          const SizedBox(height: 6),
          Text(t.prompt(prompt.id).sub, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.35, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}

/// Kartu entri (frame `Entri`): mood bulat, waktu, cuplikan, tag monster.
class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final JournalEntry entry;

  static const _moodEmoji = {'berat': '😞', 'agak_berat': '😕', 'datar': '😐', 'cukup_baik': '🙂', 'senang': '😄'};

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEEE · HH.mm', context.s.dateLocale);
    return RiungGlassCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => JurnalDetailScreen(entry: entry))),
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: AppColors.permukaan, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(_moodEmoji[entry.mood] ?? '🙂', style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(formatter.format(entry.createdAt), style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksSekunder))),
            ],
          ),
          const SizedBox(height: 8),
          Text(entry.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: AppColors.aksenHangatLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text(entry.tags.first, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.aksenHangatGelap)),
            ),
          ],
        ],
      ),
    );
  }
}
