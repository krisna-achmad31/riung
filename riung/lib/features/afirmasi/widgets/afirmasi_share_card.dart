import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Tiga gaya kartu yang bisa dipilih pengguna.
enum AfirmasiShareStyle { mengintip, catatan, malam }

/// Kartu bagikan (frame `Glass — Afirmasi · Kartu bagikan (opsi)` di
/// `design/riung.pen`). Ditata di kanvas tetap 360×520 lalu diskalakan,
/// supaya komposisi sama di semua lebar layar dan di gambar ekspor.
class AfirmasiShareCard extends StatelessWidget {
  const AfirmasiShareCard({
    super.key,
    required this.style,
    required this.text,
    required this.monsterId,
    required this.brand,
  });

  static const double _width = 360;
  static const double _height = 520;

  final AfirmasiShareStyle style;
  final String text;
  final String monsterId;
  final String brand;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _width / _height,
      child: FittedBox(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: SizedBox(
            width: _width,
            height: _height,
            child: switch (style) {
              AfirmasiShareStyle.mengintip => _MengintipLayout(text: text, monsterId: monsterId, brand: brand),
              AfirmasiShareStyle.catatan => _CatatanLayout(text: text, monsterId: monsterId, brand: brand),
              AfirmasiShareStyle.malam => _MalamLayout(text: text, monsterId: monsterId, brand: brand),
            },
          ),
        ),
      ),
    );
  }
}

/// Teks panjang mengecil sendiri supaya tidak menabrak monster.
class _Quote extends StatelessWidget {
  const _Quote({required this.text, required this.style, this.align = TextAlign.left});

  final String text;
  final TextStyle style;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: align == TextAlign.center ? Alignment.topCenter : Alignment.topLeft,
      child: SizedBox(width: 304, child: Text(text, textAlign: align, style: style)),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.brand, required this.color});

  final String brand;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(brand, style: AppTextStyles.chipLabel.copyWith(fontSize: 17, fontWeight: FontWeight.w800, color: color));
  }
}

class _MengintipLayout extends StatelessWidget {
  const _MengintipLayout({required this.text, required this.monsterId, required this.brand});

  final String text;
  final String monsterId;
  final String brand;

  @override
  Widget build(BuildContext context) {
    final warna = AppColors.monsterLembut[monsterId] ?? AppColors.kabutSage;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(warna, AppColors.permukaanPadat, 0.5)!, warna]),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(left: 92, top: 230, child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 400)),
          Positioned(
            left: 28,
            top: 44,
            width: 304,
            height: 180,
            child: _Quote(text: text, style: AppTextStyles.display.copyWith(fontSize: 38, height: 1.12, fontWeight: FontWeight.w800, color: AppColors.kartuBagikanTeksKoral)),
          ),
          Positioned(left: 28, bottom: 24, child: _Brand(brand: brand, color: AppColors.kartuBagikanTeksKoral)),
        ],
      ),
    );
  }
}

class _CatatanLayout extends StatelessWidget {
  const _CatatanLayout({required this.text, required this.monsterId, required this.brand});

  final String text;
  final String monsterId;
  final String brand;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.kartuBagikanMintAwal, AppColors.kartuBagikanMintAkhir]),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 34,
            top: 60,
            width: 286,
            height: 250,
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.kartuBagikanKertas, borderRadius: BorderRadius.circular(10)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 238,
                    child: Text(text, style: const TextStyle(fontFamily: 'Caveat', fontSize: 42, height: 1.05, fontWeight: FontWeight.w700, color: AppColors.kartuBagikanTeksTinta)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(left: 170, top: 290, child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 190)),
          Positioned(left: 28, bottom: 24, child: _Brand(brand: brand, color: AppColors.kartuBagikanTeksTinta)),
        ],
      ),
    );
  }
}

class _MalamLayout extends StatelessWidget {
  const _MalamLayout({required this.text, required this.monsterId, required this.brand});

  final String text;
  final String monsterId;
  final String brand;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.kartuBagikanMalamAwal, AppColors.kartuBagikanMalamAkhir]),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 220,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.kartuBagikanCahaya, AppColors.kartuBagikanCahayaPudar]),
              ),
            ),
          ),
          Positioned(top: 270, child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 180)),
          Positioned(
            left: 28,
            top: 56,
            width: 304,
            height: 180,
            child: _Quote(
              text: text,
              align: TextAlign.center,
              style: AppTextStyles.display.copyWith(fontSize: 34, height: 1.18, fontWeight: FontWeight.w700, color: AppColors.kartuBagikanTeksMalam),
            ),
          ),
          Positioned(bottom: 24, child: _Brand(brand: brand, color: AppColors.kartuBagikanTeksMalam)),
        ],
      ),
    );
  }
}
