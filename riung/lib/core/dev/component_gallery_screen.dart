import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// Layar QA sementara — bukan bagian dari alur app, hanya untuk
/// membandingkan token & komponen `core/theme` + `core/widgets` sisi-sisi
/// dengan `design/Design System.dc.html` §01–05 (gate QA M0).
class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  RiungNavTab _tab = RiungNavTab.beranda;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      appBar: AppBar(title: const Text('Galeri Komponen Riung')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _SectionTitle('01 · Warna'),
          _ColorGroup('Inti / netral', {
            'Latar': AppColors.latar,
            'Permukaan': AppColors.permukaan,
            'Kartu': AppColors.kartu,
            'Garis': AppColors.garis,
          }),
          _ColorGroup('Brand & aksen', {
            'Primer': AppColors.primer,
            'Primer gelap': AppColors.primerGelap,
            'Sekunder': AppColors.sekunder,
            'Aksen hangat': AppColors.aksenHangat,
          }),
          _ColorGroup('Teks', {
            'Teks utama': AppColors.teksUtama,
            'Teks sekunder': AppColors.teksSekunder,
            'Teks redup': AppColors.teksRedup,
          }),
          _ColorGroup('Semantik', {
            'Sukses': AppColors.sukses,
            'Peringatan': AppColors.peringatan,
            'Error': AppColors.error,
            'Info': AppColors.info,
          }),
          _ColorGroup('Warna monster', AppColors.monsterColors),
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle('02 · Tipografi'),
          _TypographyCard(),
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle('05 · Tombol'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.kartu,
              border: Border.all(color: AppColors.garis),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: Column(
              children: [
                RiungButton(label: 'Mulai sekarang', onPressed: () {}),
                const SizedBox(height: AppSpacing.md),
                RiungButton(
                  label: 'Nanti saja',
                  variant: RiungButtonVariant.secondary,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.md),
                RiungButton(
                  label: 'Lewati',
                  variant: RiungButtonVariant.text,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.md),
                const RiungButton(label: 'Lanjut (nonaktif)', onPressed: null),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle('05 · Chip koin, streak & tiket'),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              KoinChip(balance: 145),
              StreakChip(days: 12),
              TiketChip(count: 3),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle('05 · Navigasi bawah'),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            child: RiungBottomNav(
              current: _tab,
              onTabSelected: (tab) => setState(() => _tab = tab),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle('06 · Monster - 14 ilustrasi (liar ke jinak)'),
          Text(
            'Si Hakim otomatis dirender bossScale× lebih besar dari 6 lainnya '
            '(dari anchors.json), bukan nilai tetap.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          Column(
            children: [
              for (final m in _monsterMeta) ...[
                _MonsterPairCard(id: m.$1, name: m.$2),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
          _SectionTitle('07 · Monster berkostum'),
          const Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              _MonsterTile(id: 'kabut', name: 'Si Kabut + Topi Rajut', cosmetics: ['topi_rajut']),
              _MonsterTile(id: 'waswas', name: 'Si Waswas + Syal Hangat', cosmetics: ['syal_hangat']),
              _MonsterTile(id: 'meronta', name: 'Si Meronta + Bantal Mini', cosmetics: ['bantal_mini']),
              _MonsterTile(id: 'cermin', name: 'Si Cermin + Bingkai Emas', cosmetics: ['bingkai_emas']),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

const List<(String, String)> _monsterMeta = [
  ('meronta', 'Si Meronta'),
  ('waswas', 'Si Waswas'),
  ('kabut', 'Si Kabut'),
  ('cermin', 'Si Cermin'),
  ('sempurna', 'Si Sempurna'),
  ('mengelak', 'Si Mengelak'),
  ('hakim', 'Si Hakim'),
];

/// Kartu satu monster: nama + render liar & jinak, ukuran dasar 160dp tapi
/// selalu di-clamp ke lebar layar yang tersedia lewat [LayoutBuilder] —
/// jadi tidak overflow di HP manapun, termasuk Si Hakim yang `bossScale`-nya
/// (dibaca dari anchors.json, bukan nilai tetap) bisa jauh lebih besar.
/// Monster boss ditumpuk vertikal (satu kolom penuh); non-boss berdampingan.
class _MonsterPairCard extends StatelessWidget {
  const _MonsterPairCard({required this.id, required this.name});

  static const double _preferredSize = 160;
  static const double _slotPadding = AppSpacing.sm * 2;

  final String id;
  final String name;

  @override
  Widget build(BuildContext context) {
    final bossScale = RiungMonster.bossScaleOf(id);
    final isBoss = bossScale > 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.kartu,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(name, style: AppTextStyles.subtitle),
              if (isBoss) ...[
                const SizedBox(width: AppSpacing.sm),
                const _BossBadge(),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              // Lebar slot target (setelah bossScale diterapkan): boss dapat
              // seluruh lebar kartu — dibudget sampai `_preferredSize *
              // bossScale` supaya efek "1.4x lebih besar" tetap kelihatan,
              // bukan disamakan dengan slot non-boss — lalu ditumpuk
              // vertikal. Non-boss berbagi dua kolom berdampingan.
              final fullSlot =
                  math.min(_preferredSize * bossScale, constraints.maxWidth) - _slotPadding;
              final pairSlot = math.min(
                _preferredSize,
                (constraints.maxWidth - AppSpacing.md) / 2,
              ) - _slotPadding;
              final slotWidth = math.max(0.0, isBoss ? fullSlot : pairSlot);
              // `size` yang dikirim ke RiungMonster sebelum di-kali bossScale
              // di dalam widget, supaya hasil akhirnya pas dengan slotWidth.
              final monsterSize = slotWidth / bossScale;

              final liar = _StateSlot(
                label: 'Liar',
                slotWidth: slotWidth,
                child: RiungMonster(monsterId: id, state: MonsterVisualState.liar, size: monsterSize),
              );
              final jinak = _StateSlot(
                label: 'Jinak',
                slotWidth: slotWidth,
                child: RiungMonster(monsterId: id, state: MonsterVisualState.jinak, size: monsterSize),
              );

              if (isBoss) {
                return Column(
                  children: [liar, const SizedBox(height: AppSpacing.md), jinak],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [liar, jinak],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BossBadge extends StatelessWidget {
  const _BossBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.monsterHakim.withValues(alpha: 0.16),
        border: Border.all(color: AppColors.monsterHakim),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'BOS',
        style: AppTextStyles.caption.copyWith(color: AppColors.monsterHakim, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Satu slot state (liar/jinak) — lebar dikunci ke [slotWidth] & isinya
/// di-scale-down lewat [FittedBox] sebagai jaring pengaman terakhir kalau
/// perhitungan `monsterSize` masih meleset sedikit (mis. pembulatan).
class _StateSlot extends StatelessWidget {
  const _StateSlot({required this.label, required this.slotWidth, required this.child});

  final String label;
  final double slotWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final boxWidth = slotWidth + AppSpacing.sm * 2;
    return Column(
      children: [
        Container(
          width: boxWidth,
          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.latar,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          clipBehavior: Clip.hardEdge,
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label.toUpperCase(), style: AppTextStyles.caption),
      ],
    );
  }
}

/// Satu monster dengan kosmetik terpasang — nama + render jinak 160dp.
class _MonsterTile extends StatelessWidget {
  const _MonsterTile({required this.id, required this.name, required this.cosmetics});

  final String id;
  final String name;
  final List<String> cosmetics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.kartu,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.latar,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: RiungMonster(
              monsterId: id,
              state: MonsterVisualState.jinak,
              size: 160,
              cosmetics: cosmetics,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(name, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 13)),
        ],
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
      padding: const EdgeInsets.only(bottom: AppSpacing.lg, top: AppSpacing.sm),
      child: Text(text, style: AppTextStyles.title),
    );
  }
}

class _ColorGroup extends StatelessWidget {
  const _ColorGroup(this.label, this.colors);
  final String label;
  final Map<String, Color> colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final entry in colors.entries)
                Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: AppColors.permukaan,
                    border: Border.all(color: AppColors.garis),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 56, color: entry.value),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Text(entry.key, style: AppTextStyles.chipLabel.copyWith(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypographyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.kartu,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selamat datang kembali, Raka', style: AppTextStyles.display),
          const SizedBox(height: AppSpacing.lg),
          Text('Jinakkan Si Waswas hari ini', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),
          Text('Meditasi pagi · 10 menit', style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Pikiran yang berisik itu wajar, kok. Pelan-pelan saja, kita kenali dulu monster mana yang paling sering muncul, lalu kita jinakkan bersama.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Sumber: I-NAMHS 2022 · Bukan alat diagnosis', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
