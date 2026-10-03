import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/affirmation_deck.dart';
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
  late final PageController _controller = PageController();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.afirmasi;
    final cards = widget.deck.cards;
    final monsterId = widget.deck.monsterId ?? 'cermin';
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
                  Expanded(child: Text(t.cardScreenTitle, textAlign: TextAlign.center, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama))),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final card in cards)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A2461), Color(0xFF161A45)]),
                            border: Border.all(color: const Color(0xFF3A3580)),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 76, height: 80, child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 76)),
                              const SizedBox(height: AppSpacing.md),
                              Text('"${t.textOf(card)}"', textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 21, height: 1.45)),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                widget.deck.monsterId == null ? t.cardLabelCustom : t.cardLabelMonster(context.s.common.monsterName(widget.deck.monsterId!)),
                                style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.monsterCermin, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < cards.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: i == _index ? AppColors.monsterCermin : AppColors.garis),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (cards.isNotEmpty)
              Text(t.swipeHint(_index + 1, cards.length), style: AppTextStyles.caption.copyWith(fontSize: 12)),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: cards.isEmpty ? null : () => _toggleFavorite(cards[_index].id),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.garis, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                        icon: Icon(
                          cards.isNotEmpty && _favorites.contains(cards[_index].id) ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: AppColors.teksSekunder,
                        ),
                        label: Text(t.favorite, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: cards.isEmpty
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => AfirmasiBagikanScreen(card: cards[_index], monsterId: monsterId)),
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.monsterCermin,
                          foregroundColor: AppColors.latar,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                        icon: const Icon(Icons.ios_share, size: 16),
                        label: Text(t.share, style: AppTextStyles.chipLabel.copyWith(color: AppColors.latar, fontSize: 14)),
                      ),
                    ),
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
