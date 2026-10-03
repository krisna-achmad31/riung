import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../afirmasi/screens/afirmasi_kategori_screen.dart';
import '../../jurnal/screens/jurnal_home_screen.dart';
import '../../meditasi/screens/meditasi_list_screen.dart';
import '../../tidur/screens/tidur_list_screen.dart';

class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.background,
    required this.color,
    required this.builder,
  });

  final IconData icon;
  final String label;
  final String sub;
  final Color background;
  final Color color;
  final WidgetBuilder builder;
}

/// Grid 2×2 aksi cepat (Meditasi/Tidur/Jurnal/Afirmasi) — dipakai di kedua
/// varian Beranda.
class HomeQuickActionGrid extends StatelessWidget {
  const HomeQuickActionGrid({super.key});

  static List<QuickAction> _actions(HomeStrings t) => [
    QuickAction(
      icon: Icons.self_improvement,
      label: t.quickMeditation,
      sub: t.quickMeditationSub,
      background: AppColors.sekunder.withValues(alpha: 0.15),
      color: AppColors.sekunder,
      builder: (_) => const MeditasiListScreen(),
    ),
    QuickAction(
      icon: Icons.nightlight_round,
      label: t.quickSleep,
      sub: t.quickSleepSub,
      background: AppColors.primer.withValues(alpha: 0.15),
      color: AppColors.primer,
      builder: (_) => const TidurListScreen(),
    ),
    QuickAction(
      icon: Icons.menu_book_rounded,
      label: t.quickJournal,
      sub: t.quickJournalSub,
      background: AppColors.aksenHangat.withValues(alpha: 0.15),
      color: AppColors.aksenHangat,
      builder: (_) => const JurnalHomeScreen(),
    ),
    QuickAction(
      icon: Icons.auto_awesome,
      label: t.quickAffirmation,
      sub: t.quickAffirmationSub,
      background: AppColors.monsterCermin.withValues(alpha: 0.18),
      color: AppColors.monsterCermin,
      builder: (_) => const AfirmasiKategoriScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: [for (final action in _actions(context.s.home)) _QuickActionCard(action)],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard(this.action);

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: action.builder)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: action.background, borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: Icon(action.icon, size: 21, color: action.color),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(action.label, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14)),
            Text(action.sub, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
