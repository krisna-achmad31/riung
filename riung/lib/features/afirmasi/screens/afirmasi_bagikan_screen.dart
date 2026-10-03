import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/affirmation.dart';
import '../../../core/services/card_image_exporter.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Aksi tap tombol target — semua ("WhatsApp"/"Instagram"/"Lainnya") buka
/// share sheet native yang sama (OS yang urus daftar app tujuannya),
/// kecuali "Salin" yang langsung menyalin teksnya ke clipboard tanpa
/// buka share sheet.
enum _ShareAction { shareSheet, salin }

/// Bagikan kartu afirmasi sebagai gambar — isi jurnal & data pribadi tidak
/// pernah ikut terbagikan. Implement persis `design/Afirmasi.dc.html`
/// § Bagikan kartu.
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

  void _onTargetTap(_ShareAction action) {
    switch (action) {
      case _ShareAction.shareSheet:
        _bagikanGambar();
      case _ShareAction.salin:
        _salinTeks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.afirmasi;
    final shareTargets = [
      (Icons.chat_bubble, 'WhatsApp', AppColors.sukses, _ShareAction.shareSheet),
      (Icons.camera_alt, 'Instagram', AppColors.error, _ShareAction.shareSheet),
      (Icons.copy, t.targetCopy, AppColors.teksSekunder, _ShareAction.salin),
      (Icons.more_horiz, t.targetMore, AppColors.teksSekunder, _ShareAction.shareSheet),
    ];
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder)),
                  Text(t.shareTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RepaintBoundary(
                      key: _cardKey,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A2461), Color(0xFF161A45)]),
                          border: Border.all(color: const Color(0xFF3A3580)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 64, height: 67, child: RiungMonster(monsterId: widget.monsterId, state: MonsterVisualState.jinak, size: 64)),
                            const SizedBox(height: AppSpacing.sm),
                            Text('"${t.textOf(widget.card)}"', textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 18, height: 1.45)),
                            const SizedBox(height: AppSpacing.sm),
                            Text('riung.app', style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primer)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      t.shareNote,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final target in shareTargets)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: GestureDetector(
                              onTap: _busy ? null : () => _onTargetTap(target.$4),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.permukaan, border: Border.all(color: AppColors.garis)),
                                    alignment: Alignment.center,
                                    child: Icon(target.$1, size: 22, color: target.$3),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(target.$2, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _simpanGambar,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.garis, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                  icon: const Icon(Icons.download, size: 16, color: AppColors.teksSekunder),
                  label: Text(
                    _busy ? context.s.common.memproses : t.saveAsImage,
                    style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
