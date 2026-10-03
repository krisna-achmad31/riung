import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
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
      backgroundColor: AppColors.latar,
      body: SafeArea(
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Row(
          children: [
            // Cuma tampil kalau layar ini di-push (mis. dari Profil §
            // "Brankas monster") — sebagai tab bawah (Navigator.canPop
            // == false) sudah ada RiungBottomNav, back di sini jadi ganda.
            if (Navigator.canPop(context)) ...[
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.vaultTitle, style: AppTextStyles.display.copyWith(fontSize: 22)),
                  Text(t.vaultSub(tamedCount), style: AppTextStyles.caption.copyWith(fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.kartu, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number, size: 15, color: AppColors.sekunder),
                  const SizedBox(width: 5),
                  Text('×${scope.wallet.tickets}', style: AppTextStyles.chipLabel.copyWith(color: AppColors.sekunder, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _HakimCard(
          saboteur: hakim,
          progress: hakimProgress,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HakimDetailScreen())),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(t.minions, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 15)),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.86,
          children: [
            for (final saboteur in anakBuah)
              _AccompliceCard(
                saboteur: saboteur,
                progress: scope.monsterProgress.progressOf(saboteur.id) ?? MonsterProgress.initial(saboteur.id),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SaboteurDetailScreen(saboteur: saboteur)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HakimCard extends StatelessWidget {
  const _HakimCard({required this.saboteur, required this.progress, required this.onTap});

  final Saboteur saboteur;
  final MonsterProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTamed = progress.state == MonsterState.tamed;
    final t = context.s.monster;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.monsterHakim.withValues(alpha: 0.18), AppColors.kartu.withValues(alpha: 0.9)]),
          border: Border.all(color: AppColors.monsterHakim, width: 1.5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 112,
              height: 118,
              child: RiungMonster(
                monsterId: 'hakim',
                state: isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar,
                size: 112,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(context.s.common.monsterName('hakim'), style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 17)),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(border: Border.all(color: AppColors.monsterHakim), borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Text(t.bossBadge, style: AppTextStyles.caption.copyWith(color: AppColors.monsterHakim, fontWeight: FontWeight.w700, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    t.hakimBlurb,
                    style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontSize: 12, height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: progress.progress / 100,
                      minHeight: 7,
                      backgroundColor: AppColors.latar,
                      valueColor: const AlwaysStoppedAnimation(AppColors.monsterHakim),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(t.progressToTamed(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccompliceCard extends StatelessWidget {
  const _AccompliceCard({required this.saboteur, required this.progress, required this.onTap});

  final Saboteur saboteur;
  final MonsterProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTamed = progress.state == MonsterState.tamed;
    final t = context.s.monster;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 78,
              height: 84,
              child: Opacity(
                opacity: isTamed ? 1 : 0.85,
                child: RiungMonster(
                  monsterId: saboteur.id,
                  state: isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar,
                  size: 78,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(context.s.common.monsterName(saboteur.id), style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 13)),
            const SizedBox(height: 3),
            Text(
              isTamed ? t.tamedBadge : t.progressToTamed(progress.progress),
              style: AppTextStyles.caption.copyWith(color: isTamed ? AppColors.sukses : AppColors.teksRedup, fontWeight: FontWeight.w600, fontSize: 10),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress.progress / 100,
                minHeight: 5,
                backgroundColor: AppColors.latar,
                valueColor: AlwaysStoppedAnimation(isTamed ? AppColors.sukses : (AppColors.monsterColors[saboteur.id] ?? AppColors.primer)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
