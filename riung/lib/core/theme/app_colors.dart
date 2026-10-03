import 'package:flutter/widgets.dart';

/// Token warna Riung — di-port 1:1 dari `design/Design System.dc.html` (§01 · Warna).
/// Tema gelap "Twilight Calm". Ini satu-satunya sumber warna untuk seluruh app —
/// jangan menulis hex literal di file layar/widget lain.
abstract final class AppColors {
  // Inti / netral
  static const Color latar = Color(0xFF0D1030);
  static const Color permukaan = Color(0xFF151A3A);
  static const Color kartu = Color(0xFF1E2450);
  static const Color garis = Color(0xFF2A3160);

  // Brand & aksen
  static const Color primer = Color(0xFF7C8CFF);
  static const Color primerGelap = Color(0xFF5A66D9);
  static const Color sekunder = Color(0xFF4FD1C5);
  static const Color aksenHangat = Color(0xFFFFB877);

  // Teks
  static const Color teksUtama = Color(0xFFF4F6FF);
  static const Color teksSekunder = Color(0xFFB4BAE0);
  static const Color teksRedup = Color(0xFF7E85B0);

  // Semantik
  static const Color sukses = Color(0xFF5FD08A);
  static const Color peringatan = Color(0xFFFFCE73);
  static const Color error = Color(0xFFF27C86);
  static const Color info = Color(0xFF7C8CFF);

  // Warna khas monster (7 saboteur)
  static const Color monsterMeronta = Color(0xFF6E7BA6);
  static const Color monsterWaswas = Color(0xFFE8A94E);
  static const Color monsterKabut = Color(0xFF9AA2B8);
  static const Color monsterCermin = Color(0xFFB39DDB);
  static const Color monsterSempurna = Color(0xFFF2766F);
  static const Color monsterMengelak = Color(0xFF5FB0A0);
  static const Color monsterHakim = Color(0xFF8B5CF6);

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
