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
    'aman': CharacterArt._('aman', left: 0.063, top: 0.272, right: 0.933, bottom: 0.948, eyeX: 0.505, eyeY: 0.504, eyeDx: 0.144),
    'ENFJ': CharacterArt._('enfj', left: 0.072, top: 0.292, right: 0.924, bottom: 0.944, eyeX: 0.463, eyeY: 0.56, eyeDx: 0.104),
    'ENFP': CharacterArt._('enfp', left: 0.109, top: 0.312, right: 0.888, bottom: 0.947, eyeX: 0.488, eyeY: 0.497, eyeDx: 0.117),
    'ENTJ': CharacterArt._('entj', left: 0.083, top: 0.284, right: 0.914, bottom: 0.951, eyeX: 0.492, eyeY: 0.483, eyeDx: 0.131),
    'ENTP': CharacterArt._('entp', left: 0.113, top: 0.325, right: 0.884, bottom: 0.952, eyeX: 0.499, eyeY: 0.517, eyeDx: 0.11),
    'ESFJ': CharacterArt._('esfj', left: 0.07, top: 0.237, right: 0.925, bottom: 0.95, eyeX: 0.48, eyeY: 0.459, eyeDx: 0.158),
    'ESFP': CharacterArt._('esfp', left: 0.062, top: 0.287, right: 0.934, bottom: 0.958, eyeX: 0.502, eyeY: 0.51, eyeDx: 0.14),
    'ESTJ': CharacterArt._('estj', left: 0.061, top: 0.253, right: 0.933, bottom: 0.952, eyeX: 0.49, eyeY: 0.51, eyeDx: 0.13),
    'ESTP': CharacterArt._('estp', left: 0.085, top: 0.246, right: 0.935, bottom: 0.962, eyeX: 0.502, eyeY: 0.506, eyeDx: 0.127),
    'INFJ': CharacterArt._('infj', left: 0.133, top: 0.289, right: 0.864, bottom: 0.946, eyeX: 0.487, eyeY: 0.5, eyeDx: 0.113),
    'INFP': CharacterArt._('infp', left: 0.191, top: 0.282, right: 0.807, bottom: 0.947, eyeX: 0.503, eyeY: 0.487, eyeDx: 0.091),
    'INTJ': CharacterArt._('intj', left: 0.174, top: 0.269, right: 0.823, bottom: 0.953, eyeX: 0.498, eyeY: 0.501, eyeDx: 0.109),
    'INTP': CharacterArt._('intp', left: 0.185, top: 0.29, right: 0.811, bottom: 0.95, eyeX: 0.489, eyeY: 0.497, eyeDx: 0.101),
    'ISFJ': CharacterArt._('isfj', left: 0.191, top: 0.225, right: 0.803, bottom: 0.952, eyeX: 0.49, eyeY: 0.478, eyeDx: 0.116),
    'ISFP': CharacterArt._('isfp', left: 0.076, top: 0.229, right: 0.845, bottom: 0.967, eyeX: 0.495, eyeY: 0.51, eyeDx: 0.126),
    'ISTJ': CharacterArt._('istj', left: 0.196, top: 0.233, right: 0.8, bottom: 0.948, eyeX: 0.501, eyeY: 0.43, eyeDx: 0.099),
    'ISTP': CharacterArt._('istp', left: 0.143, top: 0.231, right: 0.853, bottom: 0.958, eyeX: 0.503, eyeY: 0.425, eyeDx: 0.097),
    'cemas': CharacterArt._('cemas', left: 0.097, top: 0.126, right: 0.901, bottom: 0.948, eyeX: 0.498, eyeY: 0.356, eyeDx: 0.107),
    'cemas_menghindar': CharacterArt._('cemas_menghindar', left: 0.088, top: 0.082, right: 0.912, bottom: 0.959, eyeX: 0.503, eyeY: 0.369, eyeDx: 0.134),
    'flegmatis': CharacterArt._('flegmatis', left: 0.061, top: 0.274, right: 0.933, bottom: 0.958, eyeX: 0.504, eyeY: 0.504, eyeDx: 0.165),
    'koleris': CharacterArt._('koleris', left: 0.061, top: 0.226, right: 0.932, bottom: 0.962, eyeX: 0.501, eyeY: 0.439, eyeDx: 0.153),
    'melankolis': CharacterArt._('melankolis', left: 0.217, top: 0.238, right: 0.783, bottom: 0.959, eyeX: 0.501, eyeY: 0.494, eyeDx: 0.098),
    'menghindar': CharacterArt._('menghindar', left: 0.066, top: 0.082, right: 0.932, bottom: 0.959, eyeX: 0.498, eyeY: 0.487, eyeDx: 0.153),
    'sanguinis': CharacterArt._('sanguinis', left: 0.061, top: 0.277, right: 0.945, bottom: 0.956, eyeX: 0.508, eyeY: 0.483, eyeDx: 0.146),
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
    CharacterAccessory.beanie: AccessoryArt._(AccessoryAnchor.headTop, width: 0.78, aspect: 0.9375, pivotY: 0.82, offsetY: 0.12),
    CharacterAccessory.ribbon: AccessoryArt._(AccessoryAnchor.headTop, width: 0.42, aspect: 1.3913, offsetX: -0.26, offsetY: 0.06),
    CharacterAccessory.flower: AccessoryArt._(AccessoryAnchor.headTop, width: 0.36, aspect: 1.259, offsetX: 0.26, offsetY: 0.07),
    CharacterAccessory.witchHat: AccessoryArt._(AccessoryAnchor.headTop, width: 0.95, aspect: 1.2347, pivotY: 0.86, offsetY: 0.1),
    CharacterAccessory.headphones: AccessoryArt._(AccessoryAnchor.eyes, width: 1.12, aspect: 1.0132, pivotY: 0.64),
    CharacterAccessory.halo: AccessoryArt._(AccessoryAnchor.headTop, width: 0.56, aspect: 3.84, pivotY: 0.5, offsetY: -0.07),
    CharacterAccessory.jungCrown: AccessoryArt._(AccessoryAnchor.headTop, width: 0.72, aspect: 1.6696, pivotY: 0.75, offsetY: 0.02),
    CharacterAccessory.tempFlame: AccessoryArt._(AccessoryAnchor.headTop, width: 0.3, aspect: 0.7891, pivotY: 0.95, offsetY: 0.05),
    CharacterAccessory.attNightCap: AccessoryArt._(AccessoryAnchor.headTop, width: 0.92, aspect: 1.6991, pivotY: 0.8, offsetY: 0.14),
    // ── Wajah ──
    CharacterAccessory.roundGlasses: AccessoryArt._(AccessoryAnchor.eyes, width: 4.2, aspect: 2.5772, eyeScaled: true),
    CharacterAccessory.sunglasses: AccessoryArt._(AccessoryAnchor.eyes, width: 4.4, aspect: 2.6122, eyeScaled: true),
    CharacterAccessory.starStickers: AccessoryArt._(AccessoryAnchor.eyes, width: 3.6, aspect: 2.3133, offsetY: 0.13, eyeScaled: true),
    CharacterAccessory.jungMask: AccessoryArt._(AccessoryAnchor.eyes, width: 4.4, aspect: 2.2197, eyeScaled: true),
    CharacterAccessory.tempMonocle: AccessoryArt._(AccessoryAnchor.eyes, width: 2.3, aspect: 0.9531, pivotX: 0.42, pivotY: 0.36, offsetX: 1.0, eyeScaled: true),
    CharacterAccessory.attHeartCharm: AccessoryArt._(AccessoryAnchor.eyes, width: 1.0, aspect: 0.4896, offsetX: 2.4, offsetY: -0.02, eyeScaled: true),
    // ── Leher ──
    CharacterAccessory.scarf: AccessoryArt._(AccessoryAnchor.eyes, width: 0.56, aspect: 0.888, pivotY: 0.1, offsetY: 0.26),
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
