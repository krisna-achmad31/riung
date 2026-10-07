import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../betterme/data/betterme_content.dart';
import '../../betterme/screens/betterme_home_screen.dart';
import '../../betterme/screens/level_intro_screen.dart';
import '../../minigame/screens/minigame_intro_screen.dart';
import '../../toko/logic/monster_loadout.dart';
import '../../toko/screens/lemari_screen.dart';
import '../logic/saboteur_content.dart';
import 'waswas_stage_map_screen.dart';

/// Detail satu saboteur (bukan bos). Implement persis
/// `design/Monster.dc.html` § Detail — Si Waswas.
///
/// Tombol "Serang" tidak ada di mockup desain (yang hanya menggambar
/// contoh Si Waswas dengan satu CTA "Latihan yang dia takuti"), tapi
/// ditambahkan di sini supaya mini-game bisa dipicu dari monster mana pun
/// yang sedang aktif dijinakkan — bukan cuma dari Si Hakim — sesuai
/// `docs/riung-cara-kerja-lengkap.md` §5 ("serangan ke monster aktif").
class SaboteurDetailScreen extends StatefulWidget {
  const SaboteurDetailScreen({super.key, required this.saboteur});

  final Saboteur saboteur;

  @override
  State<SaboteurDetailScreen> createState() => _SaboteurDetailScreenState();
}

class _SaboteurDetailScreenState extends State<SaboteurDetailScreen> {
  /// Pratinjau wujud di hero (toggle Liar/Jinak) — null = ikuti progres.
  MonsterVisualState? _preview;

  Saboteur get saboteur => widget.saboteur;

  /// Si Hakim → langsung ke Level 1 ("Kenalan sama Si Hakim", lihat
  /// `betterme_content.dart`) karena judulnya cocok persis dengan monster
  /// ini. Saboteur lain belum punya level Better me yang didedikasikan
  /// khusus untuknya, jadi cukup ke home Better me.
  void _bukaLatihanCbt(BuildContext context) {
    if (saboteur.id == 'hakim') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LevelIntroScreen(level: betterMeLevels.first)));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BetterMeHomeScreen()));
    }
  }

  void _serang(BuildContext context) {
    // Si Waswas punya peta latihan (uji coba per-monster, lihat
    // WaswasStageMapScreen); saboteur lain langsung ke intro serangan.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => saboteur.id == 'waswas' ? WaswasStageMapScreen(saboteur: saboteur) : MinigameIntroScreen(saboteur: saboteur),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.monster;
    final content = saboteurContentFor(saboteur.id, t);
    final tint = AppColors.monsterLembut[saboteur.id] ?? AppColors.aksenHangatLembut;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([scope.monsterProgress, scope.wallet, scope.prefs.monsterCosmeticsRevision]),
          builder: (context, _) {
            final progress = scope.monsterProgress.progressOf(saboteur.id) ?? MonsterProgress.initial(saboteur.id);
            final isTamed = progress.state == MonsterState.tamed;
            final shown = _preview ?? (isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar);
            final worn = shown == MonsterVisualState.jinak ? MonsterLoadout(scope.prefs).idsOf(saboteur.id, scope.wallet.ownedCosmetics) : const <String>[];

            return Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
              child: Column(
                children: [
                  RiungGlassHeader(
                    title: '',
                    trailing: isTamed
                        ? RiungGlassIconButton(
                            icon: Icons.checkroom_rounded,
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LemariScreen(monsterId: saboteur.id))),
                          )
                        : null,
                  ),
                  Expanded(
                    child: RiungBleedListView(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tint, Color.lerp(tint, AppColors.aksenHangat, 0.15)!]),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                            boxShadow: AppGlass.shadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 200,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 180,
                                      height: 190,
                                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                                    ),
                                    RiungMonster(monsterId: saboteur.id, state: shown, size: 180, applyBossScale: false, cosmetics: worn),
                                    Positioned(
                                      left: 0,
                                      top: 12,
                                      child: _StateToggle(
                                        value: shown,
                                        wildLabel: t.wild,
                                        tamedLabel: t.tamed,
                                        onChanged: (v) => setState(() => _preview = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(context.s.common.monsterName(saboteur.id), style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
                              if (saboteur.distorsiCbt.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                                  child: Text(saboteur.distorsiCbt, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.aksenHangatGelap)),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(t.saboteurDescription(saboteur.id, saboteur.deskripsi), style: AppTextStyles.caption.copyWith(fontSize: 13, height: 1.45, color: AppColors.teksSekunder)),
                              const SizedBox(height: 10),
                              Container(
                                height: 8,
                                decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(4)),
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  heightFactor: 1,
                                  widthFactor: (progress.progress / 100).clamp(0.0, 1.0),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.emas, AppColors.aksenHangat]), borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(isTamed ? t.tamedBadge : t.progressToTamed(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                            ],
                          ),
                        ),
                        if (content != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _InfoCard(eyebrow: t.realWorld, child: _body(content.duniaNyata)),
                          const SizedBox(height: AppSpacing.md),
                          _InfoCard(
                            eyebrow: t.whatItSays,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(color: AppColors.aksenHangat, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: _body('"${content.apaKatanya}"')),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _InfoCard(eyebrow: t.theFact, eyebrowColor: AppColors.sekunder, color: AppColors.sekunderLembut.withValues(alpha: 0.7), child: _body(content.faktanya)),
                          const SizedBox(height: AppSpacing.md),
                          _InfoCard(
                            eyebrow: t.antidotes,
                            eyebrowColor: AppColors.primer,
                            color: AppColors.kabutSage.withValues(alpha: 0.7),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final teknik in content.techniques) _TeknikRow(teknik: teknik),
                                Text(t.antidoteNote, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primer)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(child: RiungButton(label: t.cbtPractice, variant: RiungButtonVariant.secondary, onPressed: () => _bukaLatihanCbt(context))),
                      const SizedBox(width: 10),
                      Expanded(child: RiungButton(label: t.attack, onPressed: () => _serang(context))),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _body(String text) => Text(text, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.teksUtama));
}

/// Toggle pil Liar/Jinak untuk pratinjau wujud (frame `Toggle state`).
class _StateToggle extends StatelessWidget {
  const _StateToggle({required this.value, required this.wildLabel, required this.tamedLabel, required this.onChanged});

  final MonsterVisualState value;
  final String wildLabel;
  final String tamedLabel;
  final ValueChanged<MonsterVisualState> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(MonsterVisualState v, String label) {
      final on = v == value;
      return GestureDetector(
        onTap: () => onChanged(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: on ? AppColors.tinta : AppColors.tinta.withValues(alpha: 0), borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: on ? AppColors.diAtasTinta : AppColors.teksSekunder)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: AppGlass.pill(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg(MonsterVisualState.liar, wildLabel), seg(MonsterVisualState.jinak, tamedLabel)],
      ),
    );
  }
}

/// Kartu info kaca dengan eyebrow (DI DUNIA NYATA / FAKTANYA / …).
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.eyebrow, required this.child, this.eyebrowColor = AppColors.teksRedup, this.color = AppColors.kartu});

  final String eyebrow;
  final Widget child;
  final Color eyebrowColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      radius: 24,
      color: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: eyebrowColor)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TeknikRow extends StatelessWidget {
  const _TeknikRow({required this.teknik});

  final SaboteurTechnique teknik;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(11)),
            child: Icon(teknik.icon, size: 17, color: AppColors.primer),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(teknik.label, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.teksUtama))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text('${teknik.multiplier}×', style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primer)),
          ),
        ],
      ),
    );
  }
}
