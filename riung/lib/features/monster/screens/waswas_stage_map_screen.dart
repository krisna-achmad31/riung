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

  _StageNode _nodeFor(WaswasStepType step, MonsterStrings t, Color color) {
    switch (step) {
      case WaswasStepType.jurnal:
        return _StageNode(
          icon: Icons.edit_note_rounded,
          color: color,
          title: t.stageNodeJournalTitle,
          subtitle: _doneToday.contains('jurnal') ? t.stageNodeJournalDone : null,
          done: _doneToday.contains('jurnal'),
          doneLabel: t.stageNodeLabelDone,
          onTap: _bukaJurnal,
        );
      case WaswasStepType.napas:
        return _StageNode(
          icon: Icons.spa_rounded,
          color: color,
          title: t.stageNodeBreathTitle,
          subtitle: _doneToday.contains('napas') ? t.stageNodeBreathDone : null,
          done: _doneToday.contains('napas'),
          doneLabel: t.stageNodeLabelDone,
          onTap: _bukaNapas,
        );
      case WaswasStepType.afirmasi:
        return _StageNode(
          icon: Icons.favorite_rounded,
          color: color,
          title: t.stageNodeAfirmasiTitle,
          subtitle: _doneToday.contains('afirmasi') ? t.stageNodeAfirmasiDone : null,
          done: _doneToday.contains('afirmasi'),
          doneLabel: t.stageNodeLabelDone,
          onTap: _bukaAfirmasi,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.monster;
    final scope = AppScope.of(context);
    final color = AppColors.monsterWaswas;

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: scope.monsterProgress,
          builder: (context, _) {
            final progress = scope.monsterProgress.progressOf(widget.saboteur.id) ?? MonsterProgress.initial(widget.saboteur.id);
            final level = waswasLevelForProgress(progress.progress);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder)),
                      Expanded(child: Text(t.stageMapTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(t.stageLevelLabel(level.level), style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    children: [
                      Text(t.stageMapIntro, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
                      const SizedBox(height: AppSpacing.lg),
                      RiungOwlTip(message: t.stageOwlIntro),
                      const SizedBox(height: AppSpacing.xxl),
                      for (final step in level.steps) ...[
                        _nodeFor(step, t, color),
                        _StagePath(color: color),
                      ],
                      _StageNode(
                        icon: Icons.bolt_rounded,
                        color: color,
                        title: t.stageNodeBossTitle,
                        subtitle: t.stageNodeBossSub(progress.progress),
                        done: false,
                        big: true,
                        doneLabel: t.stageNodeLabelDone,
                        onTap: _bukaHadapi,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
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

class _StagePath extends StatelessWidget {
  const _StagePath({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 3,
        height: 28,
        child: DecoratedBox(decoration: BoxDecoration(color: color.withValues(alpha: 0.35))),
      ),
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.icon,
    required this.color,
    required this.title,
    required this.done,
    required this.doneLabel,
    required this.onTap,
    this.subtitle,
    this.big = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool done;
  final String doneLabel;
  final bool big;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = big ? 76.0 : 62.0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: big ? color : AppColors.garis, width: big ? 1.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(icon, size: big ? 32 : 24, color: color),
                ),
                if (done)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: AppColors.sukses, shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 12, color: AppColors.latar),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: big ? 15 : 14, color: AppColors.teksUtama)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: AppTextStyles.caption.copyWith(fontSize: 11, color: done ? AppColors.sukses : AppColors.teksRedup)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.teksRedup),
          ],
        ),
      ),
    );
  }
}
