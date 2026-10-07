import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/economy.dart';
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
    final n = context.s.notif;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, AppSpacing.md, 24, AppSpacing.lg),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 300,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            top: 10,
                            child: Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                            ),
                          ),
                          const Positioned(top: 96, child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 190, applyBossScale: false)),
                          Positioned(
                            top: 10,
                            left: 6,
                            right: 6,
                            child: _ContohNotifikasi(title: n.checkinTitle, body: n.checkinBody(EconomyEarn.checkinHarian)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(alignment: Alignment.centerLeft, child: Text(t.permissionTitle, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.15))),
                  ],
                ),
              ),
              RiungButton(label: _requesting ? t.permissionAsking : t.permissionEnable, onPressed: _requesting ? null : _mintaIzin),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _requesting ? null : _lanjut,
                child: Text(context.s.common.nantiSaja, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contoh notifikasi (frame `Notifikasi contoh`): kartu kaca, ikon app "R".
class _ContohNotifikasi extends StatelessWidget {
  const _ContohNotifikasi({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppGlass.card(radius: 24, color: AppColors.permukaanPadat.withValues(alpha: 0.85)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primerTerang, AppColors.sekunderTerang]),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text('R', style: AppTextStyles.display.copyWith(fontSize: 18, color: AppColors.diAtasTinta)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksUtama)),
                const SizedBox(height: 2),
                Text(body, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.3, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
