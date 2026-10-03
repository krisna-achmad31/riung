import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../appbeku/screens/appbeku_rekap_screen.dart';
import '../../launch/screens/daftar_screen.dart';
import '../../launch/screens/splash_screen.dart';
import 'bantuan_krisis_screen.dart';
import 'edit_profil_screen.dart';
import 'ekspor_data_screen.dart';
import 'hapus_akun_screen.dart';
import 'jurnal_pin_setting_screen.dart';
import 'kebijakan_privasi_screen.dart';
import 'langganan_screen.dart';
import 'notifikasi_screen.dart';

/// Pengaturan, dengan disclaimer non-diagnosis. Implement persis
/// `design/Profil.dc.html` § "Pengaturan (dengan disclaimer)".
class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  Future<void> _keluarAkun(BuildContext context) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.permukaan,
        title: Text(dialogContext.s.profil.signOutTitle, style: AppTextStyles.title.copyWith(fontSize: 17)),
        content: Text(
          dialogContext.s.profil.signOutBody,
          style: AppTextStyles.body.copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(dialogContext.s.common.batal)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(dialogContext.s.common.keluar)),
        ],
      ),
    );
    if (konfirmasi != true || !context.mounted) return;
    await AppScope.of(context).auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.profil;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
                  ),
                  Text(t.settingsTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(t.sectionAccount),
                    _SectionCard(children: [
                      ListenableBuilder(
                        listenable: scope.auth,
                        builder: (context, _) => _Row(
                          icon: Icons.mail_outline_rounded,
                          title: t.emailTitle,
                          sub: scope.auth.email ?? t.emailNotLinked,
                          onTap: () {
                            if (scope.auth.email == null) {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DaftarScreen()));
                            } else {
                              // Sudah tertaut — belum ada layar "kelola akun"
                              // di desain, jadi cukup konfirmasi supaya tap
                              // tidak pernah jadi dead click seperti sebelumnya.
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t.alreadySignedIn(scope.auth.email!))),
                              );
                            }
                          },
                        ),
                      ),
                      _Row(
                        icon: Icons.face_retouching_natural_rounded,
                        title: t.changeNameAvatar,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfilScreen())),
                      ),
                      _Row(
                        icon: Icons.lock_outline_rounded,
                        title: t.journalLock,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JurnalPinSettingScreen())),
                        isLast: true,
                      ),
                    ]),
                    _SectionLabel(t.sectionApp),
                    _SectionCard(children: [
                      _Row(
                        icon: Icons.notifications_outlined,
                        title: t.notifTitle,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
                      ),
                      _Row(
                        icon: Icons.language_rounded,
                        title: context.s.common.languageTitle,
                        sub: context.s.language.nativeName,
                        onTap: () => showBahasaSheet(context),
                      ),
                      _Row(
                        icon: Icons.phonelink_lock_rounded,
                        title: t.frozenApps,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppBekuRekapScreen())),
                      ),
                      ListenableBuilder(
                        listenable: scope.auth,
                        builder: (context, _) => _Row(
                          icon: Icons.workspace_premium_rounded,
                          iconColor: AppColors.aksenHangat,
                          title: t.subscriptionRow,
                          badge: scope.auth.profile?.premiumNow == true ? t.activeBadge : null,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LanggananScreen())),
                          isLast: true,
                        ),
                      ),
                    ]),
                    _SectionLabel(t.sectionSupport),
                    _SectionCard(children: [
                      _Row(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.error,
                        titleColor: AppColors.error,
                        title: t.crisisTitle,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BantuanKrisisScreen())),
                      ),
                      _Row(
                        icon: Icons.download_outlined,
                        title: t.downloadData,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EksporDataScreen())),
                      ),
                      _Row(
                        icon: Icons.info_outline_rounded,
                        title: t.privacyPolicy,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KebijakanPrivasiScreen())),
                        isLast: true,
                      ),
                    ]),
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.lg),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primer.withValues(alpha: 0.06),
                        border: Border.all(color: AppColors.garis),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.teksRedup),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              t.disclaimer,
                              style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: TextButton(
                        onPressed: () => _keluarAkun(context),
                        child: Text(t.signOut, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HapusAkunScreen())),
                        child: Text(t.deleteAccount, style: AppTextStyles.chipLabel.copyWith(color: AppColors.error, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(child: Text('Riung v1.0.0', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.teksRedup))),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, AppSpacing.lg, 4, AppSpacing.sm),
      child: Text(text, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.sub,
    this.badge,
    this.iconColor = AppColors.teksSekunder,
    this.titleColor = AppColors.teksUtama,
    this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final String? badge;
  final Color iconColor;
  final Color titleColor;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.kartu)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: sub == null
                  ? Text(title, style: AppTextStyles.chipLabel.copyWith(color: titleColor, fontSize: 13))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.chipLabel.copyWith(color: titleColor, fontSize: 13)),
                        Text(sub!, style: AppTextStyles.caption.copyWith(fontSize: 11)),
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
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.teksRedup),
          ],
        ),
      ),
    );
  }
}
