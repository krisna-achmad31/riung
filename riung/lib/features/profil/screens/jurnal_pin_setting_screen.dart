import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
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
    final tj = context.s.jurnal;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.journalLock),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
                  children: [
                    const SizedBox(height: 170, child: Center(child: RiungIcon3D(RiungIcon.jurnal, size: 150))),
                    const SizedBox(height: AppSpacing.md),
                    Text(tj.lockedTitle, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.2)),
                    const SizedBox(height: AppSpacing.md),
                    Text(tj.lockedBody, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.md),
                    RiungMenuGroup(
                      children: [
                        RiungMenuRow(
                          leading: RiungMenuRow.iconBox(Icons.key_rounded),
                          title: t.pinChange,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JurnalPinSetupScreen())),
                        ),
                        if (_biometricAvailable)
                          RiungMenuRow(
                            leading: RiungMenuRow.iconBox(Icons.face_retouching_natural_rounded),
                            title: t.pinBiometric,
                            trailing: Switch(
                              value: _biometricEnabled,
                              onChanged: (v) {
                                setState(() => _biometricEnabled = v);
                                AppScope.of(context).prefs.setBiometricUnlockEnabled(v);
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.kartu, borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.teksSekunder),
                          const SizedBox(width: 10),
                          Expanded(child: Text(tj.pinLocalOnly, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksSekunder))),
                        ],
                      ),
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
