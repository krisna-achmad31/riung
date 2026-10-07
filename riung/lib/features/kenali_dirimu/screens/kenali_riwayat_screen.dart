import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/kenali_result.dart';
import '../../../core/models/kenali_test.dart';
import '../../../core/services/kenali_result_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/kenali_content.dart';
import '../logic/kenali_navigator.dart';
import '../logic/kenali_progress.dart';
import '../widgets/kenali_entry_row.dart';
import '../widgets/kenali_note_card.dart';

/// Riwayat hasil Kenali Dirimu (tombol jam di header hub): semua percobaan,
/// terbaru dulu, dikelompokkan per bulan. Ketuk satu → layar hasilnya.
/// Data hanya dari perangkat (terenkripsi), tidak pernah dari server.
class KenaliRiwayatScreen extends StatefulWidget {
  const KenaliRiwayatScreen({super.key});

  @override
  State<KenaliRiwayatScreen> createState() => _KenaliRiwayatScreenState();
}

class _KenaliRiwayatScreenState extends State<KenaliRiwayatScreen> {
  Map<String, KenaliTest> _tests = const {};
  AppLanguage? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = context.s.language;
    if (language == _language) return;
    _language = language;
    KenaliContent.loadAll(language).then(
      (t) {
        if (mounted && _language == language) setState(() => _tests = t);
      },
      onError: (Object e) => debugPrint('KenaliRiwayat: gagal memuat tes ($e)'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    final repo = KenaliResultRepository.instance;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.historyTitle),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: repo.revision,
                  builder: (context, _, _) {
                    final history = [
                      for (final r in repo.history)
                        if (KenaliDirimuConfig.byId(r.testId) != null) r,
                    ];
                    return RiungBleedListView(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
                      children: [
                        Text(t.historyIntro, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                        const SizedBox(height: AppSpacing.lg),
                        if (history.isEmpty) const _EmptyHistory() else _HistoryList(history: history, tests: _tests),
                        const SizedBox(height: AppSpacing.xl),
                        KenaliNoteCard(text: t.historyPrivacyNote(KenaliDirimuConfig.riwayatPerTes)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Belum ada hasil: ajakan singkat kembali ke hub.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    return RiungGlassCard(
      radius: 28,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const RiungIcon3D(RiungIcon.kepribadian, size: 64),
          const SizedBox(height: AppSpacing.md),
          Text(t.historyEmptyTitle, textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 17)),
          const SizedBox(height: 6),
          Text(
            t.historyEmptyBody,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder),
          ),
        ],
      ),
    );
  }
}

/// Daftar percobaan dengan judul bulan setiap kali bulannya berganti.
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.history, required this.tests});

  final List<KenaliResult> history;
  final Map<String, KenaliTest> tests;

  @override
  Widget build(BuildContext context) {
    final locale = context.s.dateLocale;
    final month = DateFormat('MMMM y', locale);
    final children = <Widget>[];
    String? lastMonth;
    for (final r in history) {
      final label = month.format(r.completedAt);
      if (label != lastMonth) {
        if (lastMonth != null) children.add(const SizedBox(height: AppSpacing.md));
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(label, style: AppTextStyles.title.copyWith(fontSize: 16)),
        ));
        lastMonth = label;
      }
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _HistoryRow(result: r, test: tests[r.testId]),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

/// Satu percobaan: ilustrasi (monster yang terbangun / ikon topik), tanggal,
/// nama tes, dan judul hasil dalam bahasa aktif.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.result, required this.test});

  final KenaliResult result;
  final KenaliTest? test;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final entry = KenaliDirimuConfig.byId(result.testId)!;
    final monster = KenaliProgress.monsterOf(entry, result);
    final loaded = test;
    return KenaliEntryRow(
      leading: monster != null
          ? RiungMonster(monsterId: monster, state: MonsterVisualState.liar, size: 54, applyBossScale: false)
          : RiungIcon3D(kenaliTopicIcon(entry.topic), size: 34),
      kicker: DateFormat('d MMM y · HH.mm', s.dateLocale).format(result.completedAt).toUpperCase(),
      title: s.kenali.entryTitle(entry.id),
      status: kenaliResultTitle(loaded, result),
      highlight: true,
      onTap: loaded == null
          ? () {}
          : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => KenaliNavigator.resultScreen(entry, loaded, result))),
    );
  }
}
