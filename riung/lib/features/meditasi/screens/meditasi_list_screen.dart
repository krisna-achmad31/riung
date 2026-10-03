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
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        alignment: const Alignment(0, -1.2),
        opacity: 0.14,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            children: [
              Row(
                children: [
                  // Cuma tampil kalau layar ini di-push (mis. dari kartu
                  // cepat di Beranda) — sebagai tab Jelajah, Navigator.canPop
                  // == false, jadi tidak ada back ganda.
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
                        Text(context.s.meditasi.title, style: AppTextStyles.display.copyWith(fontSize: 22)),
                        Text(context.s.meditasi.subtitle, style: AppTextStyles.caption.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MeditasiSearchScreen()),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.kartu,
                        border: Border.all(color: AppColors.garis),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.search, size: 19, color: AppColors.teksSekunder),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final filter in MeditationFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _CategoryChip(
                          label: context.s.meditasi.filterLabel(filter),
                          selected: filter == _filter,
                          onTap: () => setState(() => _filter = filter),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_filter == MeditationFilter.semua) ...[
                _FeaturedCard(session: MeditationCatalog.byId('jeda_kerja'), onTap: () => _openSession(MeditationCatalog.byId('jeda_kerja'))),
                const SizedBox(height: AppSpacing.lg),
                Text(context.s.meditasi.sectionAnxiety, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 15)),
                const SizedBox(height: AppSpacing.sm),
                for (final session in _cemas) _SessionRow(session: session, onTap: () => _openSession(session)),
                const SizedBox(height: AppSpacing.md),
                Text(context.s.meditasi.sectionStudents, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 15)),
                const SizedBox(height: AppSpacing.sm),
                for (final session in _pelajar) _SessionRow(session: session, onTap: () => _openSession(session)),
              ] else if (_filteredByChip.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Text(
                    context.s.meditasi.emptyCategory(context.s.meditasi.filterLabel(_filter)),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                )
              else
                for (final session in _filteredByChip) _SessionRow(session: session, onTap: () => _openSession(session)),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primer : Colors.transparent,
          border: Border.all(color: selected ? AppColors.primer : AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.chipLabel.copyWith(
            fontSize: 12,
            color: selected ? AppColors.latar : AppColors.teksSekunder,
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.session, required this.onTap});

  final MeditationSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.sekunder.withValues(alpha: 0.18), AppColors.kartu.withValues(alpha: 0.9)]),
        border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.s.meditasi.featuredKicker,
                  style: AppTextStyles.caption.copyWith(color: AppColors.sekunder, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 10),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(context.s.meditasi.session(session.id).title, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 17)),
                const SizedBox(height: AppSpacing.xs),
                Text(context.s.meditasi.session(session.id).description, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.sekunder, borderRadius: BorderRadius.circular(11)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow, size: 13, color: AppColors.latar),
                            const SizedBox(width: 6),
                            Text(context.s.meditasi.play, style: AppTextStyles.caption.copyWith(color: AppColors.latar, fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(context.s.meditasi.durationCoins(session.defaultDuration, EconomyEarn.meditasi), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 84,
            height: 88,
            child: RiungMonster(monsterId: 'waswas', state: MonsterVisualState.jinak, size: 84),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onTap});

  final MeditationSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final free = MeditationCatalog.isSessionFree(session.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.permukaan,
            border: Border.all(color: AppColors.garis),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: session.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Icon(session.icon, size: 21, color: session.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.s.meditasi.session(session.id).title, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14)),
                    Text(context.s.meditasi.durationAmbient(session.defaultDuration), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              if (!free)
                const Icon(Icons.lock, size: 15, color: AppColors.teksRedup)
              else
                Icon(Icons.play_arrow, size: 18, color: session.color),
            ],
          ),
        ),
      ),
    );
  }
}
