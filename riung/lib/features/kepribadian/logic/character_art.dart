import 'character_accessory.dart';

/// Art 3D karakter hasil tes (`assets/characters/<kunci>.webp`, kanvas
/// persegi 512) beserta geometri yang diukur dari gambarnya oleh
/// `tools/build_3d_assets.py` — dipakai untuk menempatkan aksesori.
/// Semua nilai dinormalisasi 0–1 terhadap sisi kanvas.
class CharacterArt {
  const CharacterArt._(
    this.file, {
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.eyeX,
    required this.eyeY,
    required this.eyeDx,
  });

  /// Nama file tanpa ekstensi di `assets/characters/`.
  final String file;

  /// Batas badan (tanpa hiasan di atas kepala & bayangan lantai).
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// Titik tengah di antara kedua mata & setengah jarak antar-mata.
  final double eyeX;
  final double eyeY;
  final double eyeDx;

  String get asset => 'assets/characters/$file.webp';
  double get bodyWidth => right - left;
  double get bodyHeight => bottom - top;

  /// Art untuk [CharacterSpec.artKey], atau null bila belum ada (fallback
  /// ke karakter prosedural).
  static CharacterArt? of(String key) => _all[key];

  static const Map<String, CharacterArt> _all = {
    'aman': CharacterArt._('aman', left: 0.066, top: 0.334, right: 0.82, bottom: 0.92, eyeX: 0.449, eyeY: 0.535, eyeDx: 0.125),
    'ENFJ': CharacterArt._('enfj', left: 0.146, top: 0.301, right: 0.91, bottom: 0.885, eyeX: 0.497, eyeY: 0.541, eyeDx: 0.093),
    'ENFP': CharacterArt._('enfp', left: 0.193, top: 0.373, right: 0.85, bottom: 0.908, eyeX: 0.513, eyeY: 0.529, eyeDx: 0.099),
    'ENTJ': CharacterArt._('entj', left: 0.176, top: 0.318, right: 0.918, bottom: 0.914, eyeX: 0.541, eyeY: 0.496, eyeDx: 0.117),
    'ENTP': CharacterArt._('entp', left: 0.127, top: 0.346, right: 0.84, bottom: 0.926, eyeX: 0.484, eyeY: 0.523, eyeDx: 0.102),
    'ESFJ': CharacterArt._('esfj', left: 0.158, top: 0.316, right: 0.873, bottom: 0.912, eyeX: 0.501, eyeY: 0.502, eyeDx: 0.132),
    'ESFP': CharacterArt._('esfp', left: 0.094, top: 0.348, right: 0.848, bottom: 0.928, eyeX: 0.475, eyeY: 0.541, eyeDx: 0.121),
    'ESTJ': CharacterArt._('estj', left: 0.158, top: 0.328, right: 0.861, bottom: 0.891, eyeX: 0.504, eyeY: 0.535, eyeDx: 0.105),
    'ESTP': CharacterArt._('estp', left: 0.086, top: 0.283, right: 0.848, bottom: 0.924, eyeX: 0.46, eyeY: 0.516, eyeDx: 0.114),
    'INFJ': CharacterArt._('infj', left: 0.238, top: 0.32, right: 0.891, bottom: 0.906, eyeX: 0.554, eyeY: 0.508, eyeDx: 0.101),
    'INFP': CharacterArt._('infp', left: 0.104, top: 0.273, right: 0.688, bottom: 0.902, eyeX: 0.4, eyeY: 0.467, eyeDx: 0.086),
    'INTJ': CharacterArt._('intj', left: 0.074, top: 0.266, right: 0.707, bottom: 0.934, eyeX: 0.39, eyeY: 0.492, eyeDx: 0.106),
    'INTP': CharacterArt._('intp', left: 0.254, top: 0.279, right: 0.84, bottom: 0.896, eyeX: 0.539, eyeY: 0.473, eyeDx: 0.094),
    'ISFJ': CharacterArt._('isfj', left: 0.287, top: 0.219, right: 0.869, bottom: 0.91, eyeX: 0.571, eyeY: 0.459, eyeDx: 0.11),
    'ISFP': CharacterArt._('isfp', left: 0.209, top: 0.297, right: 0.857, bottom: 0.918, eyeX: 0.562, eyeY: 0.533, eyeDx: 0.106),
    'ISTJ': CharacterArt._('istj', left: 0.107, top: 0.225, right: 0.674, bottom: 0.896, eyeX: 0.394, eyeY: 0.41, eyeDx: 0.093),
    'ISTP': CharacterArt._('istp', left: 0.074, top: 0.219, right: 0.721, bottom: 0.881, eyeX: 0.402, eyeY: 0.396, eyeDx: 0.088),
    'cemas': CharacterArt._('cemas', left: 0.221, top: 0.252, right: 0.877, bottom: 0.922, eyeX: 0.548, eyeY: 0.439, eyeDx: 0.087),
    'cemas_menghindar': CharacterArt._('cemas_menghindar', left: 0.137, top: 0.236, right: 0.811, bottom: 0.924, eyeX: 0.48, eyeY: 0.438, eyeDx: 0.109),
    'flegmatis': CharacterArt._('flegmatis', left: 0.062, top: 0.346, right: 0.801, bottom: 0.926, eyeX: 0.437, eyeY: 0.541, eyeDx: 0.14),
    'koleris': CharacterArt._('koleris', left: 0.062, top: 0.314, right: 0.775, bottom: 0.916, eyeX: 0.422, eyeY: 0.488, eyeDx: 0.125),
    'melankolis': CharacterArt._('melankolis', left: 0.131, top: 0.256, right: 0.65, bottom: 0.891, eyeX: 0.394, eyeY: 0.465, eyeDx: 0.091),
    'menghindar': CharacterArt._('menghindar', left: 0.088, top: 0.232, right: 0.758, bottom: 0.916, eyeX: 0.425, eyeY: 0.557, eyeDx: 0.12),
    'sanguinis': CharacterArt._('sanguinis', left: 0.111, top: 0.34, right: 0.883, bottom: 0.934, eyeX: 0.501, eyeY: 0.52, eyeDx: 0.128),
  };
}

