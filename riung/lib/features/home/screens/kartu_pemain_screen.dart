import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/services/card_image_exporter.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Kartu pemain — ringkasan progres yang bisa dibagikan tanpa membocorkan
/// isi jurnal. Implement persis `design/Home.dc.html` § Kartu pemain.
class KartuPemainScreen extends StatefulWidget {
  const KartuPemainScreen({super.key});

  @override
  State<KartuPemainScreen> createState() => _KartuPemainScreenState();
}

class _KartuPemainScreenState extends State<KartuPemainScreen> {
  String _caption(AppScope scope) {
    final tamed = scope.monsterProgress.all.values.where((m) => m.state == MonsterState.tamed).length;
    return context.s.home.shareCaption(
      scope.auth.profile?.displayName ?? context.s.home.defaultUserName,
      scope.streak.current,
      tamed,
    );
  }

  int? _journalCount;
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadJournalCount();
  }

  Future<void> _loadJournalCount() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.uid;
    if (uid == null) return;
    final entries = await scope.userRepository.getJournalEntries(uid);
    if (!mounted) return;
    setState(() => _journalCount = entries.length);
  }

  Future<void> _simpan() async {
    if (_busy) return;
    setState(() => _busy = true);
    final t = context.s.home;
    try {
      final bytes = await CardImageExporter.capture(_cardKey);
      if (bytes == null) throw Exception('render gagal');
      await CardImageExporter.saveToGallery(bytes, namePrefix: 'riung_kartu_pemain');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cardSaved)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cardSaveFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bagikan(String caption) async {
    if (_busy) return;
    setState(() => _busy = true);
    final t = context.s.home;
    try {
      final bytes = await CardImageExporter.capture(_cardKey);
      if (bytes == null) throw Exception('render gagal');
      await CardImageExporter.share(bytes, namePrefix: 'riung_kartu_pemain', text: caption);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.cardShareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.home;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(title: t.playerCardTitle),
              Expanded(
                child: ListenableBuilder(
                  listenable: Listenable.merge([scope.auth, scope.streak, scope.monsterProgress]),
                  builder: (context, _) {
                    final profile = scope.auth.profile;
                    final userName = profile?.displayName ?? t.defaultUserName;
                    final tamed = [
                      for (final e in scope.monsterProgress.all.entries)
                        if (e.value.state == MonsterState.tamed && e.key != 'hakim') e.key,
                    ];
                    final dominant = (profile != null && profile.dominantSaboteurs.isNotEmpty) ? profile.dominantSaboteurs.first : 'waswas';
                    return RiungBleedListView(
                      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
                      children: [
                        RepaintBoundary(
                          key: _cardKey,
                          child: _PlayerCard(
                            userName: userName,
                            streak: scope.streak.current,
                            journalCount: _journalCount,
                            tamedCount: tamed.length,
                            dominantId: dominant,
                            companions: tamed.where((id) => id != dominant).take(2).toList(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(t.shareNote, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: RiungButton(label: t.saveImage, variant: RiungButtonVariant.secondary, onPressed: _busy ? null : _simpan)),
                  const SizedBox(width: 10),
                  Expanded(child: RiungButton(label: t.share, onPressed: _busy ? null : () => _bagikan(_caption(scope)))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu pemain (frame `Kartu`): gradien sage→lavender, logo + pangkat,
/// panggung monster 3D, nama, empat statistik kaca.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.userName,
    required this.streak,
    required this.journalCount,
    required this.tamedCount,
    required this.dominantId,
    required this.companions,
  });

  final String userName;
  final int streak;
  final int? journalCount;
  final int tamedCount;
  final String dominantId;
  final List<String> companions;

  @override
  Widget build(BuildContext context) {
    final t = context.s.home;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.kabutSage, AppColors.kabutLavender]),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: AppColors.garis, width: 2),
        boxShadow: AppGlass.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.kabutSage, AppColors.sekunder])),
              ),
              const SizedBox(width: 6),
              Text('Riung', style: AppTextStyles.title.copyWith(fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(t.playerRank, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.primer)),
              ),
            ],
          ),
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
                ),
                if (companions.isNotEmpty)
                  Positioned(left: 4, bottom: 10, child: RiungMonster(monsterId: companions[0], state: MonsterVisualState.jinak, size: 104, applyBossScale: false)),
                if (companions.length > 1)
                  Positioned(right: 4, bottom: 12, child: RiungMonster(monsterId: companions[1], state: MonsterVisualState.jinak, size: 100, applyBossScale: false)),
                RiungMonster(monsterId: dominantId, state: MonsterVisualState.jinak, size: 150, applyBossScale: false),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(userName, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCell(value: '$streak', label: t.statStreak)),
              const SizedBox(width: 10),
              Expanded(child: _StatCell(value: journalCount == null ? '…' : '$journalCount', label: t.statJournal)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _StatCell(value: '$tamedCount', label: t.statTamed)),
              const SizedBox(width: 10),
              Expanded(child: _StatCell(value: '$tamedCount/7', label: t.statProgress)),
            ],
          ),
          const SizedBox(height: 12),
          Text(t.tamedOf(tamedCount), style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(color: AppColors.permukaan.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.title.copyWith(fontSize: 22, height: 1.15)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}
