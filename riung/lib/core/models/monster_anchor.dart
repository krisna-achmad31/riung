import 'model_utils.dart';

/// Titik tempel kosmetik pada satu slot (head/neck/base) — posisi
/// dinormalisasi 0–1 terhadap kanvas persegi art monster (`sourceViewBox`
/// di `assets/monsters/anchors.json`).
class AnchorPoint {
  const AnchorPoint({
    required this.x,
    required this.y,
    required this.scale,
    required this.rotationDeg,
  });

  factory AnchorPoint.fromMap(Map<String, dynamic> map) {
    return AnchorPoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      rotationDeg: (map['rotationDeg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final double x;
  final double y;
  final double scale;
  final double rotationDeg;
}

/// Slot tempel kosmetik. `none` = overlay kanvas penuh 1:1 (khusus
/// `bingkai_emas`, sudah di-precompose per wujud Cermin), bukan anchor.
enum CosmeticSlot { head, neck, base, side, none }

/// Mirror satu entri `cosmetics.<id>` di `anchors.json`.
class CosmeticConfig {
  const CosmeticConfig({
    required this.id,
    required this.file,
    required this.slot,
    required this.zIndex,
    required this.canonicalWearer,
    required this.width,
    required this.aspect,
    required this.pivotX,
    required this.pivotY,
    this.fileLiar,
  });

  factory CosmeticConfig.fromMap(String id, Map<String, dynamic> map) {
    final pivot = (map['pivot'] as Map?)?.cast<String, dynamic>() ?? const {};
    return CosmeticConfig(
      id: id,
      file: map['file'] as String,
      fileLiar: map['fileLiar'] as String?,
      slot: enumFromName(CosmeticSlot.values, map['slot'] as String?, CosmeticSlot.none),
      zIndex: parseInt(map['zIndex']),
      canonicalWearer: map['canonicalWearer'] as String? ?? '',
      width: (map['width'] as num?)?.toDouble() ?? 1.0,
      aspect: (map['aspect'] as num?)?.toDouble() ?? 1.0,
      pivotX: (pivot['x'] as num?)?.toDouble() ?? 0.5,
      pivotY: (pivot['y'] as num?)?.toDouble() ?? 0.5,
    );
  }

  final String id;
  final String file;

  /// File khusus wujud liar (dipakai overlay slot `none` yang mengikuti pose).
  final String? fileLiar;
  final CosmeticSlot slot;
  final int zIndex;
  final String canonicalWearer;

  /// Lebar kosmetik sebagai fraksi lebar render monster (sebelum `anchor.scale`).
  final double width;

  /// Rasio lebar/tinggi gambar kosmetik.
  final double aspect;

  /// Titik di gambar kosmetik (0–1) yang ditempel ke anchor & jadi pusat rotasi.
  final double pivotX;
  final double pivotY;

  String fileFor({required bool jinak}) => jinak ? file : (fileLiar ?? file);
}

/// Mirror satu entri `monsters.<id>` di `anchors.json`.
class MonsterAnchorConfig {
  const MonsterAnchorConfig({
    required this.id,
    required this.isBoss,
    required this.bossScale,
    required this.fileLiar,
    required this.fileJinak,
    required this.anchors,
    this.anchorsLiar = const {},
  });

  factory MonsterAnchorConfig.fromMap(String id, Map<String, dynamic> map) {
    final files = (map['files'] as Map).cast<String, dynamic>();
    return MonsterAnchorConfig(
      id: id,
      isBoss: map['boss'] as bool? ?? false,
      bossScale: (map['bossScale'] as num?)?.toDouble() ?? 1.0,
      fileLiar: files['liar'] as String,
      fileJinak: files['jinak'] as String,
      anchors: _parseAnchors(map['anchors']),
      anchorsLiar: _parseAnchors(map['anchorsLiar']),
    );
  }

  static Map<String, AnchorPoint> _parseAnchors(Object? raw) {
    if (raw is! Map) return const {};
    return raw.cast<String, dynamic>().map(
          (slot, v) => MapEntry(slot, AnchorPoint.fromMap((v as Map).cast<String, dynamic>())),
        );
  }

  final String id;
  final bool isBoss;
  final double bossScale;
  final String fileLiar;
  final String fileJinak;

  /// Anchor wujud jinak. Key: 'head' | 'neck' | 'base'.
  final Map<String, AnchorPoint> anchors;

  /// Anchor wujud liar (pose art 3D berbeda); slot yang tidak ada jatuh ke [anchors].
  final Map<String, AnchorPoint> anchorsLiar;

  String fileFor({required bool jinak}) => jinak ? fileJinak : fileLiar;

  AnchorPoint? anchorFor(String slot, {required bool jinak}) =>
      jinak ? anchors[slot] : (anchorsLiar[slot] ?? anchors[slot]);
}

/// Mirror penuh `assets/monsters/anchors.json` — satu-satunya sumber
/// posisi/skala/rotasi render monster & kosmetik (CLAUDE.md aturan #7).
class MonsterAnchorData {
  const MonsterAnchorData({
    required this.sourceWidth,
    required this.sourceHeight,
    required this.assetDir,
    required this.monsters,
    required this.cosmetics,
  });

  factory MonsterAnchorData.fromMap(Map<String, dynamic> map) {
    final viewBox = (map['sourceViewBox'] as Map).cast<String, dynamic>();
    final monstersRaw = (map['monsters'] as Map).cast<String, dynamic>();
    final cosmeticsRaw = (map['cosmetics'] as Map).cast<String, dynamic>();
    return MonsterAnchorData(
      sourceWidth: (viewBox['width'] as num).toDouble(),
      sourceHeight: (viewBox['height'] as num).toDouble(),
      assetDir: map['assetDir'] as String? ?? 'assets/monsters/3d',
      monsters: monstersRaw.map(
        (id, v) => MapEntry(id, MonsterAnchorConfig.fromMap(id, (v as Map).cast<String, dynamic>())),
      ),
      cosmetics: cosmeticsRaw.map(
        (id, v) => MapEntry(id, CosmeticConfig.fromMap(id, (v as Map).cast<String, dynamic>())),
      ),
    );
  }

  final double sourceWidth;
  final double sourceHeight;

  /// Folder art monster & kosmetik (WebP), relatif ke root aset.
  final String assetDir;
  final Map<String, MonsterAnchorConfig> monsters;
  final Map<String, CosmeticConfig> cosmetics;

  String assetPath(String file) => '$assetDir/$file';
}
