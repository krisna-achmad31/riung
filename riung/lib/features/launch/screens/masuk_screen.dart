import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../home/screens/root_shell_screen.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import 'daftar_screen.dart';
import 'lupa_sandi_screen.dart';

/// Masuk — email + kata sandi, opsi Google. Implement persis
/// `design/Launch.dc.html` § Masuk.
class MasukScreen extends StatefulWidget {
  const MasukScreen({super.key});

  @override
  State<MasukScreen> createState() => _MasukScreenState();
}

class _MasukScreenState extends State<MasukScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _formError = context.s.launch.fillFirst);
      return;
    }
    setState(() {
      _formError = null;
      _submitting = true;
    });
    try {
      await AppScope.of(context).auth.masukEmailPassword(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootShellScreen()),
        (route) => false,
      );
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() => _formError = context.s.launch.authError(e.error, e.code));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _masukGoogle() async {
    setState(() => _submitting = true);
    try {
      await AppScope.of(context).auth.masukGoogle();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootShellScreen()),
        (route) => false,
      );
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
                      child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 70),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.welcomeBack, style: AppTextStyles.display.copyWith(fontSize: 26)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(t.monstersWaiting, style: AppTextStyles.body),
                    const SizedBox(height: AppSpacing.lg),
                    AuthTextField(
                      label: t.emailLabel,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() => _formError = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthTextField(
                      label: t.passwordLabel,
                      controller: _passwordController,
                      obscureText: true,
                      onChanged: (_) => setState(() => _formError = null),
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(_formError!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LupaSandiScreen()),
                        ),
                        child: Text(
                          t.forgotPassword,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    RiungButton(
                      label: _submitting ? context.s.common.memproses : t.signIn,
                      onPressed: _submitting ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AuthDivider(),
                    const SizedBox(height: AppSpacing.md),
                    GoogleSignInButton(onPressed: _submitting ? null : _masukGoogle),
                  ],
                ),
              ),
            ),
            AuthFooterLink(
              text: t.noAccount,
              actionLabel: t.signUp,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DaftarScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
