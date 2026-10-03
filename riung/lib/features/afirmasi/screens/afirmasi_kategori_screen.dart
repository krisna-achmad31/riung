import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/affirmation_deck.dart';
import 'afirmasi_buat_screen.dart';
import 'afirmasi_kartu_screen.dart';
import 'afirmasi_pengingat_screen.dart';

/// Koleksi deck afirmasi. Implement persis `design/Afirmasi.dc.html`
/// § Koleksi afirmasi.
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

  @override
  Widget build(BuildContext context) {
    final decks = _decks;
    final t = context.s.afirmasi;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: decks == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title, style: AppTextStyles.display),
                            Text(t.subtitle, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AfirmasiPengingatScreen())),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: AppColors.kartu, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(13)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.notifications_outlined, size: 19, color: AppColors.teksSekunder),
                        ),
                      ),
                      GestureDetector(
                        onTap: _openBuat,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppColors.kartu, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(13)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.add, size: 19, color: AppColors.teksSekunder),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (decks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Text(t.noDecks, textAlign: TextAlign.center, style: AppTextStyles.body),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.95,
                      children: [
                        for (final deck in decks)
                          _DeckCard(
                            deck: deck,
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AfirmasiKartuScreen(deck: deck))),
                          ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.deck, required this.onTap});

  final AffirmationDeck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.afirmasi;
    final monsterId = deck.monsterId;
    final title = monsterId == null ? t.customDeck : t.deckAgainst(context.s.common.monsterName(monsterId));
    final color = monsterId == null ? AppColors.primer : (AppColors.monsterColors[monsterId] ?? AppColors.primer);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.xxl)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (monsterId != null)
              SizedBox(width: 46, height: 48, child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 46))
            else
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Icon(Icons.auto_awesome, size: 21, color: color),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14)),
            const SizedBox(height: 4),
            Text(t.cards(deck.cards.length), style: AppTextStyles.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
