import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'riung_glass_card.dart';

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

/// Navigasi bawah 5 tab Riung Glass — pil kaca mengambang (komponen
/// `Tab Bar Kaca` di `design/riung.pen`); tab aktif = pil primer lembut.
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: RiungGlassCard(
          blur: true,
          radius: 34,
          color: AppColors.kacaNav,
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            height: 56,
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
          ),
        ),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: active ? AppColors.primerLembut : AppColors.primerLembut.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              tab.label(context.s),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.navLabel.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
