import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../profil/screens/kebijakan_privasi_screen.dart';

/// Ketentuan langganan Premium — dibuka dari tautan "Ketentuan" di paywall.
/// Menjelaskan trial, penagihan lewat Google Play, dan cara membatalkan,
/// plus pintasan ke kebijakan privasi.
Future<void> showKetentuanSheet(BuildContext context) {
  final trialDays = AppScope.of(context).remoteConfig.premiumTrialHari;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.permukaan,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) {
      final t = sheetContext.s.toko;
      final points = [t.termsTrial(trialDays), t.termsPlay, t.termsCancel, t.termsFree];
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.garis, borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(t.termsTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 17)),
              const SizedBox(height: AppSpacing.md),
              for (final point in points)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.check_rounded, size: 15, color: AppColors.sukses),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(point, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5))),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KebijakanPrivasiScreen()));
                },
                child: Text(
                  t.termsPrivacy,
                  style: AppTextStyles.chipLabel.copyWith(color: AppColors.primer, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
