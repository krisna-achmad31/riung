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
    final isReaction = _waswasLevel(scope)?.boss == WaswasBossType.reaction;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: scope.wallet,
          builder: (context, _) {
            final bisaMulai = scope.wallet.tickets > 0 && !scope.wallet.dailyFightCapReached;
            return Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      RiungGlassIconButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).maybePop()),
                      const Spacer(),
                      TiketChip(count: scope.wallet.tickets),
                    ],
                  ),
                  Expanded(
                    child: RiungBleedListView(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.sekunderLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                            child: Text(
                              saboteur.isBoss ? t.introKickerBoss : t.introKicker(isReaction),
                              style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.sekunder),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 280,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                              ),
                              RiungMonster(monsterId: saboteur.id, state: MonsterVisualState.liar, size: 250, applyBossScale: false),
                            ],
                          ),
                        ),
                        Text(t.introTitle(saboteur.nama), textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.2)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          t.introBody(MinigameConfig.sessionSeconds, isReaction),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5, color: AppColors.teksSekunder),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: RiungValueChip(value: '−${EconomyEarn.minigameWinProgressPercent}%', label: t.chipStrength)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RiungValueChip(
                                  leading: const RiungIcon3D(RiungIcon.koin, size: 30),
                                  value: '+${EconomyEarn.menangGame}',
                                  label: t.chipCoinsIfWin,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RiungValueChip(leading: const RiungIcon3D(RiungIcon.tiket, size: 30), value: t.chipOneTicket, label: t.chipPerAttack),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        RiungOwlTip(message: t.owlTip(saboteur.id)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RiungButton(
                    label: t.startAttack,
                    onPressed: bisaMulai
                        ? () => _mulai(context)
                        : () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MinigameDailyCapScreen())),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.introRules(EconomyTiket.maxDariLatihanPerHari, EconomyTiket.maxFightPerHari),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder),
                  ),
                  const SizedBox(height: 2),
                  Text(t.introEthic, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4, color: AppColors.teksRedup)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
