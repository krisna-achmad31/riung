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
    this.icon,
    this.hint,
  });

  /// Placeholder saat kosong (frame `Nilai` berwarna ink-faint).
  final String? hint;

  /// Ikon garis di kiri (frame `Field …`: mail / lock).
  final IconData? icon;

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
    final borderColor = hasError ? AppColors.aksenHangat : (_focusNode.hasFocus ? AppColors.primer : AppColors.garis);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: AppColors.permukaan,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: AppGlass.edgeWidth),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: active ? AppColors.primer : AppColors.teksRedup),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: hasError ? AppColors.aksenHangatGelap : AppColors.teksRedup),
                    ),
                    const SizedBox(height: 2),
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
                      style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 14, fontWeight: FontWeight.w600),
                      cursorColor: AppColors.primer,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        hintText: widget.hint,
                        hintStyle: AppTextStyles.body.copyWith(color: AppColors.teksRedup, fontSize: 14, fontWeight: FontWeight.w600),
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.obscureText)
                IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.teksRedup, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(widget.errorText!, style: AppTextStyles.caption.copyWith(color: AppColors.aksenHangatGelap)),
          ),
        ],
      ],
    );
  }
}
