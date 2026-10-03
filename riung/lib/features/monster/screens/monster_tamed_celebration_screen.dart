import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/services/card_image_exporter.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Perayaan saat satu monster mencapai 100% jinak. Implement persis
/// `design/Monster.dc.html` § Monster jinak — perayaan.
class MonsterTamedCelebrationScreen extends StatefulWidget {
  const MonsterTamedCelebrationScreen({super.key, required this.saboteur});

  final Saboteur saboteur;

  @override
  State<MonsterTamedCelebrationScreen> createState() => _MonsterTamedCelebrationScreenState();
}

class _MonsterTamedCelebrationScreenState extends State<MonsterTamedCelebrationScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  Saboteur get saboteur => widget.saboteur;

  /// Bagikan kartu perayaan (monster + judul + teks) sebagai gambar — yang
  /// terbagikan persis yang terlihat di layar, tanpa isi jurnal/data pribadi.
  Future<void> _bagikan(String caption) async {
    if (_busy) return;
    setState(() => _busy = true);
    final failed = context.s.monster.cardShareFailed;
    try {
      final bytes = await CardImageExporter.capture(_cardKey);
      if (bytes == null) throw Exception('render gagal');
      await CardImageExporter.share(bytes, namePrefix: 'riung_monster_jinak', text: caption);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.monster;
    final tamedCount = scope.monsterProgress.all.values.where((m) => m.state == MonsterState.tamed).length;
    final monsterName = context.s.common.monsterName(saboteur.id);

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Center(
                  child: SingleChildScrollView(
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: Container(
                        color: AppColors.latar,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✨ 🎉 ✨', style: AppTextStyles.title.copyWith(letterSpacing: 6, fontSize: 22)),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: 170,
                      height: 179,
                      child: RiungMonster(monsterId: saboteur.id, state: MonsterVisualState.jinak, size: 170),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      t.monsterNumberTamed(tamedCount),
                      style: AppTextStyles.caption.copyWith(color: AppColors.aksenHangat, fontWeight: FontWeight.w700, letterSpacing: 1.4, fontSize: 10),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.friendNow(monsterName),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.celebrationBody,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.55),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatChip(icon: Icons.monetization_on, color: AppColors.aksenHangat, value: '+${EconomyEarn.monsterJinak}', label: t.bonusCoins),
                        const SizedBox(width: AppSpacing.sm),
                        _StatChip(icon: Icons.pest_control, color: AppColors.sekunder, value: '$tamedCount/7', label: t.tamedLabel),
                      ],
                    ),
                  ],
                ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
              child: Column(
                children: [
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : () => _bagikan(t.shareCaption(monsterName, tamedCount)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.aksenHangat,
                        foregroundColor: AppColors.latar,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      ),
                      icon: const Icon(Icons.ios_share, size: 17),
                      label: Text(t.shareAchievement, style: AppTextStyles.chipLabel.copyWith(color: AppColors.latar, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.shareNote,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text(context.s.common.lanjut, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.chipLabel.copyWith(fontSize: 16, color: color)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
