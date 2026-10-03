import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';

/// Item navigasi bawah tetap Riung — urutan & label sesuai desain.
enum RiungNavTab {
  beranda(Icons.home_rounded),
  jelajah(Icons.explore_rounded),
  fokus(Icons.center_focus_strong_rounded),
  monster(Icons.pest_control_rounded),
  profil(Icons.person_rounded);

  const RiungNavTab(this.icon);
  final IconData icon;

  /// Label tab dalam bahasa aktif.
  String label(AppStrings s) {
    switch (this) {
      case RiungNavTab.beranda:
        return s.common.navHome;
      case RiungNavTab.jelajah:
        return s.common.navExplore;
      case RiungNavTab.fokus:
        return s.common.navFocus;
      case RiungNavTab.monster:
        return s.common.navMonster;
      case RiungNavTab.profil:
        return s.common.navProfile;
    }
  }
}

/// Navigasi bawah 5 tab Riung — lihat §05 Komponen inti · "Navigasi bawah"
/// di `design/Design System.dc.html`.
class RiungBottomNav extends StatelessWidget {
  const RiungBottomNav({
    super.key,
    required this.current,
    required this.onTabSelected,
  });

  final RiungNavTab current;
  final ValueChanged<RiungNavTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.permukaan,
        border: Border(top: BorderSide(color: AppColors.garis)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      child: Row(
        children: [
          for (final tab in RiungNavTab.values)
            Expanded(
              child: _NavItem(
                tab: tab,
                active: tab == current,
                onTap: () => onTabSelected(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.active, required this.onTap});

  final RiungNavTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primer : AppColors.teksRedup;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tab.icon, size: 23, color: color),
          const SizedBox(height: 4),
          Text(tab.label(context.s), style: AppTextStyles.navLabel.copyWith(color: color)),
        ],
      ),
    );
  }
}
