import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Field form auth (email/kata sandi) — label mengambang, border berubah
/// warna saat fokus, opsional toggle lihat/sembunyikan untuk kata sandi.
/// Dipakai di Daftar/Masuk/LupaSandi (`design/Launch.dc.html`).
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.autofocus = false,
    this.onChanged,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late final FocusNode _focusNode;
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focusNode = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final active = _focusNode.hasFocus || widget.controller.text.isNotEmpty;
    final borderColor = hasError
        ? AppColors.error
        : (active ? AppColors.primer : AppColors.garis);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.permukaan,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasError
                            ? AppColors.error
                            : (active ? AppColors.primer : AppColors.teksRedup),
                      ),
                    ),
                    const SizedBox(height: 3),
                    TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      obscureText: widget.obscureText && _obscured,
                      keyboardType: widget.keyboardType,
                      autofocus: widget.autofocus,
                      onChanged: (v) {
                        widget.onChanged?.call(v);
                        setState(() {});
                      },
                      style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 15),
                      cursorColor: AppColors.primer,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.obscureText)
                IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.teksRedup,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(widget.errorText!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
        ],
      ],
    );
  }
}
