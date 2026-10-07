import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/meditation_catalog.dart';
import 'meditasi_detail_screen.dart';
import 'meditasi_search_screen.dart';

/// Perpustakaan meditasi. Implement persis `design/Meditasi.dc.html`
/// § Perpustakaan meditasi.
class MeditasiListScreen extends StatefulWidget {
  const MeditasiListScreen({super.key});

  @override
  State<MeditasiListScreen> createState() => _MeditasiListScreenState();
}

class _MeditasiListScreenState extends State<MeditasiListScreen> {
  MeditationFilter _filter = MeditationFilter.semua;

  List<MeditationSession> get _cemas =>
      MeditationCatalog.all.where((s) => s.category == 'cemas').toList();
  List<MeditationSession> get _pelajar =>
      MeditationCatalog.all.where((s) => s.category == 'pelajar').toList();

  /// Filter chip → `category` field di [MeditationSession]. "Pemula"
  /// nggak punya kategori sendiri di data, jadi dipetakan ke sesi yang
  /// sudah gratis ([MeditationCatalog.isFree]) — itu yang paling masuk
  /// akal buat "cocok buat pemula" tanpa nambah field baru di model.
  List<MeditationSession> get _filteredByChip {
    switch (_filter) {
      case MeditationFilter.cemas:
        return _cemas;
      case MeditationFilter.stresKerja:
        return MeditationCatalog.all.where((s) => s.category == 'kerja').toList();
      case MeditationFilter.fokusBelajar:
        return _pelajar;
      case MeditationFilter.pemula:
        return [
          for (var i = 0; i < MeditationCatalog.all.length; i++)
            if (MeditationCatalog.isFree(i)) MeditationCatalog.all[i],
        ];
      case MeditationFilter.semua:
        return MeditationCatalog.all;
    }
  }

  void _openSession(MeditationSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MeditasiDetailScreen(session: session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.meditasi;
    final featured = MeditationCatalog.byId('jeda_kerja');
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl + MediaQuery.paddingOf(context).bottom),
          children: [
            Row(
              children: [
                // Cuma tampil kalau layar ini di-push (mis. dari kartu
                // cepat di Beranda) — sebagai tab Jelajah, Navigator.canPop
                // == false, jadi tidak ada back ganda.
                if (Navigator.canPop(context)) ...[
                  RiungGlassIconButton(icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title, style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.2)),
                      const SizedBox(height: 4),
                      Text(t.subtitle, style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.teksSekunder)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SearchBar(
              hint: t.searchHint,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MeditasiSearchScreen())),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_filter == MeditationFilter.semua) ...[
              _FeaturedCard(session: featured, onTap: () => _openSession(featured)),
              const SizedBox(height: AppSpacing.lg),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final filter in MeditationFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: RiungFilterChip(
                        label: t.filterLabel(filter),
                        selected: filter == _filter,
                        onTap: () => setState(() => _filter = filter),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_filter == MeditationFilter.semua) ...[
              _SectionTitle(t.sectionAnxiety),
              for (final session in _cemas) _SessionRow(session: session, onTap: () => _openSession(session)),
              const SizedBox(height: AppSpacing.sm),
              _SectionTitle(t.sectionStudents),
              for (final session in _pelajar) _SessionRow(session: session, onTap: () => _openSession(session)),
            ] else if (_filteredByChip.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Text(t.emptyCategory(t.filterLabel(_filter)), textAlign: TextAlign.center, style: AppTextStyles.body),
              )
            else
              for (final session in _filteredByChip) _SessionRow(session: session, onTap: () => _openSession(session)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.xs),
      child: Text(text, style: AppTextStyles.title.copyWith(fontSize: 17, color: AppColors.teksUtama)),
    );
  }
}

/// Bilah cari kaca (frame `Cari`) — membuka layar pencarian.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.permukaan.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18, color: AppColors.teksRedup),
            const SizedBox(width: 10),
            Text(hint, style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.teksRedup)),
          ],
        ),
      ),
    );
  }
}

/// Kartu unggulan (frame `Unggulan`): gradien sage→biru, teratai 3D, tombol
/// pil tinta "Putar".
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.session, required this.onTap});

  final MeditationSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.meditasi;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 200),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primerLembut, AppColors.kabutSage, AppColors.langitLembut],
          ),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
          boxShadow: AppGlass.shadow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              width: 240,
              height: 240,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)]),
                ),
              ),
            ),
            const Positioned(right: 0, bottom: 0, child: RiungIcon3D(RiungIcon.meditasi, size: 170)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 150, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.featuredKicker.toUpperCase(), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.primer)),
                  const SizedBox(height: 6),
                  Text(t.session(session.id).title, style: AppTextStyles.title.copyWith(fontSize: 22, height: 1.1, color: AppColors.teksUtama)),
                  const SizedBox(height: 6),
                  Text(t.durationCoins(session.defaultDuration, EconomyEarn.meditasi), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                  const SizedBox(height: 26),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.fromLTRB(7, 7, 18, 7),
                    decoration: BoxDecoration(color: AppColors.tinta, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(color: AppColors.diAtasTinta, shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.tinta),
                        ),
                        const SizedBox(width: 8),
                        Text(t.play, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.diAtasTinta)),
                      ],
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

/// Baris sesi (frame `Sesi …`): thumbnail pastel + monster sasaran 3D,
/// eyebrow "MELAWAN …", judul, meta, tombol putar / kunci premium.
class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onTap});

  final MeditationSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.meditasi;
    final free = MeditationCatalog.isSessionFree(session.id);
    final monsterId = session.targetMonsterId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RiungGlassCard(
        onTap: onTap,
        radius: 24,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.monsterLembut[monsterId] ?? AppColors.kabutSage, borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 58, applyBossScale: false),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.s.afirmasi.deckAgainst(context.s.common.monsterName(monsterId)).toUpperCase(),
                    style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup),
                  ),
                  const SizedBox(height: 3),
                  Text(t.session(session.id).title, maxLines: 2, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, height: 1.25, color: AppColors.teksUtama)),
                  const SizedBox(height: 3),
                  Text(t.durationCoins(session.defaultDuration, EconomyEarn.meditasi), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: free ? AppColors.permukaan : AppColors.sekunderLembut,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.garis),
              ),
              child: Icon(free ? Icons.play_arrow_rounded : Icons.lock_rounded, size: 18, color: free ? AppColors.teksUtama : AppColors.sekunder),
            ),
          ],
        ),
      ),
    );
  }
}