/// Aturan tempel aksesori ber-art 3D (`assets/characters/accessories/`).
/// Semua posisi relatif terhadap geometri [CharacterArt]; aksesori tanpa
/// aturan di sini digambar painter.
class AccessoryArt {
  const AccessoryArt._(
    this.anchor, {
    required this.width,
    required this.aspect,
    this.pivotX = 0.5,
    this.pivotY = 0.5,
    this.offsetX = 0,
    this.offsetY = 0,
    this.eyeScaled = false,
  });

  final AccessoryAnchor anchor;

  /// Lebar sebagai kelipatan lebar badan, atau kelipatan [CharacterArt.eyeDx]
  /// bila [eyeScaled] (barang di wajah).
  final double width;

  /// Rasio lebar/tinggi gambar (dari `tools/build_3d_assets.py`).
  final double aspect;

  /// Titik di gambar (0–1) yang ditempel ke anchor.
  final double pivotX;
  final double pivotY;

  /// Geser horizontal: kelipatan [CharacterArt.eyeDx] bila [eyeScaled],
  /// selain itu kelipatan lebar badan.
  final double offsetX;

  /// Geser vertikal sebagai fraksi tinggi badan.
  final double offsetY;
  final bool eyeScaled;

  String asset(CharacterAccessory a) => 'assets/characters/accessories/${a.name}.webp';

  static AccessoryArt? of(CharacterAccessory a) => _all[a];

