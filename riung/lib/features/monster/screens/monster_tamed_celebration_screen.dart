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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    clipBehavior: Clip.none,
                    // Kartu yang dibagikan = area ini (latar kabut ikut terekam).
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: AppGlass.backdrop, borderRadius: BorderRadius.circular(32)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.primerLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                                child: Text(t.monsterNumberTamed(tamedCount), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.primer)),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _TamedStage(monsterId: saboteur.id),
                              const SizedBox(height: AppSpacing.sm),
                              Text(t.friendNow(monsterName), textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                              const SizedBox(height: AppSpacing.sm),
                              Text(t.celebrationBody, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5, color: AppColors.teksSekunder)),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                children: [
                                  Expanded(
                                    child: RiungStatTile(leading: const RiungIcon3D(RiungIcon.koin, size: 40), value: '+${EconomyEarn.monsterJinak}', label: t.bonusCoins),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RiungStatTile(
                                      leading: RiungMonster(monsterId: saboteur.id, state: MonsterVisualState.jinak, size: 40, applyBossScale: false),
                                      value: '$tamedCount/7',
                                      label: t.tamedLabel,
                                    ),
                                  ),
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
              const SizedBox(height: AppSpacing.md),
              RiungButton(
                label: t.shareAchievement,
                icon: Icons.ios_share_rounded,
                onPressed: _busy ? null : () => _bagikan(t.shareCaption(monsterName, tamedCount)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(t.shareNote, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(context.s.common.lanjut, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panggung perayaan (frame `Perayaan`): cincin tipis, aura, monster jinak
/// 3D besar, kilau emas.
class _TamedStage extends StatelessWidget {
  const _TamedStage({required this.monsterId});

  final String monsterId;

  @override
  Widget build(BuildContext context) {
    Widget spark(double l, double tp, double size) => Positioned(left: l, top: tp, child: Icon(Icons.auto_awesome, size: size, color: AppColors.emas));
    return SizedBox(
      width: 320,
      height: 300,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 10,
            child: Container(width: 280, height: 280, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.garis, width: 1.5))),
          ),
          Positioned(
            left: 40,
            top: 30,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
            ),
          ),
          Positioned(left: 50, top: 40, child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 220, applyBossScale: false)),
          spark(20, 40, 24),
          spark(280, 30, 18),
          spark(290, 200, 22),
          spark(10, 220, 16),
          spark(150, 0, 14),
        ],
      ),
    );
  }
}
