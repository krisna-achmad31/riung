import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../widgets/pin_pad.dart';

/// Verifikasi PIN sebelum membuka jurnal. Menawarkan biometrik kalau
/// tersedia di perangkat. Mengembalikan `true` lewat `Navigator.pop`
/// kalau berhasil terbuka.
class JurnalPinUnlockScreen extends StatefulWidget {
  const JurnalPinUnlockScreen({super.key});

  @override
  State<JurnalPinUnlockScreen> createState() => _JurnalPinUnlockScreenState();
}

class _JurnalPinUnlockScreenState extends State<JurnalPinUnlockScreen> {
  String _current = '';
  bool _error = false;
  bool _checking = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final scope = AppScope.of(context);
    if (!scope.prefs.biometricUnlockEnabled) return;
    final available = await scope.pinService.isBiometricAvailable;
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
    if (available) _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final ok = await AppScope.of(context).pinService.authenticateWithBiometrics(reason: AppScope.of(context).language.strings.jurnal.biometricReason);
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  void _onDigit(String digit) {
    if (_current.length >= 6 || _checking) return;
    setState(() {
      _current += digit;
      _error = false;
    });
    if (_current.length == 6) _verify();
  }

  void _onBackspace() {
    if (_current.isEmpty || _checking) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _checking = true);
    final ok = await AppScope.of(context).pinService.verifyPin(_current);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = true;
        _current = '';
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(false),
                    icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder),
                  ),
                ],
              ),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: AppColors.primer.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.primer.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.lock_outline, size: 34, color: AppColors.primer),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(context.s.jurnal.pinEnter, style: AppTextStyles.title.copyWith(fontSize: 21)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.s.jurnal.pinEnterSub,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              PinDots(filled: _current.length),
              if (_error) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(context.s.jurnal.pinWrong, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 236,
                child: PinNumpad(onDigit: _onDigit, onBackspace: _onBackspace),
              ),
              if (_biometricAvailable) ...[
                const SizedBox(height: AppSpacing.lg),
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint, color: AppColors.primer),
                  label: Text(context.s.jurnal.useFingerprint, style: AppTextStyles.chipLabel.copyWith(color: AppColors.primer)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
