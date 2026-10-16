import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'riung_button.dart';
import 'riung_icon_3d.dart';

/// State kosong standar (ikon 3D + judul + penjelasan + aksi opsional).
/// Dipakai lewat [RiungStateView.empty] / [RiungAsyncView.empty] supaya
/// semua layar punya "belum ada data" yang seragam, dengan copy dari
/// strings fitur masing-masing.
class RiungEmptyState extends StatelessWidget {
  const RiungEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final RiungIcon? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final message = this.message;
    final actionLabel = this.actionLabel;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              RiungIcon3D(icon, size: 72),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(message, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              RiungButton(label: actionLabel, variant: RiungButtonVariant.secondary, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
