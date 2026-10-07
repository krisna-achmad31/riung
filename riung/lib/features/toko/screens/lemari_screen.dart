import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/monster_loadout.dart';
import '../logic/toko_data.dart';
import '../widgets/kosmetik_preview_sheet.dart';
import '../widgets/lemari_item_card.dart';
import '../widgets/lemari_stage.dart';

/// Lemari monster (frame `Glass — Lemari Si Kabut`): panggung monster yang
/// memakai pilihan kosmetik, tab slot, kartu item, simpan. Kosmetik murni
/// tampilan — tidak menyentuh progres (CLAUDE.md garis etis).
class LemariScreen extends StatefulWidget {
  const LemariScreen({super.key, required this.monsterId});

  final String monsterId;

  @override
  State<LemariScreen> createState() => _LemariScreenState();
}

class _LemariScreenState extends State<LemariScreen> {
  static const _tabs = [null, CosmeticSlot.head, CosmeticSlot.neck, CosmeticSlot.base];

  late Map<CosmeticSlot, TokoCosmetic> _draft;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final scope = AppScope.of(context);
    _draft = {for (final c in MonsterLoadout(scope.prefs).of(widget.monsterId, scope.wallet.ownedCosmetics)) c.slot: c};
  }

  void _toggle(TokoCosmetic c) {
    setState(() {
      if (_draft[c.slot]?.id == c.id) {
        _draft.remove(c.slot);
      } else {
        _draft[c.slot] = c;
      }
    });
  }

  Future<void> _simpan() async {
    final scope = AppScope.of(context);
    await MonsterLoadout(scope.prefs).save(widget.monsterId, _draft.values);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.toko.styleSaved)));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.toko;
    final nama = context.s.common.monsterName(widget.monsterId);
    final slot = _tabs[_tab];
    final items = [
      for (final c in tokoCosmetics)
        if (c.listedFor(widget.monsterId) && (slot == null || c.slot == slot)) c,
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: ListenableBuilder(
            listenable: scope.wallet,
            builder: (context, _) {
              final owned = scope.wallet.ownedCosmetics;
              return Column(
                children: [
                  RiungGlassHeader(title: t.lemariTitle(nama), trailing: KoinChip(balance: scope.wallet.coins)),
                  Expanded(
                    child: RiungBleedListView(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                      children: [
                        LemariStage(monsterId: widget.monsterId, worn: _draft.values.toList()),
                        const SizedBox(height: AppSpacing.md),
                        RiungSegmentedTabs(
                          labels: [for (final s in _tabs) s == null ? t.slotAll : s.label(t)],
                          index: _tab,
                          onChanged: (i) => setState(() => _tab = i),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 12,
                          childAspectRatio: 169 / 181,
                          children: [
                            for (final c in items)
                              LemariItemCard(
                                cosmetic: c,
                                owned: owned.contains(c.id),
                                wearable: c.wearableBy(widget.monsterId),
                                worn: _draft[c.slot]?.id == c.id,
                                onTap: () {
                                  if (!c.wearableBy(widget.monsterId)) return;
                                  if (owned.contains(c.id)) {
                                    _toggle(c);
                                  } else {
                                    showKosmetikPreviewSheet(context, cosmetic: c);
                                  }
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: AppColors.primerLembut.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.primer),
                              const SizedBox(width: 10),
                              Expanded(child: Text(t.lemariNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.primer))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RiungButton(label: t.applyStyle, onPressed: _simpan),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
