import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Sheet konfirmasi pembelian koin generik — dipakai tiap kali Toko
/// mengeluarkan koin (sesi fokus, pelindung streak, kosmetik). Implement
/// persis `design/Toko.dc.html` § "Konfirmasi pembelian". Pemanggil yang
/// menjalankan mutasi koin sungguhan setelah sheet ini mengembalikan
/// `true` — sheet sendiri cuma UI konfirmasi.
Future<bool> showKonfirmasiPembelianSheet(
  BuildContext context, {
  required String itemLabel,
  required int price,
}) async {
  final wallet = AppScope.of(context).wallet;
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.permukaan,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => ListenableBuilder(
      listenable: wallet,
      builder: (context, _) {
        final sisa = (wallet.coins - price).clamp(0, 1 << 31);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.garis, borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(context.s.toko.confirmTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 17)),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.kartu,
                  border: Border.all(color: AppColors.garis),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    _Baris(label: itemLabel, value: '$price', valueColor: AppColors.aksenHangat),
                    const SizedBox(height: AppSpacing.sm),
                    _Baris(label: context.s.toko.coinsNow, value: '${wallet.coins}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(color: AppColors.garis, height: 1),
                    ),
                    _Baris(label: context.s.toko.remainingAfter, value: context.s.toko.remainingCoins(sisa), bold: true, valueColor: AppColors.aksenHangat),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.s.toko.ethicNote,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
              const SizedBox(height: AppSpacing.lg),
              RiungButton(label: context.s.toko.confirmYes, onPressed: () => Navigator.of(sheetContext).pop(true)),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text(context.s.common.batal, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
              ),
            ],
          ),
        );
      },
    ),
  );
  return result ?? false;
}

class _Baris extends StatelessWidget {
  const _Baris({required this.label, required this.value, this.bold = false, this.valueColor});

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(fontSize: 13)),
        Text(
          value,
          style: (bold ? AppTextStyles.subtitle : AppTextStyles.chipLabel).copyWith(
            fontSize: bold ? 14 : 13,
            color: valueColor ?? AppColors.teksUtama,
          ),
        ),
      ],
    );
  }
}
