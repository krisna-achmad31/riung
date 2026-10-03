import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../jurnal/screens/jurnal_pin_setup_screen.dart';

/// Ganti PIN & toggle biometrik. Tidak ada mockup terpisah di desain
/// (dirujuk lewat baris "Kunci jurnal & PIN" di Pengaturan) — dibangun
/// mengikuti bahasa visual layar Pengaturan yang sudah ada.
class JurnalPinSettingScreen extends StatefulWidget {
  const JurnalPinSettingScreen({super.key});

  @override
  State<JurnalPinSettingScreen> createState() => _JurnalPinSettingScreenState();
}

class _JurnalPinSettingScreenState extends State<JurnalPinSettingScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = true;

  @override
  void initState() {
    super.initState();
    final scope = AppScope.of(context);
    _biometricEnabled = scope.prefs.biometricUnlockEnabled;
    scope.pinService.isBiometricAvailable.then((available) {
      if (mounted) setState(() => _biometricAvailable = available);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(t.journalLock, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.permukaan,
                        border: Border.all(color: AppColors.garis),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JurnalPinSetupScreen())),
                        child: Row(
                          children: [
                            const Icon(Icons.pin_rounded, size: 18, color: AppColors.teksSekunder),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: Text(t.pinChange, style: AppTextStyles.chipLabel.copyWith(fontSize: 14))),
                            const Icon(Icons.chevron_right_rounded, size: 17, color: AppColors.teksRedup),
                          ],
                        ),
                      ),
                    ),
                    if (_biometricAvailable) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.permukaan,
                          border: Border.all(color: AppColors.garis),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fingerprint_rounded, size: 18, color: AppColors.teksSekunder),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: Text(t.pinBiometric, style: AppTextStyles.chipLabel.copyWith(fontSize: 14))),
                            Switch(
                              value: _biometricEnabled,
                              onChanged: (v) {
                                setState(() => _biometricEnabled = v);
                                AppScope.of(context).prefs.setBiometricUnlockEnabled(v);
                              },
                              activeThumbColor: AppColors.latar,
                              activeTrackColor: AppColors.primer,
                              inactiveThumbColor: AppColors.teksRedup,
                              inactiveTrackColor: AppColors.kartu,
                            ),
                          ],
                        ),
                      ),
                    ],
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
