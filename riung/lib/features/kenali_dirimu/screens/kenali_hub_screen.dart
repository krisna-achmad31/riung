import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/kenali_test.dart';
import '../../../core/models/personality_result.dart';
import '../../../core/services/kenali_result_repository.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../kepribadian/logic/character_spec.dart';
import '../../kepribadian/screens/kepribadian_hasil_screen.dart';
import '../../kepribadian/screens/kepribadian_quiz_screen.dart';
import '../../kepribadian/widgets/character_avatar.dart';
import '../../profil/screens/bantuan_krisis_screen.dart';
import '../logic/kenali_content.dart';
import '../logic/kenali_navigator.dart';
import '../logic/kenali_progress.dart';
import '../widgets/kenali_entry_row.dart';
import '../widgets/kenali_section_header.dart';
import 'kenali_riwayat_screen.dart';

/// Hub "Kenali Dirimu" (frame `Glass — Kenali Dirimu · Hub`): Kuis Besar
/// (membangunkan Monster Kebiasaan), Kepribadian, Diri & Relasi, dan
/// Kesehatan Mental (tanpa monster). Tab: Semua / Kuis Besar / Tes.
class KenaliHubScreen extends StatefulWidget {
  const KenaliHubScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<KenaliHubScreen> createState() => _KenaliHubScreenState();
}

class _KenaliHubScreenState extends State<KenaliHubScreen> {
  late int _tab = widget.initialTab;
  Map<String, KenaliTest> _tests = const {};

  AppLanguage? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Muat ulang saat bahasa berganti supaya judul hasil ikut bahasanya.
    final language = context.s.language;
    if (language == _language) return;
    _language = language;
    KenaliContent.loadAll(language).then(
      (t) {
        if (mounted && _language == language) setState(() => _tests = t);
      },
      onError: (Object e) => debugPrint('KenaliHub: gagal memuat tes ($e)'),
    );
  }

  bool _show(KenaliSection s) => switch (_tab) {
        1 => s == KenaliSection.kuisBesar,
        2 => s != KenaliSection.kuisBesar,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    final prefs = AppScope.of(context).prefs;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(
                title: t.title,
                trailing: RiungGlassIconButton(
                  icon: Icons.history_rounded,
                  semanticLabel: t.historyButton,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KenaliRiwayatScreen())),
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: Listenable.merge([KenaliResultRepository.instance.revision, prefs.personalityRevision]),
                  builder: (context, _) {
                    final personality = prefs.personalityResults;
                    return RiungBleedListView(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
                      children: [
                        _HubIntro(done: KenaliProgress.doneCount(personality), total: KenaliDirimuConfig.totalTes),
                        const SizedBox(height: AppSpacing.lg),
                        RiungSegmentedTabs(labels: [t.tabAll, t.tabKuis, t.tabTes], index: _tab, onChanged: (i) => setState(() => _tab = i)),
                        for (final section in KenaliSection.values)
                          if (_show(section)) ...[
                            const SizedBox(height: AppSpacing.xl),
                            KenaliSectionHeader(title: t.sectionTitle(section), subtitle: t.sectionSub(section)),
                            const SizedBox(height: AppSpacing.md),
                            if (section == KenaliSection.kepribadian)
                              _KepribadianRows(results: personality)
                            else
                              for (final entry in KenaliDirimuConfig.inSection(section))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _EntryRow(entry: entry, test: _tests[entry.id]),
                                ),
                            if (section == KenaliSection.kesehatan)
                              Text(t.healthPrivacyNote, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, color: AppColors.teksSekunder)),
                          ],
                        const SizedBox(height: AppSpacing.xl),
                        const _HubFooter(),
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

/// Judul besar, intro, dan progres "7 dari 26 selesai".
class _HubIntro extends StatelessWidget {
  const _HubIntro({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.hubHeading, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
        const SizedBox(height: 6),
        Text(t.hubIntro, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
        const SizedBox(height: AppSpacing.md),
        RiungProgressBar(value: total == 0 ? 0 : done / total, colors: const [AppColors.kabutLavender, AppColors.sekunder]),
        const SizedBox(height: 6),
        Text(t.hubProgress(done, total), style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksSekunder)),
      ],
    );
  }
}

/// Satu baris tes/kuis dengan pil status sesuai hasil tersimpan.
class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.test});

  final KenaliEntry entry;
  final KenaliTest? test;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = s.kenali;
    final result = KenaliResultRepository.instance.resultOf(entry.id);
    final q = test?.questions.length;
    final meta = q == null ? null : t.meta(q, KenaliDirimuConfig.menitUntuk(q));
    final linked = result == null ? entry.monsterId : KenaliProgress.monsterOf(entry, result);

    String? status;
    var highlight = false;
    Widget leading = RiungIcon3D(kenaliTopicIcon(entry.topic), size: 34);

    switch (entry.section) {
      case KenaliSection.kuisBesar:
        final monster = entry.monsterId!;
        final awake = result != null && linked == monster;
        leading = Opacity(
          opacity: result == null ? 0.55 : 1,
          child: RiungMonster(monsterId: monster, state: MonsterVisualState.liar, size: 54, applyBossScale: false),
        );
        if (result == null) {
          status = meta;
        } else {
          highlight = awake;
          status = awake ? t.awoke(s.common.monsterName(monster)) : t.asleepChip(s.common.monsterName(monster));
        }
      case KenaliSection.diriRelasi:
        if (linked != null) leading = RiungMonster(monsterId: linked, state: MonsterVisualState.liar, size: 54, applyBossScale: false);
        if (result != null) {
          highlight = true;
          status = kenaliResultTitle(test, result);
        } else {
          status = linked != null ? s.common.monsterName(linked) : (entry.badge ? t.badgeChip : meta);
        }
      case KenaliSection.kesehatan:
        if (result != null) {
          highlight = true;
          status = '${kenaliResultTitle(test, result)} · ${DateFormat('d MMM', s.dateLocale).format(result.completedAt)}';
        } else {
          status = meta;
        }
      case KenaliSection.kepribadian:
        break;
    }

    return KenaliEntryRow(
      leading: leading,
      kicker: t.topicLabel(entry.topic),
      title: t.entryTitle(entry.id),
      status: status,
      highlight: highlight,
      onTap: () => KenaliNavigator.open(context, entry),
    );
  }
}

