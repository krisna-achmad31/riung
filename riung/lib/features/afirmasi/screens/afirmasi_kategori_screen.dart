import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../toko/screens/paywall_premium_screen.dart';
import '../logic/affirmation_deck.dart';
import '../widgets/afirmasi_deck_tile.dart';
import '../widgets/afirmasi_today_card.dart';
import 'afirmasi_buat_screen.dart';
import 'afirmasi_kartu_screen.dart';
import 'afirmasi_pengingat_screen.dart';

/// Koleksi deck afirmasi. Alur & copy: `design/Afirmasi.dc.html` § Koleksi
/// afirmasi; visual: `Glass — Afirmasi · Kategori` di `design/riung.pen`.
class AfirmasiKategoriScreen extends StatefulWidget {
  const AfirmasiKategoriScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AfirmasiKategoriScreen> createState() => _AfirmasiKategoriScreenState();
}

class _AfirmasiKategoriScreenState extends State<AfirmasiKategoriScreen> {
  List<AffirmationDeck>? _decks;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_error != null) setState(() => _error = null);
    final scope = AppScope.of(context);
    final uid = scope.auth.profile?.uid;
    try {
      final seeded = await scope.contentRepository.getAffirmations();
      final custom = uid == null ? <Affirmation>[] : await scope.userRepository.getCustomAffirmations(uid);
      if (!mounted) return;
      setState(() {
        _decks = buildAffirmationDecks(seeded: seeded, custom: custom);
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _openBuat() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AfirmasiBuatScreen()),
    );
    if (created == true) _load();
  }

  bool get _premium => AppScope.of(context).auth.profile?.premiumNow ?? false;

  void _openDeck(AffirmationDeck deck) {
    if (deck.isPremium && !_premium) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPremiumScreen()));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AfirmasiKartuScreen(deck: deck)));
  }

  /// Kartu harian: dipilih deterministik dari hari ke-n dalam setahun,
  /// hanya dari deck monster (bukan buatan sendiri).
  (AffirmationDeck, Affirmation)? _today(List<AffirmationDeck> decks) {
    final pool = [
      for (final d in decks)
        if (d.monsterId != null && (!d.isPremium || _premium))
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
    final showBack = !widget.embedded && Navigator.canPop(context);
    final today = decks == null ? null : _today(decks);
    final ready = decks ?? const <AffirmationDeck>[];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RiungStateView(
          status: RiungStateView.statusOf(loading: decks == null, error: _error),
          onRetry: _load,
          builder: (context) => RiungBleedListView(
                bleed: 0,
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl + MediaQuery.paddingOf(context).bottom),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showBack) ...[
                        RiungGlassIconButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        child: Text(
                          t.title,
                          style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.2),
                        ),
                      ),
                      RiungGlassIconButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AfirmasiPengingatScreen()),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RiungGlassIconButton(icon: Icons.add_rounded, onTap: _openBuat),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.subtitle,
                    style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.teksSekunder),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (today != null) ...[
                    AfirmasiTodayCard(
                      eyebrow: t.cardScreenTitle,
                      quote: t.textOf(today.$2),
                      meta: t.cards(today.$1.cards.length),
                      onTap: () => _openDeck(today.$1),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (ready.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Text(t.noDecks, textAlign: TextAlign.center, style: AppTextStyles.body),
                    )
                  else
                    for (var i = 0; i < ready.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _tile(ready[i])),
                              const SizedBox(width: 12),
                              Expanded(child: i + 1 < ready.length ? _tile(ready[i + 1]) : const SizedBox.shrink()),
                            ],
                          ),
                        ),
                      ),
                ],
              )),
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
      locked: deck.isPremium && !_premium,
      onTap: () => _openDeck(deck),
    );
  }
}
