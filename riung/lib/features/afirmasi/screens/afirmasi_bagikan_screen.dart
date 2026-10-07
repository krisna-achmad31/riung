import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/affirmation.dart';
import '../../../core/services/card_image_exporter.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/afirmasi_glass_card.dart';

/// Bagikan kartu afirmasi sebagai gambar — isi jurnal & data pribadi tidak
/// pernah ikut terbagikan. Visual: `Glass — Afirmasi · Bagikan` di
/// `design/riung.pen` (3 opsi: simpan gambar, salin, lainnya).
class AfirmasiBagikanScreen extends StatefulWidget {
  const AfirmasiBagikanScreen({super.key, required this.card, required this.monsterId});

  final Affirmation card;
  final String monsterId;

  @override
  State<AfirmasiBagikanScreen> createState() => _AfirmasiBagikanScreenState();
}

class _AfirmasiBagikanScreenState extends State<AfirmasiBagikanScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _simpanGambar() async {
    if (_busy) return;
    setState(() => _busy = true);
    final t = context.s.afirmasi;
    try {
      final bytes = await CardImageExporter.capture(_cardKey);
      if (bytes == null) throw Exception('render gagal');
      await CardImageExporter.saveToGallery(bytes, namePrefix: 'riung_afirmasi');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cardSaved)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cardSaveFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bagikanGambar() async {
    if (_busy) return;
    setState(() => _busy = true);
    final t = context.s.afirmasi;
    try {
      final bytes = await CardImageExporter.capture(_cardKey);
      if (bytes == null) throw Exception('render gagal');
      await CardImageExporter.share(bytes, namePrefix: 'riung_afirmasi', text: t.shareText(t.textOf(widget.card)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cardShareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _salinTeks() async {
    final t = context.s.afirmasi;
    await Clipboard.setData(ClipboardData(text: t.shareText(t.textOf(widget.card))));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.textCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.afirmasi;
    final monsterName = context.s.common.monsterName(widget.monsterId);
    final options = [
      (Icons.download_rounded, _busy ? context.s.common.memproses : t.saveAsImage, _simpanGambar),
      (Icons.copy_rounded, t.targetCopy, _salinTeks),
      (Icons.share_rounded, t.targetMore, _bagikanGambar),
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
          children: [
            RiungGlassHeader(title: t.shareTitle),
            const SizedBox(height: AppSpacing.lg),
            RepaintBoundary(
              key: _cardKey,
              child: AfirmasiGlassCard(
                tag: t.cardLabelMonster(monsterName),
                monsterId: widget.monsterId,
                monsterSize: 150,
                tagOnWhite: true,
                text: t.textOf(widget.card),
                footer: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primer, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(t.cardBrand, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksSekunder)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(t.shareNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.teksSekunder)),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final (icon, label, onTap) in options)
                  SizedBox(
                    width: 100,
                    child: GestureDetector(
                      onTap: _busy ? null : onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: AppGlass.card(radius: 28),
                            alignment: Alignment.center,
                            child: Icon(icon, size: 22, color: AppColors.teksUtama),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.teksSekunder),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
