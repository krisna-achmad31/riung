import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../afirmasi/logic/affirmation_deck.dart';
import '../../afirmasi/screens/afirmasi_kartu_screen.dart';
import '../../jurnal/logic/journal_prompts.dart';
import '../../jurnal/screens/jurnal_editor_screen.dart';
import '../../minigame/screens/minigame_intro_screen.dart';
import '../logic/waswas_level_config.dart';
import '../widgets/waswas_stage_path.dart';
import 'waswas_breathing_node_screen.dart';

/// Peta latihan Si Waswas — uji coba konsep "jalur ala Duolingo" sebelum
/// direplikasi ke saboteur lain: beberapa level (unit), tiap level berisi 2
/// step latihan kecil (napas/jurnal/afirmasi, lihat `waswas_level_config.dart`)
/// menuju node "hadapi" (bos level itu). Node latihan menyegarkan diri tiap
/// hari baru; node hadapi selalu terbuka kapan pun (tiket & batas hariannya
/// sendiri sudah dijaga di alur serangan yang ada).
///
/// Sengaja TIDAK mengunci node — semua bisa disentuh kapan pun (v1 uji
/// coba). Centang cuma penanda "sudah dilakukan hari ini", bukan gerbang.
/// Level dihitung ULANG tiap build dari `MonsterProgress.progress` — tidak
/// disimpan sebagai field baru (lihat `waswasLevelForProgress`).
class WaswasStageMapScreen extends StatefulWidget {
  const WaswasStageMapScreen({super.key, required this.saboteur});

  final Saboteur saboteur;

  @override
  State<WaswasStageMapScreen> createState() => _WaswasStageMapScreenState();
}

class _WaswasStageMapScreenState extends State<WaswasStageMapScreen> {
  Set<String> _doneToday = {};

  @override
  void initState() {
    super.initState();
    _muat();
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _muat() {
    final saved = AppScope.of(context).prefs.waswasStageJson;
    if (saved['date'] != _todayKey()) return;
    setState(() => _doneToday = {...(saved['done'] as List? ?? const [])}.cast<String>());
  }

  Future<void> _tandaiSelesai(String nodeId) async {
    final scope = AppScope.of(context);
    final done = {..._doneToday, nodeId};
    setState(() => _doneToday = done);
    await scope.prefs.setWaswasStageJson({'date': _todayKey(), 'done': done.toList()});
  }

  Future<void> _bukaJurnal() async {
    final prompt = journalPrompts.firstWhere((p) => p.monsterId == 'waswas', orElse: () => journalPrompts.first);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => JurnalEditorScreen(prompt: prompt)),
    );
    if (saved == true && mounted) _tandaiSelesai('jurnal');
  }

  Future<void> _bukaNapas() async {
    final selesai = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const WaswasBreathingNodeScreen()),
    );
    if (selesai == true && mounted) _tandaiSelesai('napas');
  }

  Future<void> _bukaAfirmasi() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.profile?.uid;
    final seeded = await scope.contentRepository.getAffirmations();
    final custom = uid == null ? <Affirmation>[] : await scope.userRepository.getCustomAffirmations(uid);
    if (!mounted) return;
    final decks = buildAffirmationDecks(seeded: seeded, custom: custom);
    final deck = decks.where((d) => d.monsterId == 'waswas' && d.cards.isNotEmpty).firstOrNull;
    if (deck == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AfirmasiKartuScreen(deck: deck)));
    if (mounted) _tandaiSelesai('afirmasi');
  }

  void _bukaHadapi() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MinigameIntroScreen(saboteur: widget.saboteur)));
  }

  /// Node latihan untuk satu step. Node "sekarang" = node pertama yang
  /// belum dilakukan hari ini (tidak mengunci yang lain, v1 uji coba).
  StageStep _stepFor(WaswasStepType step, MonsterStrings t, int level, bool isCurrent) {
    final (id, icon, title, doneText, onTap) = switch (step) {
      WaswasStepType.jurnal => ('jurnal', RiungIcon.jurnal, t.stageNodeJournalTitle, t.stageNodeJournalDone, _bukaJurnal),
      WaswasStepType.napas => ('napas', RiungIcon.meditasi, t.stageNodeBreathTitle, t.stageNodeBreathDone, _bukaNapas),
      WaswasStepType.afirmasi => ('afirmasi', RiungIcon.afirmasi, t.stageNodeAfirmasiTitle, t.stageNodeAfirmasiDone, _bukaAfirmasi),
    };
    final done = _doneToday.contains(id);
    final status = done ? StageNodeStatus.done : (isCurrent ? StageNodeStatus.current : StageNodeStatus.upcoming);
    return StageStep(
      icon: icon,
      caption: done ? '${t.stageLevelLabel(level)} · ${t.stageNodeLabelDone}' : t.stageLevelLabel(level),
      title: title,
      subtitle: switch (status) {
        StageNodeStatus.done => doneText,
        StageNodeStatus.current => t.stageNodeStartHere,
        StageNodeStatus.upcoming => null,
      },
      status: status,
      onTap: onTap,
    );
  }

  static String _stepId(WaswasStepType s) => s.name;

  @override
  Widget build(BuildContext context) {
    final t = context.s.monster;
    final scope = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: scope.monsterProgress,
          builder: (context, _) {
            final progress = scope.monsterProgress.progressOf(widget.saboteur.id) ?? MonsterProgress.initial(widget.saboteur.id);
            final level = waswasLevelForProgress(progress.progress);
            final currentIndex = level.steps.indexWhere((st) => !_doneToday.contains(_stepId(st)));
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
              children: [
                RiungGlassHeader(title: t.stageMapTitle),
                const SizedBox(height: AppSpacing.md),
                Text(t.stageMapIntro, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSpacing.md),
                RiungOwlTip(message: t.stageOwlIntro),
                const SizedBox(height: AppSpacing.md),
                WaswasStagePath(
                  steps: [
                    for (var i = 0; i < level.steps.length; i++) _stepFor(level.steps[i], t, level.level, i == currentIndex),
                  ],
                  boss: StageBoss(
                    monsterId: widget.saboteur.id,
                    caption: t.stageNodeBossLabel(progress.progress),
                    title: t.stageNodeBossTitle,
                    subtitle: t.stageNodeBossSub(progress.progress),
                    onTap: _bukaHadapi,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
