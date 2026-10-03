import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/sleep_catalog.dart';
import 'tidur_detail_screen.dart';
import 'tidur_pengingat_screen.dart';

/// Beranda tidur. Implement persis `design/Tidur.dc.html` § Beranda tidur.
class TidurListScreen extends StatefulWidget {
  const TidurListScreen({super.key});

  @override
  State<TidurListScreen> createState() => _TidurListScreenState();
}

class _TidurListScreenState extends State<TidurListScreen> {
  final _ambientPlayer = AudioPlayer();
  String? _playingSound;

  @override
  void dispose() {
    _ambientPlayer.dispose();
    super.dispose();
  }

  /// Ketuk suasana suara: putar berulang; ketuk lagi (atau ketuk yang lain)
  /// untuk berhenti / ganti.
  Future<void> _toggleSound(Soundscape sound) async {
    if (_playingSound == sound.id) {
      await _ambientPlayer.stop();
      if (mounted) setState(() => _playingSound = null);
      return;
    }
    setState(() => _playingSound = sound.id);
    try {
      await _ambientPlayer.setAsset(sound.assetPath);
      await _ambientPlayer.setLoopMode(LoopMode.one);
      await _ambientPlayer.play();
    } catch (_) {
      if (mounted) setState(() => _playingSound = null);
    }
  }
  void _openStory(SleepStory story) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TidurDetailScreen(story: story)));
  }

  Future<void> _openPengingat() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TidurPengingatScreen()));
    if (mounted) setState(() {}); // chip jam target ikut berubah
  }

  static String _formatTime(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = context.s.tidur;
    final featured = SleepCatalog.stories.first;
    final targetTime = _formatTime(AppScope.of(context).prefs.sleepReminder.targetMinutes);
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: AppColors.monsterCermin,
        alignment: const Alignment(0, -1.3),
        opacity: 0.1,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
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
                        Text(t.title, style: AppTextStyles.display.copyWith(fontSize: 22)),
                        Text(t.subtitle, style: AppTextStyles.caption.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _openPengingat,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.kartu,
                        border: Border.all(color: AppColors.garis),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.nightlight_round, size: 14, color: AppColors.primer),
                          const SizedBox(width: 6),
                          Text(targetTime, style: AppTextStyles.caption.copyWith(color: AppColors.primer, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.permukaan, AppColors.latar]),
                  border: Border.all(color: AppColors.garis),
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.featuredKicker, style: AppTextStyles.caption.copyWith(color: AppColors.monsterCermin, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 10)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(t.story(featured.id).title, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 17)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(t.story(featured.id).blurb, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45)),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _openStory(featured),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(color: AppColors.primer, borderRadius: BorderRadius.circular(11)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.play_arrow, size: 13, color: AppColors.latar),
                                      const SizedBox(width: 6),
                                      Text(t.play, style: AppTextStyles.caption.copyWith(color: AppColors.latar, fontWeight: FontWeight.w700, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(t.durationReader(featured.durationMinutes, featured.reader), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 82,
                      height: 86,
                      child: RiungMonster(monsterId: 'meronta', state: MonsterVisualState.jinak, size: 82),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(t.sectionStories, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 15)),
              const SizedBox(height: AppSpacing.sm),
              for (final story in SleepCatalog.stories) _StoryRow(story: story, onTap: () => _openStory(story)),
              const SizedBox(height: AppSpacing.md),
              Text(t.sectionSounds, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 15)),
              const SizedBox(height: AppSpacing.xs),
              Text(t.soundsHint, style: AppTextStyles.caption.copyWith(fontSize: 11)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (final sound in soundscapes)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: sound == soundscapes.last ? 0 : AppSpacing.sm),
                        child: GestureDetector(
                          onTap: () => _toggleSound(sound),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: _playingSound == sound.id ? AppColors.primer.withValues(alpha: 0.12) : AppColors.permukaan,
                              border: Border.all(color: _playingSound == sound.id ? AppColors.primer : AppColors.garis, width: _playingSound == sound.id ? 1.5 : 1),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Column(
                              children: [
                                Icon(_playingSound == sound.id ? Icons.pause_rounded : Icons.graphic_eq, size: 22, color: AppColors.primer),
                                const SizedBox(height: AppSpacing.xs),
                                Text(t.soundLabel(sound.id), style: AppTextStyles.chipLabel.copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryRow extends StatelessWidget {
  const _StoryRow({required this.story, required this.onTap});

  final SleepStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final free = SleepCatalog.isStoryFree(story.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.permukaan,
            border: Border.all(color: AppColors.garis),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.primer.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: const Icon(Icons.nightlight_round, size: 21, color: AppColors.primer),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.s.tidur.story(story.id).title, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14)),
                    Text(context.s.tidur.durationReader(story.durationMinutes, story.reader), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Icon(free ? Icons.play_arrow : Icons.lock, size: free ? 18 : 15, color: free ? AppColors.primer : AppColors.teksRedup),
            ],
          ),
        ),
      ),
    );
  }
}
