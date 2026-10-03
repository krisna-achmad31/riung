import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../betterme/screens/betterme_home_screen.dart';
import '../../kepribadian/screens/kepribadian_hub_screen.dart';
import '../../monster/screens/vault_screen.dart';
import '../../toko/screens/paywall_premium_screen.dart';
import '../../toko/screens/toko_screen.dart';
import '../logic/avatar_catalog.dart';
import 'bantuan_krisis_screen.dart';
import 'kalender_latihan_screen.dart';
import 'notifikasi_screen.dart';
import 'pengaturan_screen.dart';

/// Tab "Profil" — identitas, statistik, menu. Implement persis
/// `design/Profil.dc.html` § "Profil". "Level 4" di desain sengaja
/// dihilangkan (tidak ada sistem level di app ini, lihat laporan
/// deviasi) — "Better Me" mengarah ke path-map sesi sungguhan (bukan
/// dashboard statistik desain, yang butuh data historis fokus/tidur yang
/// tidak pernah dicatat di app ini).
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.profil;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([scope.auth, scope.streak, scope.wallet, scope.monsterProgress]),
          builder: (context, _) {
            final profile = scope.auth.profile;
            if (profile == null) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primer));
            }
            final tamedCount = scope.monsterProgress.all.values.where((m) => m.state == MonsterState.tamed).length;
            final avatar = AvatarCatalog.byId(profile.avatarId);
            final bergabung = DateFormat('d MMMM yyyy', context.s.dateLocale).format(profile.createdAt);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(child: Text(t.title, style: AppTextStyles.title.copyWith(fontSize: 22))),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PengaturanScreen())),
                      icon: const Icon(Icons.settings_rounded, size: 21, color: AppColors.teksSekunder),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.kartu, AppColors.permukaan], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border: Border.all(color: AppColors.garis),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: avatar.colors)),
                        alignment: Alignment.center,
                        child: Text(
                          profile.displayName.isEmpty ? '?' : profile.displayName[0].toUpperCase(),
                          style: AppTextStyles.display.copyWith(fontSize: 24, color: AppColors.latar),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.displayName.isEmpty ? t.defaultName : profile.displayName, style: AppTextStyles.title.copyWith(fontSize: 18)),
                            const SizedBox(height: 2),
                            Text(
                              profile.premiumNow ? t.levelPremium : t.levelNovice,
                              style: AppTextStyles.caption.copyWith(
                                color: profile.premiumNow ? AppColors.aksenHangat : AppColors.monsterCermin,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(t.joined(bergabung), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _StatCard(icon: Icons.local_fire_department, color: AppColors.aksenHangat, value: '${scope.streak.current}', label: t.statStreak),
                    const SizedBox(width: AppSpacing.sm),
                    _StatCard(icon: Icons.monetization_on, color: AppColors.aksenHangat, value: '${scope.wallet.coins}', label: t.statCoins),
                    const SizedBox(width: AppSpacing.sm),
                    _StatCard(icon: Icons.pest_control, color: AppColors.monsterWaswas, value: '$tamedCount/7', label: t.statTamed),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _MenuTile(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppColors.sekunder,
                  title: t.betterMeTitle,
                  subtitle: t.betterMeSub,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BetterMeHomeScreen())),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MenuTile(
                  icon: Icons.face_retouching_natural_rounded,
                  iconColor: AppColors.monsterHakim,
                  title: context.s.kepribadian.title,
                  subtitle: context.s.kepribadian.testName(PersonalityTest.jung),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KepribadianHubScreen())),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MenuTile(
                  icon: Icons.pest_control_rounded,
                  iconColor: AppColors.monsterWaswas,
                  title: t.vaultTitle,
                  subtitle: t.vaultSub(tamedCount),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VaultScreen())),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MenuTile(
                  icon: Icons.calendar_month_rounded,
                  iconColor: AppColors.monsterCermin,
                  title: t.calendarTitle,
                  subtitle: t.calendarSub,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KalenderLatihanScreen())),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MenuTile(
                  icon: Icons.storefront_rounded,
                  iconColor: AppColors.aksenHangat,
                  title: t.shopTitle,
                  subtitle: t.shopSub,
                  badge: t.shopBadge,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TokoScreen())),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MenuTile(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: AppColors.aksenHangat,
                  title: t.premiumTitle,
                  subtitle: profile.premiumNow ? t.premiumSubActive : t.premiumSubInactive,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPremiumScreen())),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MenuTile(
                  icon: Icons.notifications_rounded,
                  iconColor: AppColors.primer,
                  title: t.notifTitle,
                  subtitle: t.notifSub,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MenuTile(
                  icon: Icons.shield_rounded,
                  iconColor: AppColors.error,
                  titleColor: AppColors.error,
                  title: t.crisisTitle,
                  subtitle: t.crisisSub,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BantuanKrisisScreen())),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor = AppColors.teksUtama,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final Color titleColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: titleColor)),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: AppColors.aksenHangat, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(badge!, style: AppTextStyles.caption.copyWith(color: AppColors.latar, fontWeight: FontWeight.w700, fontSize: 10)),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.teksRedup),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.title.copyWith(fontSize: 16)),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
