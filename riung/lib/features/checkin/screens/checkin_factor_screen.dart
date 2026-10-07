import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/checkin_draft.dart';
import '../logic/checkin_options.dart';
import '../widgets/checkin_step_header.dart';
import 'checkin_note_screen.dart';

/// Langkah 2/3 — pilih maksimal 3 faktor. Implement persis
/// `design/Checkin.dc.html` § Pilih faktor.
class CheckInFactorScreen extends StatefulWidget {
  const CheckInFactorScreen({super.key, required this.draft});

  final CheckInDraft draft;

  @override
  State<CheckInFactorScreen> createState() => _CheckInFactorScreenState();
}

class _CheckInFactorScreenState extends State<CheckInFactorScreen> {
  static const _maxFactors = 3;

  void _toggle(String id) {
    setState(() {
      if (widget.draft.factorIds.contains(id)) {
        widget.draft.factorIds.remove(id);
      } else if (widget.draft.factorIds.length < _maxFactors) {
        widget.draft.factorIds.add(id);
      }
    });
  }

  void _lanjut() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CheckInNoteScreen(draft: widget.draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.checkin;
    final showHakimInsight =
        widget.draft.factorIds.contains('kerjaan') && widget.draft.factorIds.contains('takut_gagal');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CheckInStepHeader(step: 2, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
                children: [
                  Text(t.factorTitle, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.15)),
                  const SizedBox(height: 6),
                  Text(t.factorSub, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                  const SizedBox(height: AppSpacing.lg),
                  for (var i = 0; i < checkInFactors.length; i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Row(
                        children: [
                          Expanded(child: _tile(checkInFactors[i])),
                          if (i + 1 < checkInFactors.length) ...[
                            const SizedBox(width: 10),
                            Expanded(child: _tile(checkInFactors[i + 1])),
                          ],
                        ],
                      ),
                    ),
                  if (showHakimInsight)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppGlass.card(radius: 22, color: AppColors.sekunderLembut.withValues(alpha: 0.7), shadowed: false),
                      child: Row(
                        children: [
                          const RiungMonster(monsterId: 'hakim', state: MonsterVisualState.jinak, size: 52, applyBossScale: false),
                          const SizedBox(width: 12),
                          Expanded(child: Text(t.hakimInsight, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksUtama))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: RiungButton(label: context.s.common.lanjut, onPressed: widget.draft.factorIds.isEmpty ? null : _lanjut),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(CheckInFactorOption factor) => _FactorTile(
        factor: factor,
        selected: widget.draft.factorIds.contains(factor.id),
        onTap: () => _toggle(factor.id),
      );
}

/// Ubin faktor (frame `Faktor …`): kotak ikon + label; terpilih = tepi primer.
class _FactorTile extends StatelessWidget {
  const _FactorTile({required this.factor, required this.selected, required this.onTap});

  final CheckInFactorOption factor;
  final bool selected;
  final VoidCallback onTap;

  /// Label 2 baris; satu kata panjang (mis. "Relationships") mengecil
  /// alih-alih dipatah di tengah kata.
  Widget _label(BuildContext context) {
    final text = context.s.checkin.factorLabel(factor.id);
    final style = AppTextStyles.chipLabel.copyWith(fontSize: 13, height: 1.2, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: AppColors.teksUtama);
    if (text.contains(' ')) return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: style);
    return FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(text, maxLines: 1, style: style));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.garis : AppColors.kartu,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: selected ? 2 : 1.5),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: selected ? AppColors.primer : AppColors.primerLembut, borderRadius: BorderRadius.circular(12)),
                child: Icon(factor.icon, size: 18, color: selected ? AppColors.diAtasTinta : AppColors.primer),
              ),
              const SizedBox(width: 10),
              Expanded(child: _label(context)),
            ],
          ),
        ),
      ),
    );
  }
}
