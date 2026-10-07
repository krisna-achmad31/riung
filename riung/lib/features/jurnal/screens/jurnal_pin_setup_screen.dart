import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/pin_pad.dart';

/// Setup PIN 6 digit pertama kali (buat lalu konfirmasi). Disimpan via
/// `flutter_secure_storage` (lihat [JurnalPinService]). Mengembalikan
/// `true` lewat `Navigator.pop` kalau berhasil dibuat.
class JurnalPinSetupScreen extends StatefulWidget {
  const JurnalPinSetupScreen({super.key});

  @override
  State<JurnalPinSetupScreen> createState() => _JurnalPinSetupScreenState();
}

class _JurnalPinSetupScreenState extends State<JurnalPinSetupScreen> {
  String _firstPin = '';
  String _current = '';
  bool _confirming = false;
  bool _error = false;

  void _onDigit(String digit) {
    if (_current.length >= 6) return;
    setState(() {
      _current += digit;
      _error = false;
    });
    if (_current.length == 6) _handleComplete();
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!_confirming) {
      final entered = _current;
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _firstPin = entered;
        _current = '';
        _confirming = true;
      });
      return;
    }

    if (_current == _firstPin) {
      final scope = AppScope.of(context);
      await scope.pinService.setPin(_current);
      // Backup PIN (hash+salt, bukan plain text) ke Firestore — cuma
      // untuk user yang sudah login, supaya bisa dipulihkan di device
      // baru (lihat JurnalPinRecoverScreen). Anonim dilewati: tidak ada
      // uid permanen buat disambungkan.
      final uid = scope.auth.uid;
      if (uid != null && !scope.auth.isAnonymous) {
        final salt = scope.pinService.generateSalt();
        final hash = scope.pinService.hashPin(_current, salt);
        await scope.userRepository.saveJournalPinBackup(
          uid,
          JournalPinBackup(hash: hash, salt: salt, updatedAt: DateTime.now()),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _error = true;
        _firstPin = '';
        _current = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                    ),
                    const RiungIcon3D(RiungIcon.jurnal, size: 100),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _confirming ? context.s.jurnal.pinRepeat : context.s.jurnal.pinCreate,
                style: AppTextStyles.display.copyWith(fontSize: 24),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _confirming ? context.s.jurnal.pinRepeatSub : context.s.jurnal.pinCreateSub,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
              if (!_confirming && AppScope.of(context).auth.isAnonymous) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.s.jurnal.pinLocalOnly,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PinDots(filled: _current.length),
              if (_error) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(context.s.jurnal.pinMismatch, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 300,
                child: PinNumpad(onDigit: _onDigit, onBackspace: _onBackspace),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
