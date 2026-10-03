import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';
import 'riung_button.dart';

/// State error umum (ikon + pesan + "Coba lagi") — dipakai di layar mana
/// pun yang bisa gagal karena jaringan/Firestore, supaya tiap layar
/// nggak bikin versinya sendiri-sendiri. Lihat CLAUDE.md "Definition of
/// done": tiap layar wajib punya state error yang jelas.
class RiungErrorWidget extends StatelessWidget {
  const RiungErrorWidget({
    super.key,
    this.message,
    this.onRetry,
  });

  /// Kosong → pesan umum sesuai bahasa aktif (`common.loadFailed`).
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.teksRedup),
            const SizedBox(height: AppSpacing.md),
            Text(message ?? context.s.common.loadFailed, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13)),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              RiungButton(label: context.s.common.cobaLagi, variant: RiungButtonVariant.secondary, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
