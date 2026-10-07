import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Menulis afirmasi sendiri, opsional ditandai melawan monster tertentu.
/// Alur & copy: `design/Afirmasi.dc.html` § Buat afirmasi; visual:
/// `Glass — Afirmasi · Buat` di `design/riung.pen`.
class AfirmasiBuatScreen extends StatefulWidget {
  const AfirmasiBuatScreen({super.key});

  @override
  State<AfirmasiBuatScreen> createState() => _AfirmasiBuatScreenState();
}

class _AfirmasiBuatScreenState extends State<AfirmasiBuatScreen> {
  final _controller = TextEditingController();
  String? _targetMonster;
  List<Saboteur> _saboteurs = const [];
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _loadSaboteurs();
  }

  Future<void> _loadSaboteurs() async {
    final saboteurs = await AppScope.of(context).contentRepository.getSaboteurs();
    if (!mounted) return;
    // Si Hakim (bos) sengaja tidak bisa ditag di sini — afirmasi custom
    // cuma boleh menargetkan 6 anak buah, bukan bos.
    setState(() => _saboteurs = saboteurs.where((s) => !s.isBoss).toList());
  }

  Future<void> _simpan() async {
    final teks = _controller.text.trim();
    if (teks.isEmpty) return;
    final scope = AppScope.of(context);
    final uid = scope.auth.profile?.uid;
    if (uid == null) return;
    await scope.userRepository.saveCustomAffirmation(
      uid,
      Affirmation(id: 'custom_${_uuid.v4()}', teks: teks, targetSaboteur: _targetMonster, isCustom: true),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _inspirasi = 0;

  void _isiInspirasi() {
    final list = context.s.afirmasi.inspirations;
    if (list.isEmpty) return;
    setState(() {
      _controller.text = list[_inspirasi % list.length];
      _inspirasi++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.afirmasi;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            children: [
              RiungGlassHeader(title: t.createTitle),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  children: [
                    Text(t.createIntro, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSpacing.lg),
                    _PreviewCard(controller: _controller, tag: t.cardLabelCustom, hint: t.createHint, onChanged: () => setState(() {})),
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.fightsAgainst, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                    const SizedBox(height: AppSpacing.md),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          for (final saboteur in _saboteurs)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _MonsterPick(
                                monsterId: saboteur.id,
                                label: context.s.common.monsterName(saboteur.id),
                                selected: _targetMonster == saboteur.id,
                                onTap: () => setState(() => _targetMonster = _targetMonster == saboteur.id ? null : saboteur.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    GestureDetector(
                      onTap: _isiInspirasi,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.sekunder),
                          const SizedBox(width: 8),
                          Text(t.needInspiration, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.sekunder)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RiungButton(label: t.saveToCollection, onPressed: _controller.text.trim().isEmpty ? null : _simpan),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu pratinjau tempat kalimat diketik langsung (frame `Kartu pratinjau`).
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.controller, required this.tag, required this.hint, required this.onChanged});

  final TextEditingController controller;
  final String tag;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.display.copyWith(fontSize: 24, height: 1.2, color: AppColors.teksUtama);
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.garis, AppColors.kabutSage]),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
        boxShadow: AppGlass.shadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primerLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(tag, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.primer)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: null,
            autofocus: true,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged(),
            style: style,
            cursorColor: AppColors.primer,
            decoration: InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: hint,
              hintStyle: style.copyWith(color: AppColors.teksRedup),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ubin pilih monster 52×54 (frame `Monster n` di `Pilih monster`).
class _MonsterPick extends StatelessWidget {
  const _MonsterPick({required this.monsterId, required this.label, required this.selected, required this.onTap});

  final String monsterId;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 52,
          height: 54,
          decoration: BoxDecoration(
            color: selected ? AppColors.garis : AppColors.kartu,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: selected ? 2 : 1),
          ),
          alignment: Alignment.center,
          child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 44, applyBossScale: false),
        ),
      ),
    );
  }
}
