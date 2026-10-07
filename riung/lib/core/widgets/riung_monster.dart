import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/monster_anchor.dart';
import '../services/monster_anchor_registry.dart';
import 'riung_ground_shadow.dart';

/// Wujud visual monster — hanya dua varian art, terpisah dari
/// `MonsterState` (wild/taming/tamed) yang menandai progres penjinakan.
enum MonsterVisualState { liar, jinak }

/// Renderer monster: art 3D (WebP) + kosmetik ter-anchor, ditumpuk sesuai
/// `zIndex` dari `assets/monsters/anchors.json` (CLAUDE.md aturan #7).
///
/// - `size` = lebar render; tinggi dihitung dari rasio `sourceViewBox`
///   (kanvas persegi, garis lantai seragam untuk semua monster).
/// - Si Hakim otomatis di-render `bossScale`× lebih besar (set
///   `applyBossScale: false` untuk menonaktifkan, mis. di grid seragam).
/// - Gambar di-decode seukuran tampilan (`cacheWidth`) supaya hemat memori
///   di HP RAM 2–4GB.
class RiungMonster extends StatelessWidget {
  const RiungMonster({
    super.key,
    required this.monsterId,
    required this.state,
    required this.size,
    this.cosmetics = const [],
    this.applyBossScale = true,
  });

  final String monsterId;
  final MonsterVisualState state;
  final double size;
  final List<String> cosmetics;
  final bool applyBossScale;

  /// Faktor `bossScale` monster (1.0 bila bukan bos atau data belum
  /// termuat) — dipakai layar pemanggil untuk menghitung `size` yang
  /// responsif terhadap lebar layar tanpa menduplikasi lookup ke
  /// [MonsterAnchorRegistry].
  static double bossScaleOf(String monsterId) {
    final data = MonsterAnchorRegistry.instance.dataOrNull;
    return data?.monsters[monsterId]?.bossScale ?? 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final cached = MonsterAnchorRegistry.instance.dataOrNull;
    if (cached != null) {
      return _RiungMonsterBody(
        data: cached,
        monsterId: monsterId,
        state: state,
        size: size,
        cosmetics: cosmetics,
        applyBossScale: applyBossScale,
      );
    }

    return FutureBuilder<MonsterAnchorData>(
      future: MonsterAnchorRegistry.instance.load(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return SizedBox(width: size, height: size);
        }
        return _RiungMonsterBody(
          data: data,
          monsterId: monsterId,
          state: state,
          size: size,
          cosmetics: cosmetics,
          applyBossScale: applyBossScale,
        );
      },
    );
  }
}

class _RiungMonsterBody extends StatelessWidget {
  const _RiungMonsterBody({
    required this.data,
    required this.monsterId,
    required this.state,
    required this.size,
    required this.cosmetics,
    required this.applyBossScale,
  });

  final MonsterAnchorData data;
  final String monsterId;
  final MonsterVisualState state;
  final double size;
  final List<String> cosmetics;
  final bool applyBossScale;

  bool get _jinak => state == MonsterVisualState.jinak;

  @override
  Widget build(BuildContext context) {
    final monster = data.monsters[monsterId];
    if (monster == null) {
      assert(false, 'RiungMonster: monsterId tidak dikenal di anchors.json: $monsterId');
      return SizedBox(width: size, height: size);
    }

    final bossScale = applyBossScale ? monster.bossScale : 1.0;
    final renderWidth = size * bossScale;
    final renderHeight = renderWidth * data.sourceHeight / data.sourceWidth;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;

    final under = <Widget>[];
    final over = <Widget>[];
    for (final cosmeticId in cosmetics) {
      final cosmetic = data.cosmetics[cosmeticId];
      if (cosmetic == null) {
        assert(false, 'RiungMonster: cosmeticId tidak dikenal di anchors.json: $cosmeticId');
        continue;
      }
      final layer = _buildCosmeticLayer(cosmetic, monster, renderWidth, renderHeight, dpr);
      if (layer == null) continue;
      (cosmetic.zIndex <= 0 ? under : over).add(layer);
    }

    return SizedBox(
      width: renderWidth,
      height: renderHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RiungGroundShadow(canvasWidth: renderWidth, canvasHeight: renderHeight),
          ...under,
          Positioned.fill(
            child: _MonsterImage(
              asset: data.assetPath(monster.fileFor(jinak: _jinak)),
              width: renderWidth,
              dpr: dpr,
            ),
          ),
          ...over,
        ],
      ),
    );
  }

  /// Menempatkan satu kosmetik. Slot `none` (khusus `bingkai_emas`) adalah
  /// overlay kanvas penuh yang sudah di-precompose per wujud — cukup
  /// ditimpa 1:1 di atas body, tanpa anchor.
  Widget? _buildCosmeticLayer(
    CosmeticConfig cosmetic,
    MonsterAnchorConfig monster,
    double renderWidth,
    double renderHeight,
    double dpr,
  ) {
    final asset = data.assetPath(cosmetic.fileFor(jinak: _jinak));

    if (cosmetic.slot == CosmeticSlot.none) {
      return Positioned.fill(child: _MonsterImage(asset: asset, width: renderWidth, dpr: dpr));
    }

    final anchor = monster.anchorFor(cosmetic.slot.name, jinak: _jinak);
    if (anchor == null) return null;

    final w = renderWidth * cosmetic.width * anchor.scale;
    final h = w / cosmetic.aspect;
    final px = anchor.x * renderWidth;
    final py = anchor.y * renderHeight;

    return Positioned(
      left: px - cosmetic.pivotX * w,
      top: py - cosmetic.pivotY * h,
      width: w,
      height: h,
      child: Transform.rotate(
        angle: anchor.rotationDeg * math.pi / 180,
        alignment: FractionalOffset(cosmetic.pivotX, cosmetic.pivotY),
        child: _MonsterImage(asset: asset, width: w, dpr: dpr),
      ),
    );
  }
}

/// Satu layer art. `cacheWidth` mengikuti ukuran tampil × DPR (minimal 3×
/// supaya kartu yang diekspor jadi PNG tetap tajam) — decode tidak memakai
/// resolusi penuh; `gaplessPlayback` mencegah kedip saat liar ↔ jinak berganti.
class _MonsterImage extends StatelessWidget {
  const _MonsterImage({required this.asset, required this.width, required this.dpr});

  final String asset;
  final double width;
  final double dpr;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      cacheWidth: (width * math.max(dpr, 3.0)).round().clamp(1, 1024),
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
  }
}
