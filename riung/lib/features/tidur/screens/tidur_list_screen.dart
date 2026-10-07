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
      body: RiungGlassBackdrop(
        night: true,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl + MediaQuery.paddingOf(context).bottom),
            children: [
              Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    RiungGlassIconButton(icon: Icons.chevron_left_rounded, night: true, onTap: () => Navigator.of(context).maybePop()),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title, style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.2, color: AppNight.teks)),
                        const SizedBox(height: 4),
                        Text(t.subtitle, style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppNight.teksSekunder)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _FeaturedStoryCard(story: featured, onTap: () => _openStory(featured)),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: _openPengingat,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  decoration: AppNight.card(),
                  child: Row(
                    children: [
                      const Icon(Icons.bedtime_rounded, size: 18, color: AppNight.aksen),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t.reminderTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppNight.teks))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppNight.pil, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(targetTime, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppNight.teks)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(t.sectionSounds, style: AppTextStyles.title.copyWith(fontSize: 17, color: AppNight.teks)),
              const SizedBox(height: 6),
              Text(t.soundsHint, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppNight.teksSekunder)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  for (final sound in soundscapes) ...[
                    if (sound != soundscapes.first) const SizedBox(width: 10),
                    Expanded(
                      child: _SoundTile(
                        icon: _soundIcon(sound.id),
                        label: t.soundLabel(sound.id),
                        active: _playingSound == sound.id,
                        onTap: () => _toggleSound(sound),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(t.sectionStories, style: AppTextStyles.title.copyWith(fontSize: 17, color: AppNight.teks)),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < SleepCatalog.stories.length; i++)
                _StoryRow(story: SleepCatalog.stories[i], icon: _storyIcons[i % _storyIcons.length], onTap: () => _openStory(SleepCatalog.stories[i])),
              const SizedBox(height: AppSpacing.sm),
              Text(t.noSensorNote, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4, color: AppNight.teksRedup)),
            ],
          ),
        ),
      ),
    );
  }

  static const _storyIcons = [Icons.sailing_rounded, Icons.train_rounded, Icons.forest_rounded, Icons.nights_stay_rounded];

  static IconData _soundIcon(String id) => switch (id) {
        'hujan' => Icons.water_drop_rounded,
        'ombak' => Icons.waves_rounded,
        _ => Icons.air_rounded,
      };
}

/// Kartu "Cerita malam ini" (frame `Cerita malam ini`): kaca malam, cahaya,
/// Si Kabut tidur di atas bantal mini, tombol pil terang "Putar".
class _FeaturedStoryCard extends StatelessWidget {
  const _FeaturedStoryCard({required this.story, required this.onTap});

  final SleepStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.tidur;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 250,
        clipBehavior: Clip.antiAlias,
        decoration: AppNight.card(radius: 36, color: AppNight.kacaKuat),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: 10,
              width: 240,
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppNight.cahayaKartu, AppNight.cahayaKartu.withValues(alpha: 0)]),
                ),
              ),
            ),
            const Positioned(
              right: 6,
              top: 36,
              child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 156, cosmetics: ['bantal_mini']),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 160, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.featuredKicker, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppNight.aksen)),
                  const SizedBox(height: 6),
                  Text(t.story(story.id).title, style: AppTextStyles.title.copyWith(fontSize: 22, height: 1.15, color: AppNight.teks)),
                  const SizedBox(height: 6),
                  Text(t.durationReader(story.durationMinutes, story.reader), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppNight.teksSekunder)),
                  const Spacer(),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.fromLTRB(7, 7, 18, 7),
                    decoration: BoxDecoration(color: AppNight.teks, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(color: AppNight.latarAtas, shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, size: 16, color: AppNight.teks),
                        ),
                        const SizedBox(width: 8),
                        Text(t.play, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppNight.latarAtas)),
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

/// Ubin suasana suara (frame `Suara …`): aktif = lavender tembus bertepi aksen.
class _SoundTile extends StatelessWidget {
  const _SoundTile({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 74,
          decoration: BoxDecoration(
            color: active ? AppNight.aksenLembut : AppNight.kaca,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: active ? AppNight.aksen : AppNight.tepi, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(active ? Icons.pause_rounded : icon, size: 24, color: active ? AppNight.teks : AppNight.teksSekunder),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AppNight.teks : AppNight.teksSekunder),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris cerita (frame `Cerita …`): thumbnail gradien berikon, judul, meta,
/// tombol putar / kunci premium.
class _StoryRow extends StatelessWidget {
  const _StoryRow({required this.story, required this.icon, required this.onTap});

  final SleepStory story;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final free = SleepCatalog.isStoryFree(story.id);
    final t = context.s.tidur;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: AppNight.card(),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(gradient: AppNight.thumb, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, size: 22, color: AppColors.kabutLavender),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.story(story.id).title, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppNight.teks)),
                    const SizedBox(height: 3),
                    Text(t.durationReader(story.durationMinutes, story.reader), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppNight.teksSekunder)),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: free ? AppNight.pil : AppNight.aksenLembut, shape: BoxShape.circle),
                child: Icon(free ? Icons.play_arrow_rounded : Icons.lock_rounded, size: 16, color: AppNight.teks),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
