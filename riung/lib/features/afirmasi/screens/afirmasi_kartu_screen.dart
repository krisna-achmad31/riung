import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/models/affirmation.dart';
import '../logic/affirmation_deck.dart';
import '../widgets/afirmasi_card_stack.dart';
import '../widgets/afirmasi_glass_card.dart';
import 'afirmasi_bagikan_screen.dart';

/// Kartu afirmasi yang bisa digeser + simpan/bagikan. Implement persis
/// `design/Afirmasi.dc.html` § Kartu afirmasi harian.
class AfirmasiKartuScreen extends StatefulWidget {
  const AfirmasiKartuScreen({super.key, required this.deck});

  final AffirmationDeck deck;

  @override
  State<AfirmasiKartuScreen> createState() => _AfirmasiKartuScreenState();
}

class _AfirmasiKartuScreenState extends State<AfirmasiKartuScreen> {
  int _index = 0;
  Set<String> _favorites = const {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.profile?.uid;
    if (uid == null) return;
    final favorites = await scope.userRepository.getFavoriteAffirmationIds(uid);
    if (!mounted) return;
    setState(() => _favorites = favorites);
  }

  Future<void> _toggleFavorite(String affirmationId) async {
    final scope = AppScope.of(context);
    final uid = scope.auth.profile?.uid;
    if (uid == null) return;
    final updated = {..._favorites};
    if (!updated.add(affirmationId)) updated.remove(affirmationId);
    setState(() => _favorites = updated);
    await scope.userRepository.setFavoriteAffirmationIds(uid, updated);
  }

  void _bagikan(List<Affirmation> cards, String monsterId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AfirmasiBagikanScreen(card: cards[_index], monsterId: monsterId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.afirmasi;
    final cards = widget.deck.cards;
    final monsterId = widget.deck.monsterId ?? 'cermin';
    final tag = widget.deck.monsterId == null ? t.cardLabelCustom : t.cardLabelMonster(context.s.common.monsterName(widget.deck.monsterId!));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: RiungGlassHeader(title: t.cardScreenTitle),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl + 15),
                    child: AfirmasiCardStack(
                      itemCount: cards.length,
                      index: _index,
                      onSwiped: (i) => setState(() => _index = i),
                      colorOf: (i) => AfirmasiTone.forCard(i, cards.length).base,
                      cardBuilder: (context, i) => AfirmasiGlassCard(
                        tag: tag,
                        monsterId: monsterId,
                        text: t.textOf(cards[i]),
                        tone: AfirmasiTone.forCard(i, cards.length),
                        footer: cards.length < 2
                            ? null
                            : Text(t.swipeHint(i + 1, cards.length), textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: RiungButton(
                        label: t.share,
                        variant: RiungButtonVariant.secondary,
                        onPressed: cards.isEmpty ? null : () => _bagikan(cards, monsterId),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RiungButton(
                        label: t.favorite,
                        onPressed: cards.isEmpty ? null : () => _toggleFavorite(cards[_index].id),
                        icon: cards.isNotEmpty && _favorites.contains(cards[_index].id) ? Icons.favorite_rounded : null,
                      ),
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
}
