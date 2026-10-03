import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/services.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../launch/screens/splash_screen.dart';

/// Konfirmasi hapus akun. Implement `design/Profil.dc.html` §
/// "Hapus akun — konfirmasi" DENGAN SATU PERUBAHAN SENGAJA: desain
/// menjanjikan jeda 30 hari sebelum penghapusan permanen (bisa dibatalkan
/// dengan login lagi) — app ini tidak punya mekanisme soft-delete
/// terjadwal (Spark plan, tanpa Cloud Functions/Scheduler buat purge
/// job), jadi janji itu diganti jujur: hapus akun di sini LANGSUNG
/// permanen. Menjanjikan pemulihan yang tidak sungguhan melanggar
/// CLAUDE.md aturan #4 (tidak ada dark pattern) — lihat laporan deviasi.
class HapusAkunScreen extends StatefulWidget {
  const HapusAkunScreen({super.key});

  @override
  State<HapusAkunScreen> createState() => _HapusAkunScreenState();
}

class _HapusAkunScreenState extends State<HapusAkunScreen> {
  bool _menghapus = false;

  Future<void> _hapus() async {
    final konfirmasiAkhir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.permukaan,
        title: Text(dialogContext.s.profil.deleteConfirmTitle, style: AppTextStyles.title.copyWith(fontSize: 17)),
        content: Text(
          dialogContext.s.profil.deleteConfirmBody,
          style: AppTextStyles.body.copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(dialogContext.s.common.batal)),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.s.profil.deletePermanent, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (konfirmasiAkhir != true || !mounted) return;

    setState(() => _menghapus = true);
    final scope = AppScope.of(context);
    try {
      final uid = scope.auth.uid;
      if (uid != null) {
        try {
          await scope.userRepository.deleteCloudData(uid);
        } catch (_) {
          // Salinan cloud gagal dihapus (mis. offline) — akun tetap dihapus.
        }
      }
      await scope.auth.deleteAccount();
      await scope.pinService.clearPin();
      await scope.userRepository.deleteAllLocalData();
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() => _menghapus = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.launch.authError(e.error, e.code))));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = AppScope.of(context).wallet;
    final t = context.s.profil;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: Column(
        children: [
          Expanded(
            child: Opacity(
              opacity: 0.3,
              child: SafeArea(
                bottom: false,
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
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.permukaan,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.garis, borderRadius: BorderRadius.circular(AppRadius.pill))),
                  const SizedBox(height: AppSpacing.lg),
                  const SizedBox(
                    width: 96,
                    height: 100,
                    child: RiungMonster(monsterId: 'meronta', state: MonsterVisualState.jinak, size: 96),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(t.deleteHeading, textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 19)),
                  const SizedBox(height: AppSpacing.sm),
                  ListenableBuilder(
                    listenable: wallet,
                    builder: (context, _) => Text(
                      t.deleteBody(wallet.coins),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primer.withValues(alpha: 0.08),
                      border: Border.all(color: AppColors.primer.withValues(alpha: 0.25)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      t.deleteHint,
                      style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  RiungButton(
                    label: t.deleteBack,
                    variant: RiungButtonVariant.secondary,
                    onPressed: _menghapus ? null : () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: _menghapus ? null : _hapus,
                    child: Text(
                      _menghapus ? t.deleting : t.deleteYes,
                      style: AppTextStyles.chipLabel.copyWith(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
