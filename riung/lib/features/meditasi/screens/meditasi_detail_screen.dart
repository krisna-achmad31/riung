import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/meditation_catalog.dart';
import 'meditasi_player_screen.dart';

/// Detail sesi meditasi. Implement persis `design/Meditasi.dc.html`
/// § Detail sesi.
class MeditasiDetailScreen extends StatefulWidget {
  const MeditasiDetailScreen({super.key, required this.session});

  final MeditationSession session;

  @override
  State<MeditasiDetailScreen> createState() => _MeditasiDetailScreenState();
}

class _MeditasiDetailScreenState extends State<MeditasiDetailScreen> {
  late int _durationIndex = widget.session.defaultDurationIndex;

  void _mulaiSesi() {
    final free = MeditationCatalog.isSessionFree(widget.session.id);
    final scope = AppScope.of(context);
    final premiumActive = scope.auth.profile?.premiumNow ?? false;
    if (!free && !premiumActive) {
      final t = scope.language.strings.meditasi;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PremiumLockedScreen(
            title: t.session(widget.session.id).title,
            freeTierNote: t.freeTierNote(EconomyFreeTier.meditasi),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeditasiPlayerScreen(
          session: widget.session,
          durationMinutes: widget.session.durations[_durationIndex],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final t = context.s.meditasi;
    final text = t.session(session.id);
    final monsterId = session.targetMonsterId;
    final monsterName = context.s.common.monsterName(monsterId);
    final tint = AppColors.monsterLembut[monsterId] ?? AppColors.aksenHangatLembut;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            children: [
              RiungGlassHeader(
                title: '',
                trailing: RiungGlassIconButton(
                  icon: Icons.download_done_rounded,
                  semanticLabel: t.download,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.alreadyOffline))),
                ),
              ),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  children: [
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tint, AppColors.kabutLavender]),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                        boxShadow: AppGlass.shadow,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)]),
                            ),
                          ),
                          RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 200, applyBossScale: false),
                          Positioned(
                            left: 16,
                            top: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                              child: Text(
                                t.fighting(monsterName).toUpperCase(),
                                style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.aksenHangatGelap),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(text.title, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.2)),
                    const SizedBox(height: 6),
                    Text(text.description, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, color: AppColors.teksSekunder)),
                    if (session.durations.length > 1) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(t.duration, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksSekunder)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (var i = 0; i < session.durations.length; i++)
                            RiungFilterChip(
                              label: t.minutes(session.durations[i]),
                              selected: i == _durationIndex,
                              selectedColor: AppColors.tinta,
                              onTap: () => setState(() => _durationIndex = i),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    RiungGlassCard(
                      radius: 22,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: AppColors.primerLembut, borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.eco_rounded, size: 18, color: AppColors.primer),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.ambientTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                                const SizedBox(height: 2),
                                Text(t.ambientNote, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _RewardBox(
                            leading: const RiungIcon3D(RiungIcon.koin, size: 34),
                            value: '+${EconomyEarn.meditasi} ${t.coins}',
                            label: t.whenDone,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RewardBox(
                            leading: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 34, applyBossScale: false),
                            value: '+3%',
                            label: t.tame(monsterName),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RiungButton(label: t.startSession, onPressed: _mulaiSesi),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kotak hadiah (frame `Hadiah …`): ikon/monster 3D + nilai + label.
class _RewardBox extends StatelessWidget {
  const _RewardBox({required this.leading, required this.value, required this.label});

  final Widget leading;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(width: 34, height: 34, child: leading),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.teksSekunder)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