  static const Map<CharacterAccessory, AccessoryArt> _all = {
    // ── Kepala ──
    CharacterAccessory.beanie: AccessoryArt._(AccessoryAnchor.headTop, width: 0.78, aspect: 1.1034, pivotY: 0.82, offsetY: 0.12),
    CharacterAccessory.ribbon: AccessoryArt._(AccessoryAnchor.headTop, width: 0.42, aspect: 1.3913, offsetX: -0.26, offsetY: 0.06),
    CharacterAccessory.flower: AccessoryArt._(AccessoryAnchor.headTop, width: 0.36, aspect: 1.259, offsetX: 0.26, offsetY: 0.07),
    CharacterAccessory.witchHat: AccessoryArt._(AccessoryAnchor.headTop, width: 0.95, aspect: 1.2347, pivotY: 0.86, offsetY: 0.1),
    CharacterAccessory.headphones: AccessoryArt._(AccessoryAnchor.eyes, width: 1.45, aspect: 1.0787, pivotY: 0.64),
    CharacterAccessory.halo: AccessoryArt._(AccessoryAnchor.headTop, width: 0.5, aspect: 1.1925, pivotY: 0.6, offsetY: -0.2),
    CharacterAccessory.jungCrown: AccessoryArt._(AccessoryAnchor.headTop, width: 0.72, aspect: 1.6696, pivotY: 0.75, offsetY: 0.02),
    CharacterAccessory.tempFlame: AccessoryArt._(AccessoryAnchor.headTop, width: 0.3, aspect: 0.7891, pivotY: 0.95, offsetY: 0.05),
    CharacterAccessory.attNightCap: AccessoryArt._(AccessoryAnchor.headTop, width: 0.92, aspect: 1.6991, pivotY: 0.8, offsetY: 0.14),
    // ── Wajah ──
    CharacterAccessory.roundGlasses: AccessoryArt._(AccessoryAnchor.eyes, width: 4.2, aspect: 2.087, eyeScaled: true),
    CharacterAccessory.sunglasses: AccessoryArt._(AccessoryAnchor.eyes, width: 4.4, aspect: 2.6122, eyeScaled: true),
    CharacterAccessory.starStickers: AccessoryArt._(AccessoryAnchor.eyes, width: 3.6, aspect: 2.3133, offsetY: 0.13, eyeScaled: true),
    CharacterAccessory.jungMask: AccessoryArt._(AccessoryAnchor.eyes, width: 4.4, aspect: 2.2197, eyeScaled: true),
    CharacterAccessory.tempMonocle: AccessoryArt._(AccessoryAnchor.eyes, width: 2.3, aspect: 0.9531, pivotX: 0.42, pivotY: 0.36, offsetX: 1.0, eyeScaled: true),
    CharacterAccessory.attHeartCharm: AccessoryArt._(AccessoryAnchor.eyes, width: 1.0, aspect: 0.4896, offsetX: 2.4, offsetY: -0.02, eyeScaled: true),
    // ── Leher ──
    CharacterAccessory.scarf: AccessoryArt._(AccessoryAnchor.body, width: 0.62, aspect: 1.035, pivotY: 0.22, offsetY: 0.7),
    CharacterAccessory.necklace: AccessoryArt._(AccessoryAnchor.body, width: 0.56, aspect: 1.2632, pivotY: 0.05, offsetY: 0.6),
    CharacterAccessory.jungCompass: AccessoryArt._(AccessoryAnchor.body, width: 0.34, aspect: 0.7005, pivotY: 0.04, offsetY: 0.58),
    CharacterAccessory.tempLeaf: AccessoryArt._(AccessoryAnchor.body, width: 0.66, aspect: 1.3287, pivotY: 0.05, offsetY: 0.62),
    CharacterAccessory.attBlanket: AccessoryArt._(AccessoryAnchor.body, width: 0.9, aspect: 1.0909, pivotY: 0.12, offsetY: 0.58),
    // ── Punggung (di belakang badan) ──
    CharacterAccessory.wings: AccessoryArt._(AccessoryAnchor.body, width: 1.55, aspect: 2.6301, offsetY: 0.42),
    CharacterAccessory.backpack: AccessoryArt._(AccessoryAnchor.body, width: 0.46, aspect: 0.8906, offsetX: 0.4, offsetY: 0.55),
    CharacterAccessory.cape: AccessoryArt._(AccessoryAnchor.body, width: 1.2, aspect: 1.4275, pivotY: 0.08, offsetY: 0.42),
    CharacterAccessory.jungLantern: AccessoryArt._(AccessoryAnchor.body, width: 0.24, aspect: 0.4948, pivotY: 0.1, offsetX: 0.62, offsetY: 0.28),
    CharacterAccessory.tempWave: AccessoryArt._(AccessoryAnchor.body, width: 0.7, aspect: 0.875, pivotY: 0.7, offsetX: 0.5, offsetY: 1.0),
    CharacterAccessory.attCompanion: AccessoryArt._(AccessoryAnchor.body, width: 0.34, aspect: 1.1963, pivotY: 0.9, offsetX: -0.66, offsetY: 1.0),
  };
}

/// Titik acuan tempel aksesori 3D pada badan karakter.
enum AccessoryAnchor { headTop, eyes, body }
