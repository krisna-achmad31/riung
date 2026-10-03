import '../../../core/models/personality_result.dart';

/// Satu butir tes. Jawaban = skala setuju 1..[PersonalityConfig.scaleMax].
/// Teks per bahasa ada di `KepribadianStrings.question(id)`.
///
/// [key] = kutub yang didukung bila jawabannya "setuju":
///  - jung: huruf kutub (E/I/S/N/T/F/J/P), [dimension] = "EI"/"SN"/"TF"/"JP"
///  - temperamen: nama temperamen (sanguinis/koleris/melankolis/flegmatis)
///  - keterikatan: "cemas" atau "menghindar"; [reversed] = butir dibalik
///    (setuju = skor rendah pada dimensi itu)
class PersonalityQuestion {
  const PersonalityQuestion(this.id, this.test, this.key, {this.dimension, this.reversed = false});

  final String id;
  final PersonalityTest test;
  final String key;
  final String? dimension;
  final bool reversed;
}

/// Semua angka & pemetaan tes di satu tempat (CLAUDE.md aturan #8: mapping di
/// config, bukan hardcode; tiap persen bisa dihitung ulang dari jawaban).
///
/// CATATAN: tes-tes ini alat REFLEKSI diri, bukan diagnosis. Butirnya asli
/// (ditulis untuk Riung), bukan salinan instrumen berlisensi; "tipe 16 gaya
/// Jung" sengaja tidak memakai nama dagang MBTI®.
abstract final class PersonalityConfig {
  static const int scaleMin = 1;
  static const int scaleMax = 5;
  static const int scaleMid = 3;

  /// Pasangan kutub tiap dimensi jung (urutan = huruf kode). Seri jatuh ke
  /// kutub pertama.
  static const List<String> jungDimensions = ['EI', 'SN', 'TF', 'JP'];

  /// Selisih relatif (poin persen) di bawah ini = temperamen sekunder ikut
  /// ditampilkan sebagai campuran.
  static const int temperamentBlendGapPercent = 8;

  /// Batas skor rata-rata (skala 1..5) antara "rendah" dan "tinggi" pada
  /// kecemasan/penghindaran keterikatan.
  static const double attachmentCutoff = 3.0;

  static const List<String> temperaments = ['sanguinis', 'koleris', 'melankolis', 'flegmatis'];
  static const List<String> attachmentStyles = ['aman', 'cemas', 'menghindar', 'cemas_menghindar'];

  static const List<PersonalityQuestion> jung = [
    // E / I
    PersonalityQuestion('j_ei_1', PersonalityTest.jung, 'E', dimension: 'EI'),
    PersonalityQuestion('j_ei_2', PersonalityTest.jung, 'I', dimension: 'EI'),
    PersonalityQuestion('j_ei_3', PersonalityTest.jung, 'E', dimension: 'EI'),
    PersonalityQuestion('j_ei_4', PersonalityTest.jung, 'I', dimension: 'EI'),
    PersonalityQuestion('j_ei_5', PersonalityTest.jung, 'E', dimension: 'EI'),
    PersonalityQuestion('j_ei_6', PersonalityTest.jung, 'I', dimension: 'EI'),
    // S / N
    PersonalityQuestion('j_sn_1', PersonalityTest.jung, 'S', dimension: 'SN'),
    PersonalityQuestion('j_sn_2', PersonalityTest.jung, 'N', dimension: 'SN'),
    PersonalityQuestion('j_sn_3', PersonalityTest.jung, 'S', dimension: 'SN'),
    PersonalityQuestion('j_sn_4', PersonalityTest.jung, 'N', dimension: 'SN'),
    PersonalityQuestion('j_sn_5', PersonalityTest.jung, 'S', dimension: 'SN'),
    PersonalityQuestion('j_sn_6', PersonalityTest.jung, 'N', dimension: 'SN'),
    // T / F
    PersonalityQuestion('j_tf_1', PersonalityTest.jung, 'T', dimension: 'TF'),
    PersonalityQuestion('j_tf_2', PersonalityTest.jung, 'F', dimension: 'TF'),
    PersonalityQuestion('j_tf_3', PersonalityTest.jung, 'T', dimension: 'TF'),
    PersonalityQuestion('j_tf_4', PersonalityTest.jung, 'F', dimension: 'TF'),
    PersonalityQuestion('j_tf_5', PersonalityTest.jung, 'T', dimension: 'TF'),
    PersonalityQuestion('j_tf_6', PersonalityTest.jung, 'F', dimension: 'TF'),
    // J / P
    PersonalityQuestion('j_jp_1', PersonalityTest.jung, 'J', dimension: 'JP'),
    PersonalityQuestion('j_jp_2', PersonalityTest.jung, 'P', dimension: 'JP'),
    PersonalityQuestion('j_jp_3', PersonalityTest.jung, 'J', dimension: 'JP'),
    PersonalityQuestion('j_jp_4', PersonalityTest.jung, 'P', dimension: 'JP'),
    PersonalityQuestion('j_jp_5', PersonalityTest.jung, 'J', dimension: 'JP'),
    PersonalityQuestion('j_jp_6', PersonalityTest.jung, 'P', dimension: 'JP'),
  ];

