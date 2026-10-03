import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Menulis afirmasi sendiri, opsional ditandai melawan monster tertentu.
/// Implement persis `design/Afirmasi.dc.html` § Buat afirmasi.
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

  @override
  Widget build(BuildContext context) {
    final t = context.s.afirmasi;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close, color: AppColors.teksSekunder)),
                  Text(t.createTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  Text(
                    t.createIntro,
                    style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.55),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    constraints: const BoxConstraints(minHeight: 110),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.primer, width: 1.5), borderRadius: BorderRadius.circular(AppRadius.xxl)),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.body.copyWith(fontSize: 16, color: AppColors.teksUtama, height: 1.6),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: t.createHint,
                        hintStyle: AppTextStyles.body.copyWith(fontSize: 16, color: AppColors.teksRedup),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.fightsAgainst, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final saboteur in _saboteurs)
                        GestureDetector(
                          onTap: () => setState(() => _targetMonster = _targetMonster == saboteur.id ? null : saboteur.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: _targetMonster == saboteur.id ? (AppColors.monsterColors[saboteur.id] ?? AppColors.primer) : AppColors.garis, width: 1.5),
                              color: _targetMonster == saboteur.id ? (AppColors.monsterColors[saboteur.id] ?? AppColors.primer).withValues(alpha: 0.12) : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 17, height: 18, child: RiungMonster(monsterId: saboteur.id, state: MonsterVisualState.liar, size: 17)),
                                const SizedBox(width: 6),
                                Text(context.s.common.monsterName(saboteur.id), style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teksSekunder)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(t.needInspiration, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
                  const SizedBox(height: AppSpacing.sm),
                  for (final teks in t.inspirations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => setState(() => _controller.text = teks),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(14)),
                          child: Text('"$teks"', style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: RiungButton(
                label: t.saveToCollection,
                onPressed: _controller.text.trim().isEmpty ? null : _simpan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
