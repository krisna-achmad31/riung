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
import '../logic/character_art.dart';
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
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => KoinKurangScreen(needed: price, backTitle: t.title),
          ),
        );
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
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => KoinKurangScreen(needed: price, backTitle: t.title),
            ),
          );
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
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KoinKurangScreen(needed: price, backTitle: t.title),
        ),
      );
      return;
    }
    final name = t.bundleName(bundle);
    final ok = await showKonfirmasiPembelianSheet(context, itemLabel: t.bundleConfirmLabel(name), price: price);
    if (!ok || !mounted) return;
    final bought = await wallet.buyCosmeticBundle(bundleId: bundle.id, ids: [for (final a in bundle.items) a.cosmeticId], price: price);
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(
                title: t.testName(result.test),
                trailing: RiungGlassIconButton(icon: Icons.share_rounded, semanticLabel: t.shareCard, onTap: _busy ? () {} : _bagikan),
              ),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
                  children: [
                    Center(
                      child: SizedBox(
                        width: cardWidth,
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: PersonalityShareCard(result: result, style: _style, accessories: _accessories),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: RiungButton(label: t.saveImage, variant: RiungButtonVariant.secondary, onPressed: _busy ? null : _simpan),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RiungButton(label: t.shareCard, onPressed: _busy ? null : _bagikan),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(t.customizeTitle, style: AppTextStyles.title.copyWith(fontSize: 17)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(t.customizeBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.md),
                    RiungSegmentedTabs(
                      labels: [for (final slot in AccessorySlot.values) t.slotName(slot)],
                      index: AccessorySlot.values.indexOf(_slot),
                      onChanged: (i) => setState(() => _slot = AccessorySlot.values[i]),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListenableBuilder(
                      listenable: wallet,
                      builder: (context, _) {
                        final items = CharacterAccessory.catalogFor(result.test, _slot);
                        Widget tile(CharacterAccessory a) => _AccessoryTile(
                          accessory: a,
                          spec: spec,
                          exclusive: a.category != null,
                          worn: _accessories.contains(a),
                          owned: wallet.ownsCosmetic(a.cosmeticId),
                          onTap: () => _pilihAksesori(a),
                        );
                        return Column(
                          children: [
                            for (var i = 0; i < items.length; i += 2)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(child: tile(items[i])),
                                      const SizedBox(width: 12),
                                      Expanded(child: i + 1 < items.length ? tile(items[i + 1]) : const SizedBox.shrink()),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    ListenableBuilder(
                      listenable: wallet,
                      builder: (context, _) {
                        final owned = wallet.ownedCosmetics;
                        final bundles = [
                          for (final b in AccessoryBundle.catalogFor(result.test))
                            if (b.worthBuying(owned)) b,
                        ];
                        if (bundles.isEmpty) return const SizedBox.shrink();
                        return AccessoryBundlesSection(bundles: bundles, owned: owned, onBuy: _pilihPaket);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(t.stylesTitle, style: AppTextStyles.title.copyWith(fontSize: 17)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(t.stylesBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksSekunder)),
                    const SizedBox(height: AppSpacing.md),
                    ListenableBuilder(
                      listenable: wallet,
                      builder: (context, _) => Row(
                        children: [
                          for (final style in CardStyle.values)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _StyleChip(
                                  style: style,
                                  tint: spec.base,
                                  selected: style == _style,
                                  owned: style.isFree || premium || wallet.ownsCosmetic(style.cosmeticId),
                                  onTap: () => _pilihGaya(style),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _Section(
                      title: t.strengthsTitle,
                      children: [
                        for (final s in text.strengths)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_rounded, size: 15, color: AppColors.primer),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(child: Text(s, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5))),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Section(
                      title: t.growthTitle,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(text.growth, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Section(
                      title: t.scoresTitle,
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        for (final key in _scoreKeys(result)) _ScoreBar(label: t.axisLabel(key), percent: result.scores[key] ?? 0, color: spec.base),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      t.gentleNote,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksSekunder),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(t.disclaimer, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.5)),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => KepribadianQuizScreen(test: result.test))),
                      child: Text(t.retake, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _scoreKeys(PersonalityResult r) {
    switch (r.test) {
      case PersonalityTest.jung:
        return [
          for (final dim in PersonalityConfig.jungDimensions) ...[dim[0], dim[1]],
        ];
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
    return RiungGlassCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title.copyWith(fontSize: 15)),
          ...children,
        ],
      ),
    );
  }
}

/// Bilah kecenderungan (frame `Skala …`): label + persen, isi gradien lavender.
class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.label, required this.percent, required this.color});

  final String label;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label $percent%', style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: AppColors.teksUtama)),
          const SizedBox(height: 5),
          Container(
            height: 8,
            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(4)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              heightFactor: 1,
              widthFactor: (percent / 100).clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.kabutLavender, AppColors.sekunder]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pratinjau gaya kartu (frame `Gaya …`).
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
          AspectRatio(
            aspectRatio: 64 / 78,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? AppColors.sekunder : AppColors.garis, width: selected ? 2.5 : 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: CardBackgroundPainter(style, tint)),
                    if (!owned)
                      Center(child: Icon(Icons.lock_rounded, size: 16, color: CardBackgroundPainter.isDark(style) ? AppNight.teks : AppColors.teksSekunder)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.styleName(style.id),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teksUtama),
          ),
          Text(
            selected ? t.accessoryEquipped : (owned ? t.styleOwned : t.styleBuy(style.price ?? 0)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w600, color: selected ? AppColors.sekunder : AppColors.teksSekunder),
          ),
        ],
      ),
    );
  }
}

/// Ubin aksesori (frame `Aksesori …`): pil tier, gambar 3D aksesori, nama,
/// harga / status dipakai.
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
    final art = AccessoryArt.of(accessory);
    final rare = exclusive || accessory.tier == AccessoryTier.langka;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: worn ? AppColors.permukaanPadat.withValues(alpha: 0.85) : AppColors.kartu,
          border: Border.all(color: worn ? AppColors.sekunder : AppColors.garis, width: worn ? 2 : 1.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: rare ? AppColors.sekunderLembut : AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text(
                exclusive ? t.accessoryExclusive : t.tierName(accessory.tier),
                style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: rare ? AppColors.sekunder : AppColors.teksSekunder),
              ),
            ),
            SizedBox(
              height: 80,
              child: Center(
                child: art != null
                    ? Image.asset(art.asset(accessory), height: 70, fit: BoxFit.contain, cacheHeight: 210)
                    : CharacterAvatar(spec: spec, size: 70, accessories: [accessory]),
              ),
            ),
            Text(
              t.accessoryName(accessory),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksUtama),
            ),
            const SizedBox(height: 6),
            if (worn)
              Row(
                children: [
                  const Icon(Icons.check_rounded, size: 13, color: AppColors.sekunder),
                  const SizedBox(width: 4),
                  Text(
                    t.accessoryEquipped,
                    style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sekunder),
                  ),
                ],
              )
            else if (owned)
              Text(
                t.styleOwned,
                style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksSekunder),
              )
            else
              Container(
                padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
                decoration: BoxDecoration(
                  color: AppColors.permukaan,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.garis),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const RiungIcon3D(RiungIcon.koin, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      t.styleBuy(accessory.price),
                      style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teksUtama),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
