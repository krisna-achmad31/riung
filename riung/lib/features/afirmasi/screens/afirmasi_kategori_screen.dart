import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/affirmation_deck.dart';
import '../widgets/afirmasi_deck_tile.dart';
import '../widgets/afirmasi_today_card.dart';
import 'afirmasi_buat_screen.dart';
import 'afirmasi_kartu_screen.dart';
import 'afirmasi_pengingat_screen.dart';

/// Koleksi deck afirmasi. Alur & copy: `design/Afirmasi.dc.html` § Koleksi
/// afirmasi; visual: `Glass — Afirmasi · Kategori` di `design/riung.pen`.
class AfirmasiKategoriScreen extends StatefulWidget {
  const AfirmasiKategoriScreen({super.key});

  @override
  State<AfirmasiKategoriScreen> createState() => _AfirmasiKategoriScreenState();
}

class _AfirmasiKategoriScreenState extends State<AfirmasiKategoriScreen> {
  List<AffirmationDeck>? _decks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.profile?.uid;
    final seeded = await scope.contentRepository.getAffirmations();
    final custom = uid == null ? <Affirmation>[] : await scope.userRepository.getCustomAffirmations(uid);
    if (!mounted) return;
    setState(() {
      _decks = buildAffirmationDecks(seeded: seeded, custom: custom);
    });
  }

  Future<void> _openBuat() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AfirmasiBuatScreen()),
    );
    if (created == true) _load();
  }

  void _openDeck(AffirmationDeck deck) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AfirmasiKartuScreen(deck: deck)));
  }

  /// Kartu harian: dipilih deterministik dari hari ke-n dalam setahun,
  /// hanya dari deck monster (bukan buatan sendiri).
  (AffirmationDeck, Affirmation)? _today(List<AffirmationDeck> decks) {
    final pool = [
      for (final d in decks)
        if (d.monsterId != null)
          for (final c in d.cards) (d, c),
    ];
    if (pool.isEmpty) return null;
    final now = DateTime.now();
    final day = now.difference(DateTime(now.year)).inDays;
    return pool[day % pool.length];
  }

  @override
  Widget build(BuildContext context) {
    final decks = _decks;
    final t = context.s.afirmasi;
    final canPop = Navigator.canPop(context);
    final today = decks == null ? null : _today(decks);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: decks == null
            ? const SizedBox.shrink()
            : RiungBleedListView(
                bleed: 0,
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl + MediaQuery.paddingOf(context).bottom),
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        if (canPop)
                          RiungGlassIconButton(icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).maybePop())
                        else
                          const SizedBox(width: 44),
                        Expanded(
                          child: Text(
                            t.title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.title.copyWith(fontSize: 17, color: AppColors.teksUtama),
                          ),
                        ),
                        RiungGlassIconButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AfirmasiPengingatScreen())),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        RiungGlassIconButton(icon: Icons.add_rounded, onTap: _openBuat),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(t.subtitle, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
                  if (today != null) ...[
                    AfirmasiTodayCard(
                      eyebrow: t.cardScreenTitle,
                      quote: t.textOf(today.$2),
                      meta: t.cards(today.$1.cards.length),
                      onTap: () => _openDeck(today.$1),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (decks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Text(t.noDecks, textAlign: TextAlign.center, style: AppTextStyles.body),
                    )
                  else
                    for (var i = 0; i < decks.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _tile(decks[i])),
                              const SizedBox(width: 12),
                              Expanded(child: i + 1 < decks.length ? _tile(decks[i + 1]) : const SizedBox.shrink()),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
      ),
    );
  }

  Widget _tile(AffirmationDeck deck) {
    final t = context.s.afirmasi;
    final id = deck.monsterId;
    return AfirmasiDeckTile(
      monsterId: id,
      title: id == null ? t.customDeck : t.deckAgainst(context.s.common.monsterName(id)),
      meta: t.cards(deck.cards.length),
      onTap: () => _openDeck(deck),
    );
  }
}
