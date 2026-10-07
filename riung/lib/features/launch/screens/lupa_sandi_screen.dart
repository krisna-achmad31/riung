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
      body: SafeArea(
        child: RiungBleedListView(
          padding: const EdgeInsets.fromLTRB(24, AppSpacing.sm, 24, AppSpacing.lg),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: RiungGlassIconButton(icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).maybePop()),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 150,
                height: 150,
                margin: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.permukaan,
                  border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                  boxShadow: AppGlass.shadow,
                ),
                child: const Icon(Icons.key_rounded, size: 56, color: AppColors.primer),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(t.forgotTitle, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.2)),
            const SizedBox(height: 6),
            Text(t.forgotSub, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: t.emailLabel,
              icon: Icons.mail_outline_rounded,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              onChanged: (_) => setState(() => _emailError = null),
            ),
            const SizedBox(height: AppSpacing.md),
            RiungButton(label: _sending ? t.sending : t.sendResetLink, onPressed: _sending ? null : _submit),
            if (_sent) ...[
              const SizedBox(height: AppSpacing.md),
              const _TautanTerkirimBanner(),
            ],
            AuthFooterLink(text: t.rememberedPassword, actionLabel: t.signIn, onTap: () => Navigator.of(context).maybePop()),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.primerLembut.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 18, color: AppColors.primer),
          const SizedBox(width: 10),
          Expanded(child: Text(context.s.launch.linkSent, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.primer))),
        ],
      ),
    );
  }
}
