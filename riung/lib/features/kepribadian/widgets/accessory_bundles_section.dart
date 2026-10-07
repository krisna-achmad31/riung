import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/character_accessory.dart';
import '../logic/character_art.dart';

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
        const SizedBox(height: AppSpacing.sm),
        Text(t.bundlesTitle, style: AppTextStyles.title.copyWith(fontSize: 17)),
        const SizedBox(height: 6),
        Text(t.bundlesBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksSekunder)),
        const SizedBox(height: AppSpacing.md),
        for (final bundle in bundles)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _BundleCard(bundle: bundle, owned: owned, onBuy: () => onBuy(bundle)),
          ),
      ],
    );
  }
}

/// Kartu paket (frame `Paket …`): tumpukan gambar aksesori 3D, nama,
/// hemat, pil harga.
class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.bundle, required this.owned, required this.onBuy});

  final AccessoryBundle bundle;
  final Set<String> owned;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    final missing = bundle.missing(owned);
    final shown = missing.take(3).toList();
    return RiungGlassCard(
      onTap: onBuy,
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 34.0 * shown.length + 18,
            height: 56,
            child: Stack(
              children: [
                for (var i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * 32.0,
                    top: 4,
                    child: _AccessoryImage(accessory: shown[i]),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.bundleName(bundle), style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                const SizedBox(height: 2),
                Text(
                  '${t.bundleItems(missing.length)} · ${t.bundleSave(bundle.savings(owned))}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primer),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.garis)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RiungIcon3D(RiungIcon.koin, size: 16),
                const SizedBox(width: 4),
                Text(t.bundleBuy(bundle.price(owned)), style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teksUtama)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessoryImage extends StatelessWidget {
  const _AccessoryImage({required this.accessory});

  final CharacterAccessory accessory;

  @override
  Widget build(BuildContext context) {
    final art = AccessoryArt.of(accessory);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.permukaan, shape: BoxShape.circle, border: Border.all(color: AppColors.garis)),
      padding: const EdgeInsets.all(6),
      child: art == null ? const Icon(Icons.auto_awesome, size: 18, color: AppColors.sekunder) : Image.asset(art.asset(accessory), fit: BoxFit.contain, cacheWidth: 144),
    );
  }
}