/// Tiga tes kepribadian lama (fitur `kepribadian/`) — hasilnya membuka
/// karakter pendamping.
class _KepribadianRows extends StatelessWidget {
  const _KepribadianRows({required this.results});

  final Map<PersonalityTest, PersonalityResult> results;

  static const _order = [PersonalityTest.jung, PersonalityTest.attachment, PersonalityTest.temperament];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final test in _order)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _KepribadianRow(test: test, result: results[test]),
          ),
      ],
    );
  }
}

class _KepribadianRow extends StatelessWidget {
  const _KepribadianRow({required this.test, required this.result});

  final PersonalityTest test;
  final PersonalityResult? result;

  static CharacterSpec _placeholder(PersonalityTest test) => switch (test) {
        PersonalityTest.jung => CharacterSpec.jung('INFP'),
        PersonalityTest.temperament => CharacterSpec.temperament('melankolis'),
        PersonalityTest.attachment => CharacterSpec.attachment('aman'),
      };

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    final k = context.s.kepribadian;
    final r = result;
    final status = r == null
        ? t.openCharacter
        : switch (test) {
            PersonalityTest.jung => r.code,
            PersonalityTest.temperament => k.temperament(r.code).name,
            PersonalityTest.attachment => k.attachment(r.code).name,
          };
    return KenaliEntryRow(
      leading: Opacity(
        opacity: r == null ? 0.55 : 1,
        child: CharacterAvatar(spec: r == null ? _placeholder(test) : CharacterSpec.fromResult(r), size: 48),
      ),
      kicker: t.topicLabel(KenaliTopic.kepribadian),
      title: switch (test) {
        PersonalityTest.jung => t.kepribadianJung,
        PersonalityTest.attachment => t.kepribadianAttachment,
        PersonalityTest.temperament => t.kepribadianTemperament,
      },
      status: status,
      highlight: r != null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => r == null ? KepribadianQuizScreen(test: test) : KepribadianHasilScreen(result: r)),
      ),
    );
  }
}

/// Catatan penutup + tautan Bantuan krisis (selalu bisa diakses).
class _HubFooter extends StatelessWidget {
  const _HubFooter();

  @override
  Widget build(BuildContext context) {
    final t = context.s.kenali;
    final style = AppTextStyles.caption.copyWith(fontSize: 11, height: 1.45, color: AppColors.teksRedup);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BantuanKrisisScreen())),
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: t.hubFooter),
            TextSpan(text: t.hubFooterCrisis, style: style.copyWith(fontWeight: FontWeight.w700, color: AppColors.primer, decoration: TextDecoration.underline)),
          ],
        ),
      ),
    );
  }
}
