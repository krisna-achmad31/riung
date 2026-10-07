import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../afirmasi/screens/afirmasi_kategori_screen.dart';
import '../../jurnal/screens/jurnal_home_screen.dart';
import '../../meditasi/screens/meditasi_list_screen.dart';
import '../../tidur/screens/tidur_list_screen.dart';

class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.builder,
  });

  final RiungIcon icon;
  final String label;
  final String sub;
  final WidgetBuilder builder;
}

/// Grid 2×2 aksi cepat (Meditasi/Tidur/Jurnal/Afirmasi) — dipakai di kedua
/// varian Beranda.
class HomeQuickActionGrid extends StatelessWidget {
  const HomeQuickActionGrid({super.key});

  static List<QuickAction> _actions(HomeStrings t) => [
    QuickAction(
      icon: RiungIcon.meditasi,
      label: t.quickMeditation,
      sub: t.quickMeditationSub,
      builder: (_) => const MeditasiListScreen(),
    ),
    QuickAction(
      icon: RiungIcon.tidur,
      label: t.quickSleep,
      sub: t.quickSleepSub,
      builder: (_) => const TidurListScreen(),
    ),
    QuickAction(
      icon: RiungIcon.jurnal,
      label: t.quickJournal,
      sub: t.quickJournalSub,
      builder: (_) => const JurnalHomeScreen(),
    ),
    QuickAction(
      icon: RiungIcon.afirmasi,
      label: t.quickAffirmation,
      sub: t.quickAffirmationSub,
      builder: (_) => const AfirmasiKategoriScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context.s.home);
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _QuickActionCard(actions[i])),
        ],
      ],
    );
  }
}

/// Ubin aksi cepat (frame `Aksi …` di `Glass — Beranda`).
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard(this.action);

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: action.builder)),
      child: Column(
        children: [
          RiungIcon3D(action.icon, size: 52),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(action.label, maxLines: 1, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksUtama)),
          ),
          const SizedBox(height: 2),
          Text(
            action.sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.teksRedup),
          ),
        ],
      ),
    );
  }
}
