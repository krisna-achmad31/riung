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
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder),
                  ),
                  Expanded(
                    child: Text(
                      t.playerCardTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama),
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => _bagikan(_caption(scope)),
                    icon: const Icon(Icons.ios_share, size: 20, color: AppColors.teksSekunder),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([scope.auth, scope.streak, scope.monsterProgress]),
                builder: (context, _) {
                  final userName = scope.auth.profile?.displayName ?? t.defaultUserName;
                  final tamedCount =
                      scope.monsterProgress.all.values.where((m) => m.state == MonsterState.tamed).length;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RepaintBoundary(
                            key: _cardKey,
                            child: _PlayerCard(
                            userName: userName,
                            streak: scope.streak.current,
                            journalCount: _journalCount,
                            tamedCount: tamedCount,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            t.shareNote,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: RiungButton(label: t.share, onPressed: _busy ? null : () => _bagikan(_caption(scope))),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _simpan,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppColors.garis, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      ),
                      icon: const Icon(Icons.download_outlined, size: 17, color: AppColors.teksSekunder),
                      label: Text(t.saveImage, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 15)),
                    ),
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

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.userName,
    required this.streak,
    required this.journalCount,
    required this.tamedCount,
  });

  final String userName;
  final int streak;
  final int? journalCount;
  final int tamedCount;

  @override
  Widget build(BuildContext context) {
    final t = context.s.home;
    return Container(
      width: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.garis),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.kartu, AppColors.permukaan],
        ),
      ),
      child: Column(
        children: [
          RiungGlowBackground(
            glowColor: AppColors.primer,
            alignment: const Alignment(0, -1),
            opacity: 0.3,
            radius: 1.1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Column(
                children: [
                  const SizedBox(
                    width: 96,
                    height: 100,
                    child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.liar, size: 96, applyBossScale: false),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(userName, style: AppTextStyles.title.copyWith(fontSize: 19)),
                  Text(
                    t.playerRank,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.monsterCermin,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: AppColors.garis,
            child: Column(
              children: [
                Row(
                  children: [
                    _StatCell(value: context.s.profil.daysCount(streak), label: t.statStreak, color: AppColors.aksenHangat),
                    const SizedBox(width: 1),
                    _StatCell(
                      value: journalCount == null ? '…' : '$journalCount',
                      label: t.statJournal,
                      color: AppColors.monsterCermin,
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    _StatCell(value: '$tamedCount', label: t.statTamed, color: AppColors.sekunder),
                    const SizedBox(width: 1),
                    _StatCell(value: '$tamedCount/7', label: t.statProgress, color: AppColors.primer),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 13),
            color: AppColors.permukaan,
            child: Row(
              children: [
                Text(t.tamedOf(tamedCount), style: AppTextStyles.caption.copyWith(fontSize: 10)),
                const Spacer(),
                Text(
                  'riung.app',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primer, fontWeight: FontWeight.w700, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: AppColors.permukaan,
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.title.copyWith(fontSize: 17, color: color)),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
