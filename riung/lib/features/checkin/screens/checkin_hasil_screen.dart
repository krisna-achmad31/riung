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
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        alignment: const Alignment(0, -1),
        opacity: 0.16,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 110,
                        height: 116,
                        child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 110),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        t.resultTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display.copyWith(fontSize: 22, height: 1.3),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ListenableBuilder(
                        listenable: scope.streak,
                        builder: (context, _) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatBox(
                              icon: Icons.monetization_on,
                              iconColor: AppColors.aksenHangat,
                              value: '+${EconomyEarn.checkinHarian}',
                              label: t.coinsLabel,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _StatBox(
                              icon: Icons.local_fire_department,
                              iconColor: AppColors.aksenHangat,
                              value: '${scope.streak.current}',
                              label: t.daysInARow,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.permukaan,
                          border: Border.all(color: AppColors.garis),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.suggestionsLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.monsterCermin,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _SuggestionRow(
                              icon: Icons.self_improvement,
                              iconColor: AppColors.sekunder,
                              title: t.suggestionPauseTitle,
                              subtitle: t.suggestionPauseSub,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MeditasiDetailScreen(session: MeditationCatalog.byId('jeda_kerja')),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _SuggestionRow(
                              icon: Icons.menu_book_rounded,
                              iconColor: AppColors.aksenHangat,
                              title: t.suggestionCbtTitle,
                              subtitle: t.suggestionCbtSub,
                              // Lewat JurnalHomeScreen supaya gerbang PIN jurnal tetap berlaku.
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const JurnalHomeScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showHakimInsight) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.monsterHakim.withValues(alpha: 0.08),
                            border: Border.all(color: AppColors.monsterHakim.withValues(alpha: 0.25)),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 38,
                                height: 40,
                                child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.liar, size: 38, applyBossScale: false),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  t.resultHakimInsight,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontSize: 12, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
                child: RiungButton(label: t.startMyDay, onPressed: () => _mulaiHariku(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.icon, required this.iconColor, required this.value, required this.label});

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: iconColor),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.chipLabel.copyWith(color: AppColors.aksenHangat, fontSize: 15)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 13)),
              Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.teksRedup),
      ],
      ),
    );
  }
}
