import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../widgets/pin_pad.dart';
import 'jurnal_pin_setup_screen.dart';

/// PIN fallback lintas device: user sudah login & pernah bikin PIN di HP
/// lain (ada [JournalPinBackup] di Firestore), tapi HP ini belum punya PIN
/// lokal. Minta PIN yang sama, cocokkan ke hash cloud — begitu benar, PIN
/// itu dipersist lokal di HP ini juga (`pinService.setPin`) supaya buka
/// berikutnya jalan penuh offline seperti biasa.
///
/// CATATAN: ini cuma memulihkan GERBANG PIN-nya, bukan entri jurnal lama
/// dari HP sebelumnya — jurnal tetap murni lokal per-device (lihat laporan
/// status sinkronisasi). Tidak ada mockup desain untuk layar ini — dibangun
/// mengikuti bahasa visual JurnalPinUnlockScreen/JurnalPinSetupScreen yang
/// sudah ada.
class JurnalPinRecoverScreen extends StatefulWidget {
  const JurnalPinRecoverScreen({super.key, required this.backup});

  final JournalPinBackup backup;

  @override
  State<JurnalPinRecoverScreen> createState() => _JurnalPinRecoverScreenState();
}

class _JurnalPinRecoverScreenState extends State<JurnalPinRecoverScreen> {
  String _current = '';
  bool _error = false;
  bool _checking = false;

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
    final scope = AppScope.of(context);
    final hash = scope.pinService.hashPin(_current, widget.backup.salt);
    if (hash == widget.backup.hash) {
      await scope.pinService.setPin(_current);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      if (!mounted) return;
      setState(() {
        _error = true;
        _current = '';
        _checking = false;
      });
    }
  }

  Future<void> _mulaiPinBaru() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const JurnalPinSetupScreen()),
    );
    if (!mounted) return;
    if (created == true) Navigator.of(context).pop(true);
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
                  color: AppColors.sekunder.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.restore_rounded, size: 34, color: AppColors.sekunder),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(context.s.jurnal.pinOldTitle, style: AppTextStyles.title.copyWith(fontSize: 21)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.s.jurnal.pinOldSub,
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
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: _checking ? null : _mulaiPinBaru,
                child: Text(
                  context.s.jurnal.pinForgotOld,
                  style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
