import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/personality_result.dart';
import '../../../core/services/card_image_exporter.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../toko/screens/koin_kurang_screen.dart';
import '../../toko/widgets/konfirmasi_pembelian_sheet.dart';
import '../logic/card_style.dart';
import '../logic/character_accessory.dart';
import '../logic/character_spec.dart';
import '../logic/personality_config.dart';
import '../widgets/card_background_painter.dart';
import '../widgets/accessory_bundles_section.dart';
import '../widgets/character_avatar.dart';
import '../widgets/personality_share_card.dart';
import 'kepribadian_quiz_screen.dart';

/// Hasil satu tes: kartu karakter (bisa dibagikan/disimpan), gaya kartu
/// (add-on koin), kekuatan, hal yang bisa dilatih, dan kecenderungan per
/// dimensi. Nada hangat, tidak menghakimi, dan tidak ada hasil "lebih baik".
class KepribadianHasilScreen extends StatefulWidget {
  const KepribadianHasilScreen({super.key, required this.result});

  final PersonalityResult result;

  @override
  State<KepribadianHasilScreen> createState() => _KepribadianHasilScreenState();
}

class _KepribadianHasilScreenState extends State<KepribadianHasilScreen> {
  final GlobalKey _cardKey = GlobalKey();
  late CardStyle _style = CardStyle.fromId(AppScope.of(context).prefs.personalityCardStyle(widget.result.test));
  bool _busy = false;
  late List<CharacterAccessory> _accessories = AccessoryLoadout(AppScope.of(context).prefs).of(widget.result.test);
  AccessorySlot _slot = AccessorySlot.head;

  ProfileText _text(KepribadianStrings t) {
    switch (widget.result.test) {
      case PersonalityTest.jung:
        return t.jungType(widget.result.code);
      case PersonalityTest.temperament:
        return t.temperament(widget.result.code);
      case PersonalityTest.attachment:
        return t.attachment(widget.result.code);
    }
  }

