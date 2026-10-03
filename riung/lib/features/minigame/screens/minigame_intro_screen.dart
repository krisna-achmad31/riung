import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../monster/logic/waswas_level_config.dart';
import '../logic/minigame_config.dart';
import 'block_breaker_screen.dart';
import 'minigame_daily_cap_screen.dart';
import 'waswas_reaction_screen.dart';

/// Intro sebelum satu sesi serangan. Implement persis
/// `design/Monster.dc.html` § Intro serangan — mekanik "pecahkan balok"
/// diganti latihan napas berirama (lihat catatan di
/// `lib/features/minigame/screens/block_breaker_screen.dart`), tapi
/// struktur & reward layar ini tetap sama persis desain.
class MinigameIntroScreen extends StatelessWidget {
  const MinigameIntroScreen({super.key, required this.saboteur});

  final Saboteur saboteur;

  /// Level (unit ala Duolingo) Si Waswas untuk progres SAAT INI — dihitung
  /// ulang tiap kali layar ini dibangun, bukan disimpan, supaya selalu
  /// cocok dengan progres terbaru (termasuk saat "coba lagi" dari layar
  /// menang/kalah). `null` untuk saboteur lain (belum punya level).
  WaswasLevelDef? _waswasLevel(AppScope scope) {
    if (saboteur.id != 'waswas') return null;
    final progress = scope.monsterProgress.progressOf(saboteur.id)?.progress ?? 0;
    return waswasLevelForProgress(progress);
  }

  Future<void> _mulai(BuildContext context) async {
    final scope = AppScope.of(context);
    final berhasil = await scope.wallet.useTicket();
    if (!context.mounted) return;
    if (!berhasil) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MinigameDailyCapScreen()),
      );
      return;
    }
    final level = _waswasLevel(scope);
    // Si Waswas punya beberapa level (ala unit Duolingo): level awal masih
    // memakai Block Breaker (ditala makin cepat), level terakhir baru
    // memakai mekanik sendiri "Lepaskan Pikiran" — lihat waswas_level_config.dart.
    // Saboteur lain masih memakai Block Breaker biasa.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => level?.boss == WaswasBossType.reaction
            ? WaswasReactionScreen(saboteur: saboteur)
            : BlockBreakerScreen(saboteur: saboteur, startSpeedBonus: level?.boss.speedBonus ?? 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.minigame;
    final color = AppColors.monsterColors[saboteur.id] ?? AppColors.primer;
    final isReaction = _waswasLevel(scope)?.boss == WaswasBossType.reaction;

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: scope.wallet,
          builder: (context, _) {
            final bisaMulai = scope.wallet.tickets > 0 && !scope.wallet.dailyFightCapReached;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close, color: AppColors.teksRedup)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.kartu, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.confirmation_number, size: 14, color: AppColors.sekunder),
                            const SizedBox(width: 6),
                            Text('×${scope.wallet.tickets}', style: AppTextStyles.chipLabel.copyWith(color: AppColors.sekunder, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 158,
                          child: RiungMonster(monsterId: saboteur.id, state: MonsterVisualState.liar, size: 150),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          saboteur.isBoss ? t.introKickerBoss : t.introKicker(isReaction),
                          style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: 1.4, fontSize: 10),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(t.introTitle(saboteur.nama), textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 23)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          t.introBody(MinigameConfig.sessionSeconds, isReaction),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.6),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatChip(icon: Icons.bolt, color: color, value: '-${EconomyEarn.minigameWinProgressPercent}%', label: t.chipStrength),
                            const SizedBox(width: AppSpacing.sm),
                            _StatChip(icon: Icons.monetization_on, color: AppColors.aksenHangat, value: '+${EconomyEarn.menangGame}', label: t.chipCoinsIfWin),
                            const SizedBox(width: AppSpacing.sm),
                            _StatChip(icon: Icons.confirmation_number, color: AppColors.sekunder, value: t.chipOneTicket, label: t.chipPerAttack),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        RiungOwlTip(message: t.owlTip(saboteur.id)),
                      ],
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
                          onPressed: bisaMulai ? () => _mulai(context) : () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const MinigameDailyCapScreen()),
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: AppColors.latar,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                          ),
                          icon: const Icon(Icons.bolt, size: 17),
                          label: Text(t.startAttack, style: AppTextStyles.chipLabel.copyWith(color: AppColors.latar, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.introRules(EconomyTiket.maxDariLatihanPerHari, EconomyTiket.maxFightPerHari),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.introEthic,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: color)),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}
