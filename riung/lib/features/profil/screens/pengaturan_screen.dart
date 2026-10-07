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
        content: Text(dialogContext.s.profil.signOutBody, style: AppTextStyles.body.copyWith(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(dialogContext.s.common.batal)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(dialogContext.s.common.keluar)),
        ],
      ),
    );
    if (konfirmasi != true || !context.mounted) return;
    await AppScope.of(context).auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.profil;
    void buka(Widget layar) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => layar));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.settingsTitle),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xl),
                  children: [
                    RiungMenuGroup(
                      title: t.sectionAccount,
                      children: [
                        ListenableBuilder(
                          listenable: scope.auth,
                          builder: (context, _) {
                            final email = scope.auth.email;
                            final tertaut = email != null && email.isNotEmpty;
                            return RiungMenuRow(
                              leading: RiungMenuRow.iconBox(Icons.mail_outline_rounded),
                              title: t.emailTitle,
                              subtitle: tertaut ? email : t.emailNotLinked,
                              onTap: () {
                                if (!tertaut) {
                                  buka(const DaftarScreen());
                                } else {
                                  // Sudah tertaut — belum ada layar "kelola akun"
                                  // di desain, jadi cukup konfirmasi supaya tap
                                  // tidak pernah jadi dead click.
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.alreadySignedIn(email))));
                                }
                              },
                            );
                          },
                        ),
                        RiungMenuRow(leading: RiungMenuRow.iconBox(Icons.face_retouching_natural_rounded), title: t.changeNameAvatar, onTap: () => buka(const EditProfilScreen())),
                        RiungMenuRow(leading: RiungMenuRow.iconBox(Icons.lock_outline_rounded), title: t.journalLock, onTap: () => buka(const JurnalPinSettingScreen())),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RiungMenuGroup(
                      title: t.sectionApp,
                      children: [
                        RiungMenuRow(leading: RiungMenuRow.iconBox(Icons.notifications_outlined), title: t.notifTitle, onTap: () => buka(const NotifikasiScreen())),
                        RiungMenuRow(
                          leading: RiungMenuRow.iconBox(Icons.language_rounded),
                          title: context.s.common.languageTitle,
                          subtitle: context.s.language.nativeName,
                          onTap: () => showBahasaSheet(context),
                        ),
                        RiungMenuRow(
                          leading: RiungMenuRow.iconBox(Icons.phonelink_lock_rounded, background: AppColors.langitLembut, color: AppColors.langit),
                          title: t.frozenApps,
                          onTap: () => buka(const AppBekuRekapScreen()),
                        ),
                        ListenableBuilder(
                          listenable: scope.auth,
                          builder: (context, _) => RiungMenuRow(
                            leading: RiungMenuRow.iconBox(Icons.diamond_outlined, background: AppColors.sekunderLembut, color: AppColors.sekunder),
                            title: t.subscriptionRow,
                            badge: scope.auth.profile?.premiumNow == true ? t.activeBadge : null,
                            badgeColor: AppColors.sekunderLembut,
                            badgeTextColor: AppColors.sekunder,
                            onTap: () => buka(const LanggananScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RiungMenuGroup(
                      title: t.sectionSupport,
                      children: [
                        RiungMenuRow(
                          leading: RiungMenuRow.iconBox(Icons.favorite_border_rounded, background: AppColors.aksenHangatLembut, color: AppColors.aksenHangatGelap),
                          title: t.crisisTitle,
                          titleColor: AppColors.aksenHangatGelap,
                          onTap: () => buka(const BantuanKrisisScreen()),
                        ),
                        RiungMenuRow(leading: RiungMenuRow.iconBox(Icons.download_outlined), title: t.downloadData, onTap: () => buka(const EksporDataScreen())),
                        RiungMenuRow(leading: RiungMenuRow.iconBox(Icons.info_outline_rounded), title: t.privacyPolicy, onTap: () => buka(const KebijakanPrivasiScreen())),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RiungGlassCard(
                      radius: 22,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.teksRedup),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(t.disclaimer, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.55))),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RiungMenuGroup(
                      children: [
                        RiungMenuRow(
                          leading: RiungMenuRow.iconBox(Icons.logout_rounded, background: AppColors.netralLembut, color: AppColors.teksSekunder),
                          title: t.signOut,
                          onTap: () => _keluarAkun(context),
                        ),
                        RiungMenuRow(
                          leading: RiungMenuRow.iconBox(Icons.delete_outline_rounded, background: AppColors.aksenHangatLembut, color: AppColors.aksenHangatGelap),
                          title: t.deleteAccount,
                          titleColor: AppColors.aksenHangatGelap,
                          onTap: () => buka(const HapusAkunScreen()),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text('Riung v1.0.0', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.teksRedup)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
