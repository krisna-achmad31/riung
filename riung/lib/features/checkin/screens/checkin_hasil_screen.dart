import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../home/screens/root_shell_screen.dart';
import '../../jurnal/screens/jurnal_home_screen.dart';
import '../../meditasi/logic/meditation_catalog.dart';
import '../../meditasi/screens/meditasi_detail_screen.dart';
import '../logic/checkin_draft.dart';

/// Hasil check-in — perayaan hangat + saran. Implement persis
/// `design/Checkin.dc.html` § Hasil check-in.
class CheckInHasilScreen extends StatelessWidget {
  const CheckInHasilScreen({super.key, required this.draft});

  final CheckInDraft draft;

  void _mulaiHariku(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootShellScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.checkin;
    final showHakimInsight = draft.factorIds.contains('kerjaan') && draft.factorIds.contains('takut_gagal');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            children: [
              Expanded(
                child: RiungBleedListView(
                  children: [
                    const _Sparkles(),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.resultTitle, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.15)),
                    const SizedBox(height: AppSpacing.lg),
                    ListenableBuilder(
                      listenable: scope.streak,
                      builder: (context, _) => Row(
                        children: [
                          Expanded(
                            child: RiungStatTile(
                              leading: const RiungIcon3D(RiungIcon.koin, size: 44),
                              value: '+${EconomyEarn.checkinHarian}',
                              label: t.coinsLabel,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RiungStatTile(
                              leading: const RiungIcon3D(RiungIcon.streak, size: 44),
                              value: '${scope.streak.current}',
                              label: t.daysInARow,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.suggestionsLabel.toUpperCase(), style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup)),
                    const SizedBox(height: AppSpacing.md),
                    _SuggestionRow(
                      leading: const RiungIcon3D(RiungIcon.meditasi, size: 50),
                      title: t.suggestionPauseTitle,
                      subtitle: t.suggestionPauseSub,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MeditasiDetailScreen(session: MeditationCatalog.byId('jeda_kerja'))),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SuggestionRow(
                      leading: const RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 50, applyBossScale: false),
                      title: t.suggestionCbtTitle,
                      subtitle: t.suggestionCbtSub,
                      // Lewat JurnalHomeScreen supaya gerbang PIN jurnal tetap berlaku.
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JurnalHomeScreen())),
                    ),
                    if (showHakimInsight) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AppGlass.card(radius: 22, color: AppColors.sekunderLembut.withValues(alpha: 0.7), shadowed: false),
                        child: Text(t.resultHakimInsight, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksUtama)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RiungButton(label: t.startMyDay, onPressed: () => _mulaiHariku(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Si Kabut jinak dengan aura & kilau emas (frame `Perayaan`).
class _Sparkles extends StatelessWidget {
  const _Sparkles();

  @override
  Widget build(BuildContext context) {
    Widget spark(double size) => Icon(Icons.auto_awesome, size: size, color: AppColors.emas);
    return Center(
      child: SizedBox(
        width: 350,
        height: 220,
        child: Stack(
          children: [
            Positioned(
              left: 65,
              top: 0,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
              ),
            ),
            const Positioned(left: 80, top: 14, child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 190)),
            Positioned(left: 60, top: 40, child: spark(20)),
            Positioned(left: 280, top: 50, child: spark(16)),
            Positioned(left: 290, top: 170, child: spark(18)),
          ],
        ),
      ),
    );
  }
}

/// Baris saran (frame `Saran …`): thumbnail kaca + judul + tombol putar tinta.
class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.leading, required this.title, required this.subtitle, required this.onTap});

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      onTap: onTap,
      radius: 24,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            child: leading,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.35, color: AppColors.teksSekunder)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.tinta, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.diAtasTinta),
          ),
        ],
      ),
    );
  }
}
