import 'package:flutter/painting.dart';

import '../../../core/models/personality_result.dart';
import '../../../core/theme/theme.dart';

/// Hiasan di atas kepala.
enum CharacterTop { none, sprout, star }

/// Wajah: kacamata (berpikir), pipi hati (merasa), pipi merona, polos.
enum CharacterFace { plain, glasses, hearts, blush }

/// Aksesori tambahan.
enum CharacterExtra { none, bowtie, tuft, crown, sparks, tremble, shell, split }

/// Resep gambar satu karakter — semua warna dari token tema.
/// Dipetakan dari hasil tes: 16 tipe → kombinasi 4 huruf, temperamen &
/// keterikatan → karakter khusus. Hasil yang sama selalu memberi karakter
/// yang sama.
class CharacterSpec {
  const CharacterSpec({
    required this.base,
    required this.accent,
    this.wide = false,
    this.top = CharacterTop.none,
    this.face = CharacterFace.plain,
    this.extra = CharacterExtra.none,
    this.artKey = '',
  });

  final Color base;
  final Color accent;

  /// Ekstrovert: badan lebih lebar & senyum lebar. Introvert: lebih tinggi & senyum kecil.
  final bool wide;
  final CharacterTop top;
  final CharacterFace face;
  final CharacterExtra extra;

  /// Kunci art 3D di `CharacterArt` (kode tipe jung, kunci temperamen,
  /// atau kunci keterikatan). Kosong = digambar prosedural.
  final String artKey;

  /// Karakter untuk kode tipe jung 4 huruf (mis. "INFP").
  factory CharacterSpec.jung(String code) {
    final c = code.length == 4 ? code : 'ISFJ';
    final sn = c[1];
    final tf = c[2];
    // Kelompok warna: intuitif-perasa = ungu, intuitif-pemikir = biru,
    // realis-terencana = hijau, realis-spontan = jingga.
    final Color base;
    final Color accent;
    if (sn == 'N' && tf == 'F') {
      base = AppColors.monsterHakim;
      accent = AppColors.monsterCermin;
    } else if (sn == 'N') {
      base = AppColors.primer;
      accent = AppColors.sekunder;
    } else if (c[3] == 'J') {
      base = AppColors.sukses;
      accent = AppColors.sekunder;
    } else {
      base = AppColors.aksenHangat;
      accent = AppColors.peringatan;
    }
    return CharacterSpec(
      base: base,
      accent: accent,
      wide: c[0] == 'E',
      top: sn == 'S' ? CharacterTop.sprout : CharacterTop.star,
      face: tf == 'T' ? CharacterFace.glasses : CharacterFace.hearts,
      extra: c[3] == 'J' ? CharacterExtra.bowtie : CharacterExtra.tuft,
      artKey: c,
    );
  }

  factory CharacterSpec.temperament(String key) {
    switch (key) {
      case 'sanguinis':
        return const CharacterSpec(base: AppColors.peringatan, accent: AppColors.aksenHangat, wide: true, face: CharacterFace.blush, extra: CharacterExtra.sparks, artKey: 'sanguinis');
      case 'koleris':
        return const CharacterSpec(base: AppColors.error, accent: AppColors.aksenHangat, wide: true, face: CharacterFace.plain, extra: CharacterExtra.crown, artKey: 'koleris');
      case 'melankolis':
        return const CharacterSpec(base: AppColors.monsterMeronta, accent: AppColors.primer, top: CharacterTop.star, face: CharacterFace.glasses, artKey: 'melankolis');
      default:
        return const CharacterSpec(base: AppColors.sekunder, accent: AppColors.sukses, wide: true, top: CharacterTop.sprout, face: CharacterFace.blush, artKey: 'flegmatis');
    }
  }

  factory CharacterSpec.attachment(String key) {
    switch (key) {
      case 'aman':
        return const CharacterSpec(base: AppColors.sukses, accent: AppColors.sekunder, wide: true, face: CharacterFace.hearts, extra: CharacterExtra.sparks, artKey: 'aman');
      case 'cemas':
        return const CharacterSpec(base: AppColors.monsterCermin, accent: AppColors.primer, face: CharacterFace.blush, extra: CharacterExtra.tremble, artKey: 'cemas');
      case 'menghindar':
        return const CharacterSpec(base: AppColors.monsterKabut, accent: AppColors.teksRedup, face: CharacterFace.plain, extra: CharacterExtra.shell, artKey: 'menghindar');
      default:
        return const CharacterSpec(base: AppColors.monsterSempurna, accent: AppColors.monsterKabut, face: CharacterFace.blush, extra: CharacterExtra.split, artKey: 'cemas_menghindar');
    }
  }

  factory CharacterSpec.fromResult(PersonalityResult result) {
    switch (result.test) {
      case PersonalityTest.jung:
        return CharacterSpec.jung(result.code);
      case PersonalityTest.temperament:
        return CharacterSpec.temperament(result.code);
      case PersonalityTest.attachment:
        return CharacterSpec.attachment(result.code);
    }
  }
}