  static const List<PersonalityQuestion> temperament = [
    PersonalityQuestion('t_san_1', PersonalityTest.temperament, 'sanguinis'),
    PersonalityQuestion('t_kol_1', PersonalityTest.temperament, 'koleris'),
    PersonalityQuestion('t_mel_1', PersonalityTest.temperament, 'melankolis'),
    PersonalityQuestion('t_fle_1', PersonalityTest.temperament, 'flegmatis'),
    PersonalityQuestion('t_san_2', PersonalityTest.temperament, 'sanguinis'),
    PersonalityQuestion('t_kol_2', PersonalityTest.temperament, 'koleris'),
    PersonalityQuestion('t_mel_2', PersonalityTest.temperament, 'melankolis'),
    PersonalityQuestion('t_fle_2', PersonalityTest.temperament, 'flegmatis'),
    PersonalityQuestion('t_san_3', PersonalityTest.temperament, 'sanguinis'),
    PersonalityQuestion('t_kol_3', PersonalityTest.temperament, 'koleris'),
    PersonalityQuestion('t_mel_3', PersonalityTest.temperament, 'melankolis'),
    PersonalityQuestion('t_fle_3', PersonalityTest.temperament, 'flegmatis'),
    PersonalityQuestion('t_san_4', PersonalityTest.temperament, 'sanguinis'),
    PersonalityQuestion('t_kol_4', PersonalityTest.temperament, 'koleris'),
    PersonalityQuestion('t_mel_4', PersonalityTest.temperament, 'melankolis'),
    PersonalityQuestion('t_fle_4', PersonalityTest.temperament, 'flegmatis'),
    PersonalityQuestion('t_san_5', PersonalityTest.temperament, 'sanguinis'),
    PersonalityQuestion('t_kol_5', PersonalityTest.temperament, 'koleris'),
    PersonalityQuestion('t_mel_5', PersonalityTest.temperament, 'melankolis'),
    PersonalityQuestion('t_fle_5', PersonalityTest.temperament, 'flegmatis'),
  ];

  static const List<PersonalityQuestion> attachment = [
    PersonalityQuestion('a_cemas_1', PersonalityTest.attachment, 'cemas'),
    PersonalityQuestion('a_hindar_1', PersonalityTest.attachment, 'menghindar'),
    PersonalityQuestion('a_cemas_2', PersonalityTest.attachment, 'cemas'),
    PersonalityQuestion('a_hindar_2', PersonalityTest.attachment, 'menghindar'),
    PersonalityQuestion('a_cemas_3', PersonalityTest.attachment, 'cemas'),
    PersonalityQuestion('a_hindar_3', PersonalityTest.attachment, 'menghindar'),
    PersonalityQuestion('a_cemas_4', PersonalityTest.attachment, 'cemas'),
    PersonalityQuestion('a_hindar_4', PersonalityTest.attachment, 'menghindar', reversed: true),
    PersonalityQuestion('a_cemas_5', PersonalityTest.attachment, 'cemas', reversed: true),
    PersonalityQuestion('a_hindar_5', PersonalityTest.attachment, 'menghindar'),
    PersonalityQuestion('a_cemas_6', PersonalityTest.attachment, 'cemas'),
    PersonalityQuestion('a_hindar_6', PersonalityTest.attachment, 'menghindar', reversed: true),
  ];

  static List<PersonalityQuestion> questionsFor(PersonalityTest test) {
    switch (test) {
      case PersonalityTest.jung:
        return jung;
      case PersonalityTest.temperament:
        return temperament;
      case PersonalityTest.attachment:
        return attachment;
    }
  }
}
