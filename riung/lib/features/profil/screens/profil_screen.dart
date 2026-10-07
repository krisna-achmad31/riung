import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../betterme/screens/betterme_home_screen.dart';
import '../../kepribadian/screens/kepribadian_hub_screen.dart';
import '../../monster/screens/vault_screen.dart';
import '../../toko/screens/paywall_premium_screen.dart';
import '../../toko/screens/toko_screen.dart';
import '../logic/avatar_catalog.dart';
import '../widgets/profil_avatar.dart';
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
      body: SafeArea(
        bottom: false,
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
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl + MediaQuery.paddingOf(context).bottom),
              children: [
                Row(
                  children: [
                    Expanded(child: Text(t.title, style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.2))),
                    RiungGlassIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PengaturanScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                RiungGlassCard(
                  radius: 34,
                  color: AppColors.permukaan,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ProfilAvatar(avatar: avatar),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile.displayName.isEmpty ? t.defaultName : profile.displayName, style: AppTextStyles.title.copyWith(fontSize: 22)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: profile.premiumNow ? AppColors.emasLembut : AppColors.primerLembut,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    profile.premiumNow ? t.levelPremium : t.levelNovice,
                                    style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: profile.premiumNow ? AppColors.emasTua : AppColors.primer),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(t.joined(bergabung), style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(child: _StatCard(leading: const RiungIcon3D(RiungIcon.streak, size: 40), value: '${scope.streak.current}', label: t.statStreak)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(leading: const RiungIcon3D(RiungIcon.koin, size: 40), value: '${scope.wallet.coins}', label: t.statCoins)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              leading: const RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 40, applyBossScale: false),
                              value: '$tamedCount/7',
                              label: t.statTamed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _PremiumCard(
                  title: t.premiumTitle,
                  sub: profile.premiumNow ? t.premiumSubActive : t.premiumSubInactive,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPremiumScreen())),
                ),
                const SizedBox(height: AppSpacing.lg),
                RiungMenuGroup(
                  children: [
                    RiungMenuRow(
                      leading: const RiungIcon3D(RiungIcon.kepribadian, size: 42),
                      title: t.betterMeTitle,
                      subtitle: t.betterMeSub,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BetterMeHomeScreen())),
                    ),
                    RiungMenuRow(
                      leading: const RiungIcon3D(RiungIcon.beranda, size: 42),
                      title: context.s.kepribadian.title,
                      subtitle: context.s.kepribadian.testName(PersonalityTest.jung),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KepribadianHubScreen())),
                    ),
                    RiungMenuRow(
                      leading: const RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 42, applyBossScale: false),
                      title: t.vaultTitle,
                      subtitle: t.vaultSub(tamedCount),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VaultScreen())),
                    ),
                    RiungMenuRow(
                      leading: const RiungIcon3D(RiungIcon.laporan, size: 42),
                      title: t.calendarTitle,
                      subtitle: t.calendarSub,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KalenderLatihanScreen())),
                    ),
                    RiungMenuRow(
                      leading: const RiungIcon3D(RiungIcon.koin, size: 42),
                      title: t.shopTitle,
                      subtitle: t.shopSub,
                      badge: t.shopBadge,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TokoScreen())),
                    ),
                    RiungMenuRow(
                      leading: const RiungIcon3D(RiungIcon.checkin, size: 42),
                      title: t.notifTitle,
                      subtitle: t.notifSub,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BantuanKrisisScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.aksenHangatLembut.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.aksenHangat.withValues(alpha: 0.5), width: AppGlass.edgeWidth),
                    ),
                    child: Row(
                      children: [
                        const RiungIcon3D(RiungIcon.bantuan, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.crisisTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                              const SizedBox(height: 2),
                              Text(t.crisisSub, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                            ],
                          ),
                        ),
                        const Icon(Icons.phone_outlined, size: 20, color: AppColors.aksenHangatGelap),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Kartu Riung Premium (frame `Premium`): gradien ungu malam → primer.
class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.title, required this.sub, required this.onTap});

  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.tiketAwal, AppColors.primer]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppGlass.shadow,
        ),
        child: Row(
          children: [
            const RiungIcon3D(RiungIcon.premium, size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.title.copyWith(fontSize: 17, color: AppColors.diAtasTinta)),
                  const SizedBox(height: 3),
                  Text(sub, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.diAtasTinta.withValues(alpha: 0.8))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.diAtasTinta),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.leading, required this.value, required this.label});

  final Widget leading;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          SizedBox(width: 40, height: 40, child: leading),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.title.copyWith(fontSize: 20, height: 1.2)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}
