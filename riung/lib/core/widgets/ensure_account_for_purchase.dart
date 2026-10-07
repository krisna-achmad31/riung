import 'package:flutter/material.dart';

import '../../features/launch/screens/daftar_screen.dart';
import '../l10n/l10n.dart';
import '../state/state.dart';
import '../theme/theme.dart';
import 'riung_button.dart';

/// Poin 2 — gate sebelum transaksi Play Billing sungguhan (beli koin
/// atau Premium). Sesi anonim bisa hilang kalau app di-uninstall/ganti
/// HP, jadi pembelian uang asli harus lewat akun yang bisa dipulihkan.
///
/// Kalau user sudah login (bukan anonim), lolos langsung tanpa
/// menampilkan apa pun. Kalau masih anonim, tawarkan daftar/hubungkan
/// akun dulu lewat sheet ini — TIDAK memaksa: pilih "Nanti saja" cukup
/// membatalkan pembelian yang sedang dicoba, tidak menghentikan apa pun
/// yang lain (pemanggil cukup `return` kalau ini balikin `false`).
Future<bool> ensureAccountForPurchase(BuildContext context) async {
  final scope = AppScope.of(context);
  if (!scope.auth.isAnonymous) return true;

  final lanjut = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 26 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: AppColors.garis, borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Frame `Glass — Toko · Simpan pembelianmu`: orb kaca + perisai.
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.permukaan,
              border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
              boxShadow: AppGlass.shadow,
            ),
            child: const Icon(Icons.verified_user_outlined, size: 46, color: AppColors.primer),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(sheetContext.s.toko.gateTitle, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
          const SizedBox(height: AppSpacing.md),
          Text(
            sheetContext.s.toko.gateBody,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder),
          ),
          const SizedBox(height: AppSpacing.lg),
          RiungButton(label: sheetContext.s.toko.gateSignUp, onPressed: () => Navigator.of(sheetContext).pop(true)),
          const SizedBox(height: 10),
          RiungButton(label: sheetContext.s.common.nantiSaja, variant: RiungButtonVariant.secondary, onPressed: () => Navigator.of(sheetContext).pop(false)),
        ],
      ),
    ),
  );
  if (lanjut != true || !context.mounted) return false;

  final berhasil = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const DaftarScreen(isPurchaseGate: true)),
  );
  return berhasil == true;
}
