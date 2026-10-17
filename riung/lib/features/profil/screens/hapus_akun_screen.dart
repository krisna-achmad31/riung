import '../../../core/services/assessment_draft_store.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/api/api_client.dart';
import '../../../core/widgets/api_error_feedback.dart';

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
        title: Text(
          dialogContext.s.profil.deleteConfirmTitle,
          style: AppTextStyles.title.copyWith(fontSize: 17),
        ),
        content: Text(
          AppScope.of(context).auth.profile?.premiumNow == true
              ? '${dialogContext.s.profil.deleteConfirmBody}\n\n'
                    '${dialogContext.s.profil.deleteSubDialogNote}'
              : dialogContext.s.profil.deleteConfirmBody,
          style: AppTextStyles.body.copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.s.common.batal),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              dialogContext.s.profil.deletePermanent,
              style: TextStyle(color: AppColors.error),
            ),
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
        await scope.userRepository.deleteCloudData(uid);
        await AssessmentDraftStore().clear(uid);
        await scope.wallet.apiState?.clearDeletedAccountCache(uid);
      }
      if (scope.wallet.apiState != null) {
        await scope.auth.signOut();
      } else {
        await scope.auth.deleteAccount();
      }
      if (uid != null) await scope.pinService.clearPin(uid);
      await scope.userRepository.deleteAllLocalData();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _menghapus = false);
      showApiError(context, e);
      return;
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() => _menghapus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.launch.authError(e.error, e.code))),
      );
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
    final scope = AppScope.of(context);
    final wallet = scope.wallet;
    final t = context.s.profil;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              RiungGlassHeader(title: t.deleteAccount),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom: AppSpacing.md,
                  ),
                  children: [
                    SizedBox(
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.garis,
                                  AppColors.garis.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                          const RiungMonster(
                            monsterId: 'meronta',
                            state: MonsterVisualState.jinak,
                            size: 170,
                            applyBossScale: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      t.deleteHeading,
                      style: AppTextStyles.display.copyWith(
                        fontSize: 26,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListenableBuilder(
                      listenable: wallet,
                      builder: (context, _) => Text(
                        t.deleteBody(wallet.coins),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.teksSekunder,
                        ),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: scope.auth,
                      builder: (context, _) {
                        final profile = scope.auth.profile;
                        if (profile == null || !profile.premiumNow) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: _LanggananPlayWarning(
                            premiumPlan: profile.premiumPlan,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.sekunderLembut.withValues(alpha: 0.7),
                        border: Border.all(
                          color: AppColors.garis,
                          width: AppGlass.edgeWidth,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: AppColors.sekunder,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t.deleteHint,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                color: AppColors.teksUtama,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RiungButton(
                label: t.deleteBack,
                onPressed: _menghapus
                    ? null
                    : () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: AppSpacing.md),
              Material(
                color: AppColors.permukaan,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: AppColors.aksenHangat.withValues(alpha: 0.7),
                    width: AppGlass.edgeWidth,
                  ),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: _menghapus ? null : _hapus,
                  child: SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        _menghapus ? t.deleting : t.deleteYes,
                        style: AppTextStyles.buttonLabel.copyWith(
                          fontSize: 15,
                          color: AppColors.aksenHangatGelap,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// H-05 (audit 2026-10): hapus akun TIDAK membatalkan langganan Play. Kalau
/// Premium masih berlaku, beri tahu dengan jelas + jalan pintas ke halaman
/// langganan Play — tanpa menghalangi penghapusan (bukan dark pattern).
class _LanggananPlayWarning extends StatelessWidget {
  const _LanggananPlayWarning({required this.premiumPlan});

  final String? premiumPlan;

  // Pola sama dengan `_kelolaLangganan` di langganan_screen.dart.
  Future<void> _kelolaDiPlay() async {
    final productId = premiumPlan;
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '${productId != null ? '?sku=$productId&package=com.riung.riung' : ''}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.aksenHangatLembut.withValues(alpha: 0.8),
        border: Border.all(
          color: AppColors.aksenHangat.withValues(alpha: 0.7),
          width: AppGlass.edgeWidth,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppColors.aksenHangatGelap,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.deleteSubWarningTitle,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 14,
                    color: AppColors.teksUtama,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.deleteSubWarningBody,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppColors.teksUtama,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          RiungButton(
            label: t.deleteManagePlay,
            variant: RiungButtonVariant.secondary,
            onPressed: _kelolaDiPlay,
          ),
        ],
      ),
    );
  }
}
