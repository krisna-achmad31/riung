import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../logic/character_accessory.dart';

/// Daftar paket aksesori berdiskon. Harga & hemat dihitung dari item yang
/// belum dimiliki ([owned]); memilih paket memanggil [onBuy].
class AccessoryBundlesSection extends StatelessWidget {
  const AccessoryBundlesSection({super.key, required this.bundles, required this.owned, required this.onBuy});

  final List<AccessoryBundle> bundles;
  final Set<String> owned;
  final ValueChanged<AccessoryBundle> onBuy;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(t.bundlesTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpacing.xs),
        Text(t.bundlesBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5)),
        const SizedBox(height: AppSpacing.md),
        for (final bundle in bundles)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _BundleCard(bundle: bundle, owned: owned, onBuy: () => onBuy(bundle)),
          ),
      ],
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.bundle, required this.owned, required this.onBuy});

  final AccessoryBundle bundle;
  final Set<String> owned;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    final missing = bundle.missing(owned);
    return GestureDetector(
      onTap: onBuy,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.bundleName(bundle), style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksUtama)),
                  const SizedBox(height: 2),
                  Text(
                    '${t.bundleItems(missing.length)} · ${missing.map(t.accessoryName).join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Text(t.bundleSave(bundle.savings(owned)), style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.sukses, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primer, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text(t.bundleBuy(bundle.price(owned)), style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: AppColors.latar)),
            ),
          ],
        ),
      ),
    );
  }
}
