import 'package:flutter/widgets.dart';

/// Token warna Riung — **Riung Glass 2026** (variabel `g-*` di
/// `design/riung.pen`): tema terang pastel kalem, kartu kaca di atas latar
/// gradien kabut. Ini satu-satunya sumber warna untuk seluruh app — jangan
/// menulis hex literal di file layar/widget lain.
///
/// Nama token lama (latar, kartu, primer, …) dipertahankan supaya semua
/// layar ikut termigrasi; nilainya kini memetakan palet kaca.
abstract final class AppColors {
  // Inti / netral
  /// Latar dasar (g-bg). Juga dipakai sebagai warna teks/ikon di atas primer.
  static const Color latar = Color(0xFFF3F1EC);

  /// Permukaan kaca kuat (g-glass-strong) — sheet, nav, input.
  static const Color permukaan = Color(0xC7FFFFFF);

  /// Kartu kaca (g-glass).
  static const Color kartu = Color(0x8CFFFFFF);

  /// Tepi kaca (g-glass-edge) — border kartu & pemisah.
  static const Color garis = Color(0xE6FFFFFF);

  /// Kaca tab bar mengambang (`Tab Bar Kaca`, putih 65%).
  static const Color kacaNav = Color(0xA6FFFFFF);

  /// Permukaan padat untuk dialog/bottom sheet (tidak tembus pandang).
  static const Color permukaanPadat = Color(0xFFFBFAF7);

  // Brand & aksen
  static const Color primer = Color(0xFF3E6B63);
  static const Color primerGelap = Color(0xFF2F5650);
  static const Color primerLembut = Color(0xFFCFE3DB);
  static const Color sekunder = Color(0xFF6F67B0);
  static const Color sekunderLembut = Color(0xFFE6E2F6);
  static const Color sekunderGelap = Color(0xFF5D4FA8);
  static const Color sekunderPucat = Color(0xFFECE6FA);
  static const Color sekunderMuda = Color(0xFFD8CFF3);
  // Gradien ikon app "R" (frame `App ikon`).
  static const Color primerTerang = Color(0xFF9DC2AE);
  static const Color sekunderTerang = Color(0xFF8E86C8);
  static const Color aksenHangat = Color(0xFFC97B5C);
  static const Color aksenHangatLembut = Color(0xFFF8E2D7);
  static const Color aksenHangatMuda = Color(0xFFF5D2C2);

  /// Persik tua — teks label di atas kaca (mis. "LEVEL 2" node aktif).
  static const Color aksenHangatGelap = Color(0xFFB76E52);
  static const Color langit = Color(0xFF7FA3C9);
  static const Color langitMuda = Color(0xFF9FC1E3);
  static const Color langitGelap = Color(0xFF4F77A3);

  // Tile aplikasi Aplikasi Beku (frame `App …` di Glass — Aplikasi Beku).
  static const Color appInstagramAwal = Color(0xFFF2B38F);
  static const Color appInstagramAkhir = Color(0xFFC98BC4);
  static const Color appTiktok = Color(0xFF3A3F4A);
  static const Color appYoutube = Color(0xFFE59A93);
  static const Color appX = Color(0xFF5C6470);
  static const Color appWhatsapp = Color(0xFF8FC7A5);
  static const Color langitLembut = Color(0xFFDCE7F4);
  static const Color emas = Color(0xFFD9AE5F);
  static const Color emasMuda = Color(0xFFF8E3A8);
  static const Color emasLembut = Color(0xFFF6E7C8);
  static const Color emasTua = Color(0xFFC99A4A);
  static const Color emasGelap = Color(0xFFA97E35);

  // Teks
  static const Color teksUtama = Color(0xFF1F2A2C);
  static const Color teksSekunder = Color(0xFF5A6668);
  static const Color teksRedup = Color(0xFF8A9795);

  /// Tinta (g-ink) — isi tombol utama.
  static const Color tinta = Color(0xFF1F2A2C);
  static const Color diAtasTinta = Color(0xFFFFFFFF);

  // Semantik
  static const Color sukses = Color(0xFF4E8F6A);
  static const Color peringatan = Color(0xFFB8862F);
  static const Color error = Color(0xFFC25A5A);
  static const Color info = Color(0xFF3E6B63);

  // Kaca
  static const Color bayangan = Color(0x1F3E5A5A);
  static const Color bayanganTinta = Color(0x331F2A2C);

  /// Bayangan lantai di bawah art 3D monster/karakter.
  static const Color bayanganLantai = Color(0x403E5A5A);

  /// Titik gradien kabut latar (mesh 3×3 di desain), atas → bawah.
  static const Color kabutSage = Color(0xFFD5E6DA);
  static const Color kabutBiru = Color(0xFFD9E4F2);
  static const Color kabutLavender = Color(0xFFE4DEF3);
  static const Color kabutPersik = Color(0xFFF7E4D8);

  /// Kartu tiket serangan bos: gradien ungu malam → primer + cahaya lavender.
  static const Color tiketAwal = Color(0xFF5D5A8C);
  static const Color tiketCahaya = Color(0x66B9A8F5);


  // Warna khas monster (7 saboteur) — versi pastel kalem yang serasi art 3D.
  static const Color monsterMeronta = Color(0xFF7487B0);
  static const Color monsterWaswas = Color(0xFFD9A04E);
  static const Color monsterKabut = Color(0xFF8E98AE);
  static const Color monsterCermin = Color(0xFFA08BCF);
  static const Color monsterSempurna = Color(0xFFE07C74);
  static const Color monsterMengelak = Color(0xFF5FA596);
  static const Color monsterHakim = Color(0xFF8B6FD6);

  /// Latar pastel lembut per monster (thumbnail deck, kartu monster).
  static const Map<String, Color> monsterLembut = {
    'meronta': langitLembut,
    'waswas': aksenHangatLembut,
    'kabut': langitLembut,
    'cermin': kabutLavender,
    'sempurna': aksenHangatLembut,
    'mengelak': primerLembut,
    'hakim': sekunderLembut,
  };

  /// Netral hangat lembut (orb mood "datar").
  static const Color netralLembut = Color(0xFFEDEBE6);

  /// Latar orb per mood check-in (berat → senang).
  static const Map<String, Color> moodLembut = {
    'berat': kabutLavender,
    'agak_berat': langitLembut,
    'datar': netralLembut,
    'cukup_baik': kabutSage,
    'senang': aksenHangatLembut,
  };

  static const Map<String, Color> monsterColors = {
    'meronta': monsterMeronta,
    'waswas': monsterWaswas,
    'kabut': monsterKabut,
    'cermin': monsterCermin,
    'sempurna': monsterSempurna,
    'mengelak': monsterMengelak,
    'hakim': monsterHakim,
  };
}
