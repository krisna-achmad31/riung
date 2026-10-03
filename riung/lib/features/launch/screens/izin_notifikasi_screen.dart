import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../home/screens/root_shell_screen.dart';
import '../../onboarding/screens/onboarding_flow_screen.dart';

/// Priming permission notifikasi — dialog sistem Android asli dipicu lewat
/// `permission_handler`, bukan ditiru manual (chrome sistem tak bisa
/// dikustom app). Implement persis `design/Launch.dc.html` § Izin notifikasi.
class IzinNotifikasiScreen extends StatefulWidget {
  const IzinNotifikasiScreen({super.key});

  @override
  State<IzinNotifikasiScreen> createState() => _IzinNotifikasiScreenState();
}

class _IzinNotifikasiScreenState extends State<IzinNotifikasiScreen> {
  bool _requesting = false;

  Future<void> _mintaIzin() async {
    setState(() => _requesting = true);
    final status = await Permission.notification.request();
    if (!mounted) return;
    setState(() => _requesting = false);
    final pesan = status.isGranted ? context.s.launch.permissionGranted : context.s.launch.permissionDenied;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
    _lanjut();
  }

  /// Kalau dipicu dari alur onboarding baru, lanjut ke sisa onboarding
  /// seperti biasa. Tapi kalau dipicu dari Daftar-lewat-Pengaturan (user
  /// yang profilnya sudah `onboardingDone`), jangan nyasar balik ke
  /// onboarding — langsung ke Beranda.
  void _lanjut() {
    final onboardingDone = AppScope.of(context).auth.profile?.onboardingDone ?? false;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => onboardingDone ? const RootShellScreen() : const OnboardingFlowScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.launch;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: 44),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const SizedBox(
                          width: 120,
                          height: 126,
                          child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 120),
                        ),
                        Positioned(
                          top: -4,
                          right: -10,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.aksenHangat,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.notifications, size: 21, color: AppColors.latar),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      t.permissionTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.permissionBody,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
              child: Column(
                children: [
                  RiungButton(
                    label: _requesting ? t.permissionAsking : t.permissionEnable,
                    onPressed: _requesting ? null : _mintaIzin,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: _requesting ? null : _lanjut,
                    child: Text(
                      context.s.common.nantiSaja,
                      style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
