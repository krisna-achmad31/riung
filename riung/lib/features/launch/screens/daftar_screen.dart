import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import 'izin_notifikasi_screen.dart';
import 'masuk_screen.dart';

/// Buat akun — email, kata sandi, nama. Upgrade sesi anonim (dari
/// onboarding) jadi akun permanen lewat [AuthNotifier.daftarEmailPassword]
/// atau [AuthNotifier.daftarGoogle]. Implement persis
/// `design/Launch.dc.html` § Daftar.
class DaftarScreen extends StatefulWidget {
  const DaftarScreen({super.key, this.isPurchaseGate = false});

  /// Poin 2 — true kalau layar ini dipicu dari [ensureAccountForPurchase]
  /// (gate sebelum beli koin/Premium sungguhan), bukan dari alur onboarding
  /// biasa. Di mode ini, sukses daftar cuma `pop(true)` balik ke pemanggil
  /// (mis. TokoScreen) alih-alih push [IzinNotifikasiScreen] — layar itu
  /// pakai `pushAndRemoveUntil` yang akan menghapus TokoScreen dari stack
  /// kalau sempat kepanggil di sini.
  final bool isPurchaseGate;

  @override
  State<DaftarScreen> createState() => _DaftarScreenState();
}

class _DaftarScreenState extends State<DaftarScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _emailError = email.contains('@') && email.contains('.') ? null : context.s.launch.invalidEmail;
      _passwordError = password.length >= 6 ? null : context.s.launch.passwordTooShort;
    });
    return _emailError == null && _passwordError == null;
  }

  /// Poin 4d — begitu daftar sukses, cek apakah penyalinan progres anonim
  /// ke cloud sempat gagal ([AuthNotifier.migrationWarning]) dan
  /// tampilkan sebagai peringatan lembut. Tetap lanjut ke layar
  /// berikutnya baik warning ada atau tidak — akun sudah valid, jangan
  /// bikin user macet di sini.
  void _tampilkanPeringatanMigrasiJikaAda(AppScope scope) {
    if (!scope.auth.migrationWarning) return;
    scope.auth.clearMigrationWarning();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.launch.migrationWarning), duration: const Duration(seconds: 5)),
    );
  }

  /// Poin 2 — cabang tujuan setelah daftar sukses, lihat [DaftarScreen.isPurchaseGate].
  void _lanjutSetelahDaftar() {
    if (widget.isPurchaseGate) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IzinNotifikasiScreen()),
    );
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _submitting = true);
    try {
      final scope = AppScope.of(context);
      await scope.auth.daftarEmailPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      _tampilkanPeringatanMigrasiJikaAda(scope);
      _lanjutSetelahDaftar();
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() => _emailError = context.s.launch.authError(e.error, e.code));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _daftarGoogle() async {
    setState(() => _submitting = true);
    try {
      final scope = AppScope.of(context);
      await scope.auth.daftarGoogle();
      if (!mounted) return;
      _tampilkanPeringatanMigrasiJikaAda(scope);
      _lanjutSetelahDaftar();
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.launch.authError(e.error, e.code))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.launch;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 70,
                      height: 74,
                      child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 70),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.createAccount, style: AppTextStyles.display.copyWith(fontSize: 26)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.createAccountSub,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthTextField(
                      label: t.emailLabel,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      onChanged: (_) => setState(() => _emailError = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthTextField(
                      label: t.passwordLabel,
                      controller: _passwordController,
                      obscureText: true,
                      errorText: _passwordError,
                      onChanged: (_) => setState(() => _passwordError = null),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RiungButton(
                      label: _submitting ? context.s.common.memproses : t.signUp,
                      onPressed: _submitting ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AuthDivider(),
                    const SizedBox(height: AppSpacing.md),
                    GoogleSignInButton(onPressed: _submitting ? null : _daftarGoogle),
                  ],
                ),
              ),
            ),
            AuthFooterLink(
              text: t.hasAccount,
              actionLabel: t.signIn,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MasukScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