  Future<void> _pilihGaya(CardStyle style) async {
    final scope = AppScope.of(context);
    final t = scope.language.strings.kepribadian;
    final wallet = scope.wallet;
    final premium = scope.auth.profile?.premiumNow ?? false;
    if (!style.isFree && !premium && !wallet.ownsCosmetic(style.cosmeticId)) {
      final price = style.price!;
      if (wallet.coins < price) {
        // Garis etis: kalau koin kurang, tawarkan latihan dulu (layar koin kurang).
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => KoinKurangScreen(needed: price, backTitle: t.title)));
        return;
      }
      final ok = await showKonfirmasiPembelianSheet(context, itemLabel: t.styleConfirmLabel(t.styleName(style.id)), price: price);
      if (!ok || !mounted) return;
      final bought = await wallet.buyCosmetic(id: style.cosmeticId, price: price);
      if (!bought || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.styleBought(t.styleName(style.id)))));
    }
    await scope.prefs.setPersonalityCardStyle(widget.result.test, style.id);
    if (mounted) setState(() => _style = style);
  }

  Future<void> _pilihAksesori(CharacterAccessory accessory) async {
    final scope = AppScope.of(context);
    final t = scope.language.strings.kepribadian;
    final wallet = scope.wallet;
    final loadout = AccessoryLoadout(scope.prefs);
    final test = widget.result.test;
    final worn = _accessories.contains(accessory);
    if (worn) {
      await loadout.unequip(test, accessory.slot);
    } else {
      if (!wallet.ownsCosmetic(accessory.cosmeticId)) {
        final price = accessory.price;
        if (wallet.coins < price) {
          // Garis etis: koin kurang -> latihan dulu, baru beli.
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => KoinKurangScreen(needed: price, backTitle: t.title)));
          return;
        }
        final ok = await showKonfirmasiPembelianSheet(context, itemLabel: t.accessoryConfirmLabel(t.accessoryName(accessory)), price: price);
        if (!ok || !mounted) return;
        final bought = await wallet.buyCosmetic(id: accessory.cosmeticId, price: price);
        if (!bought || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.accessoryBought(t.accessoryName(accessory)))));
      }
      await loadout.equip(test, accessory);
    }
    if (mounted) setState(() => _accessories = loadout.of(test));
  }

  Future<void> _pilihPaket(AccessoryBundle bundle) async {
    final scope = AppScope.of(context);
    final t = scope.language.strings.kepribadian;
    final wallet = scope.wallet;
    final owned = wallet.ownedCosmetics;
    final price = bundle.price(owned);
    if (price <= 0) return;
    if (wallet.coins < price) {
      // Garis etis: koin kurang -> latihan dulu, baru beli.
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => KoinKurangScreen(needed: price, backTitle: t.title)));
      return;
    }
    final name = t.bundleName(bundle);
    final ok = await showKonfirmasiPembelianSheet(context, itemLabel: t.bundleConfirmLabel(name), price: price);
    if (!ok || !mounted) return;
    final bought = await wallet.buyCosmeticBundle(
      bundleId: bundle.id,
      ids: [for (final a in bundle.items) a.cosmeticId],
      price: price,
    );
    if (!bought || !mounted) return;
    final loadout = AccessoryLoadout(scope.prefs);
    for (final a in bundle.items) {
      await loadout.equip(widget.result.test, a);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.bundleBought(name))));
    setState(() => _accessories = loadout.of(widget.result.test));
  }

  Future<void> _simpan() async {
    if (_busy) return;
    setState(() => _busy = true);
    final t = context.s.kepribadian;
    try {
      final bytes = await CardImageExporter.capture(_cardKey);
      if (bytes == null) throw Exception('render gagal');
      await CardImageExporter.saveToGallery(bytes, namePrefix: 'riung_karakter');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.imageSaved)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.imageSaveFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bagikan() async {
    if (_busy) return;
    setState(() => _busy = true);
    final t = context.s.kepribadian;
    final name = _text(t).name;
    try {
      final bytes = await CardImageExporter.capture(_cardKey);
      if (bytes == null) throw Exception('render gagal');
      await CardImageExporter.share(bytes, namePrefix: 'riung_karakter', text: t.shareText(name));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.imageShareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    final wallet = AppScope.of(context).wallet;
    final premium = AppScope.of(context).auth.profile?.premiumNow ?? false;
    final result = widget.result;
    final text = _text(t);
    final spec = CharacterSpec.fromResult(result);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 2 * AppSpacing.xl).clamp(0.0, 340.0);

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
                  ),
                  Text(t.testName(result.test), style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  Center(
                    child: SizedBox(
                      width: cardWidth,
                      child: RepaintBoundary(key: _cardKey, child: PersonalityShareCard(result: result, style: _style, accessories: _accessories)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: RiungButton(label: t.shareCard, onPressed: _busy ? null : _bagikan)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: RiungButton(label: t.saveImage, variant: RiungButtonVariant.secondary, onPressed: _busy ? null : _simpan)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(t.customizeTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(t.customizeBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5)),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      for (final slot in AccessorySlot.values)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: GestureDetector(
                            onTap: () => setState(() => _slot = slot),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: _slot == slot ? AppColors.primer : Colors.transparent,
                                border: Border.all(color: _slot == slot ? AppColors.primer : AppColors.garis),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                t.slotName(slot),
                                style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: _slot == slot ? AppColors.latar : AppColors.teksSekunder),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListenableBuilder(
                    listenable: wallet,
                    builder: (context, _) => SizedBox(
                      height: 132,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final accessory in CharacterAccessory.catalogFor(result.test, _slot))
                            Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.sm),
                              child: _AccessoryTile(
                                accessory: accessory,
                                spec: spec,
                                exclusive: accessory.category != null,
                                worn: _accessories.contains(accessory),
                                owned: wallet.ownsCosmetic(accessory.cosmeticId),
                                onTap: () => _pilihAksesori(accessory),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: wallet,
                    builder: (context, _) {
                      final owned = wallet.ownedCosmetics;
                      final bundles = [for (final b in AccessoryBundle.catalogFor(result.test)) if (b.worthBuying(owned)) b];
                      if (bundles.isEmpty) return const SizedBox.shrink();
                      return AccessoryBundlesSection(bundles: bundles, owned: owned, onBuy: _pilihPaket);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(t.stylesTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(t.stylesBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5)),
                  const SizedBox(height: AppSpacing.md),
                  ListenableBuilder(
                    listenable: wallet,
                    builder: (context, _) => SizedBox(
                      height: 88,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final style in CardStyle.values)
                            Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.sm),
                              child: _StyleChip(
                                style: style,
                                tint: spec.base,
                                selected: style == _style,
                                owned: style.isFree || premium || wallet.ownsCosmetic(style.cosmeticId),
                                onTap: () => _pilihGaya(style),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _Section(title: t.strengthsTitle, children: [
                    for (final s in text.strengths)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_rounded, size: 15, color: AppColors.sukses),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(s, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5))),
                          ],
                        ),
                      ),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _Section(title: t.growthTitle, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(text.growth, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _Section(title: t.scoresTitle, children: [
                    const SizedBox(height: AppSpacing.sm),
                    for (final key in _scoreKeys(result))
                      _ScoreBar(label: t.axisLabel(key), percent: result.scores[key] ?? 0, color: spec.base),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.gentleNote, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(t.disclaimer, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.5)),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => KepribadianQuizScreen(test: result.test)),
                    ),
                    child: Text(t.retake, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _scoreKeys(PersonalityResult r) {
    switch (r.test) {
      case PersonalityTest.jung:
        return [for (final dim in PersonalityConfig.jungDimensions) ...[dim[0], dim[1]]];
      case PersonalityTest.temperament:
        return PersonalityConfig.temperaments;
      case PersonalityTest.attachment:
        return const ['cemas', 'menghindar'];
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6)),
          ...children,
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.label, required this.percent, required this.color});

  final String label;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.chipLabel.copyWith(fontSize: 12)),
              Text('$percent%', style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(value: percent / 100, minHeight: 6, backgroundColor: AppColors.latar, valueColor: AlwaysStoppedAnimation(color)),
          ),
        ],
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({required this.style, required this.tint, required this.selected, required this.owned, required this.onTap});

  final CardStyle style;
  final Color tint;
  final bool selected;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: selected ? 2 : 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: CardBackgroundPainter(style, tint)),
                  if (!owned) const Center(child: Icon(Icons.lock_rounded, size: 16, color: AppColors.teksUtama)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            owned ? t.styleName(style.id) : t.styleBuy(style.price ?? 0),
            style: AppTextStyles.caption.copyWith(fontSize: 10, color: owned ? AppColors.teksSekunder : AppColors.aksenHangat, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Satu aksesori: pratinjau karakter memakainya, nama, dan harga / status.
class _AccessoryTile extends StatelessWidget {
  const _AccessoryTile({required this.accessory, required this.spec, required this.exclusive, required this.worn, required this.owned, required this.onTap});

  final CharacterAccessory accessory;
  final CharacterSpec spec;
  final bool exclusive;
  final bool worn;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: worn ? AppColors.primer.withValues(alpha: 0.12) : AppColors.permukaan,
          border: Border.all(color: worn ? AppColors.primer : AppColors.garis, width: worn ? 1.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            CharacterAvatar(spec: spec, size: 56, accessories: [accessory]),
            const SizedBox(height: 4),
            Text(t.accessoryName(accessory), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.chipLabel.copyWith(fontSize: 11)),
            if (exclusive) Text(t.accessoryExclusive, style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.monsterCermin, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              worn
                  ? t.accessoryEquipped
                  : owned
                      ? t.styleOwned
                      : t.styleBuy(accessory.price),
              style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: worn ? AppColors.primer : (owned ? AppColors.teksSekunder : AppColors.aksenHangat)),
            ),
          ],
        ),
      ),
    );
  }
}
