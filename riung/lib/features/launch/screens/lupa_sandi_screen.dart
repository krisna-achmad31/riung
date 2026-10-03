import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_text_field.dart';

/// Lupa kata sandi — input email, lalu state "tautan terkirim" muncul di
/// tempat (bukan pindah layar). Implement persis
/// `design/Launch.dc.html` § Lupa / reset kata sandi.
class LupaSandiScreen extends StatefulWidget {
  const LupaSandiScreen({super.key});

  @override
  State<LupaSandiScreen> createState() => _LupaSandiScreenState();
}

class _LupaSandiScreenState extends State<LupaSandiScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = context.s.launch.invalidEmail);
      return;
    }
    setState(() {
      _emailError = null;
      _sending = true;
    });
    try {
      await AppScope.of(context).auth.kirimResetKataSandi(email);
      if (!mounted) return;
      setState(() => _sent = true);
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() => _emailError = context.s.launch.authError(e.error, e.code));
    } finally {
      if (mounted) setState(() => _sending = false);
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
                      child: RiungMonster(monsterId: 'meronta', state: MonsterVisualState.jinak, size: 70),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      t.forgotTitle,
                      style: AppTextStyles.display.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.forgotSub,
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
                    const SizedBox(height: AppSpacing.lg),
                    RiungButton(
                      label: _sending ? t.sending : t.sendResetLink,
                      onPressed: _sending ? null : _submit,
                    ),
                    if (_sent) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const _TautanTerkirimBanner(),
                    ],
                  ],
                ),
              ),
            ),
            AuthFooterLink(
              text: t.rememberedPassword,
              actionLabel: t.signIn,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TautanTerkirimBanner extends StatelessWidget {
  const _TautanTerkirimBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.sekunder.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mail_outline, size: 18, color: AppColors.sekunder),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.s.launch.linkSent,
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
