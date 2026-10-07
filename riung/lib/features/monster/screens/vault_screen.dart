import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../betterme/screens/betterme_home_screen.dart';
import '../../minigame/screens/minigame_intro_screen.dart';
import 'hakim_detail_screen.dart';
import 'saboteur_detail_screen.dart';

/// Brankas monster — kartu besar Si Hakim (bos) + grid 6 anak buah.
/// Implement persis `design/Monster.dc.html` § Brankas monster.
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<Saboteur>? _saboteurs;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await AppScope.of(context).contentRepository.getSaboteurs();
      if (!mounted) return;
      setState(() => _saboteurs = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([scope.monsterProgress, scope.wallet]),
          builder: (context, _) => _buildBody(context, scope),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppScope scope) {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.teksRedup),
              const SizedBox(height: AppSpacing.md),
              Text(context.s.monster.loadError, textAlign: TextAlign.center, style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.md),
              RiungButton(label: context.s.common.cobaLagi, onPressed: () { setState(() => _loadError = null); _load(); }),
            ],
          ),
        ),
      );
    }

    final saboteurs = _saboteurs;
    if (saboteurs == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primer));
    }

    final t = context.s.monster;
    final hakim = saboteurs.firstWhere((s) => s.id == 'hakim', orElse: () => saboteurs.first);
    final anakBuah = saboteurs.where((s) => s.id != 'hakim').toList();
    final hakimProgress = scope.monsterProgress.progressOf('hakim') ?? MonsterProgress.initial('hakim');
    final tamedCount = scope.monsterProgress.all.values.where((m) => m.state == MonsterState.tamed).length;

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl + MediaQuery.paddingOf(context).bottom),
      children: [
        Row(
          children: [
            // Cuma tampil kalau layar ini di-push (mis. dari Profil) — sebagai
            // tab bawah sudah ada RiungBottomNav, back di sini jadi ganda.
            if (Navigator.canPop(context)) ...[
              RiungGlassIconButton(icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(t.vaultTitle, maxLines: 1, style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.2)),
                  ),
                  const SizedBox(height: 2),
                  Text(t.vaultSub(tamedCount), style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.teksSekunder)),
                ],
              ),
            ),
            TiketChip(count: scope.wallet.tickets),
            const SizedBox(width: 8),
            KoinChip(balance: scope.wallet.coins),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _HakimCard(
          saboteur: hakim,
          progress: hakimProgress,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HakimDetailScreen())),
          onAttack: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MinigameIntroScreen(saboteur: hakim))),
          onCbt: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BetterMeHomeScreen())),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(t.minions, style: AppTextStyles.title.copyWith(fontSize: 18)),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < anakBuah.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _minion(context, scope, anakBuah[i])),
                  const SizedBox(width: 12),
                  Expanded(child: i + 1 < anakBuah.length ? _minion(context, scope, anakBuah[i + 1]) : const SizedBox.shrink()),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _minion(BuildContext context, AppScope scope, Saboteur saboteur) => _AccompliceCard(
        saboteur: saboteur,
        progress: scope.monsterProgress.progressOf(saboteur.id) ?? MonsterProgress.initial(saboteur.id),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SaboteurDetailScreen(saboteur: saboteur))),
      );
}

/// Kartu bos Si Hakim (frame `Kartu Bos`): panggung lavender dengan Si
/// Hakim 3D besar, badge "BOS · n%", progres gradien, tombol Serang & CBT.
class _HakimCard extends StatelessWidget {
  const _HakimCard({required this.saboteur, required this.progress, required this.onTap, required this.onAttack, required this.onCbt});

  final Saboteur saboteur;
  final MonsterProgress progress;
  final VoidCallback onTap;
  final VoidCallback onAttack;
  final VoidCallback onCbt;

  @override
  Widget build(BuildContext context) {
    final isTamed = progress.state == MonsterState.tamed;
    final t = context.s.monster;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.sekunderLembut, AppColors.kabutLavender]),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
          boxShadow: AppGlass.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 230,
                    height: 200,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                  ),
                  RiungMonster(monsterId: 'hakim', state: isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar, size: 200, applyBossScale: false),
                  Positioned(
                    left: 0,
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.sekunder, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(t.bossPercent(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.diAtasTinta)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(context.s.common.monsterName('hakim'), style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.2)),
            const SizedBox(height: 6),
            Text(t.hakimBlurb, style: AppTextStyles.caption.copyWith(fontSize: 13, height: 1.45, color: AppColors.teksSekunder)),
            const SizedBox(height: 10),
            _GradientProgress(value: progress.progress / 100, colors: const [AppColors.kabutLavender, AppColors.sekunder]),
            const SizedBox(height: 8),
            Text(t.progressToTamed(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: RiungButton(label: t.attack, onPressed: onAttack)),
                const SizedBox(width: 10),
                Expanded(child: RiungButton(label: t.cbtPractice, variant: RiungButtonVariant.secondary, onPressed: onCbt)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientProgress extends StatelessWidget {
  const _GradientProgress({required this.value, required this.colors});

  final double value;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(3)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        heightFactor: 1,
        widthFactor: value.clamp(0.0, 1.0),
        child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(3))),
      ),
    );
  }
}

/// Kartu anak buah (frame `Kartu Si …`): panggung monster 3D + pil status,
/// nama, progres persik atau "Sekarang temanmu" bila sudah jinak.
class _AccompliceCard extends StatelessWidget {
  const _AccompliceCard({required this.saboteur, required this.progress, required this.onTap});

  final Saboteur saboteur;
  final MonsterProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTamed = progress.state == MonsterState.tamed;
    final t = context.s.monster;
    return RiungGlassCard(
      onTap: onTap,
      radius: 28,
      color: isTamed ? AppColors.permukaan : AppColors.kartu,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RiungMonster(monsterId: saboteur.id, state: isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar, size: 118, applyBossScale: false),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: isTamed ? AppColors.primer : AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text(
                      isTamed ? t.tamedBadge : t.wild,
                      style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: isTamed ? AppColors.diAtasTinta : AppColors.teksSekunder),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(context.s.common.monsterName(saboteur.id), style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
          const SizedBox(height: 6),
          if (isTamed)
            Text(t.friendShort, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primer))
          else ...[
            _GradientProgress(value: progress.progress / 100, colors: const [AppColors.aksenHangat, AppColors.aksenHangat]),
            const SizedBox(height: 6),
            Text(t.progressToTamed(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
          ],
        ],
      ),
    );
  }
}
