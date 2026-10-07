import 'package:flutter/material.dart';

/// Token varian **malam** Riung Glass (frame `Glass — Tidur …` di
/// `design/riung.pen`): latar gradien biru-ungu tua, kaca putih tipis,
/// teks terang, aksen lavender. Dipakai khusus alur Tidur.
abstract final class AppNight {
  static const Color latarAtas = Color(0xFF2F3A5C);
  static const Color latarTengah = Color(0xFF2C3654);
  static const Color latarBawah = Color(0xFF1F2B3E);
  static const Color latarUngu = Color(0xFF3B3866);

  static const Color teks = Color(0xFFF1F0F8);
  static const Color teksSekunder = Color(0xFFC9C8DA);
  static const Color teksRedup = Color(0xFF9C9BB5);

  /// Aksen lavender (eyebrow, ikon aktif).
  static const Color aksen = Color(0xFFB9B1E6);
  static const Color aksenLembut = Color(0x33B9B1E6);

  /// Kaca tipis, kaca sedikit lebih kuat, isi pil, tepi kaca.
  static const Color kaca = Color(0x14FFFFFF);
  static const Color kacaKuat = Color(0x1AFFFFFF);
  static const Color pil = Color(0x1FFFFFFF);
  static const Color tepi = Color(0x2EFFFFFF);

  /// Cahaya bulan & sorotan kartu.
  static const Color cahayaBulan = Color(0x40B9B1E6);
  static const Color cahayaKartu = Color(0x559FB4E6);
  static const Color bintang = Color(0xCCFFFFFF);

  /// Palet balok "vonis" di arena Pecahkan balok (lavender, langit, persik,
  /// sage, emas) + teks gelap di atasnya.
  static const List<Color> balok = [Color(0xCCB9B1E6), Color(0xCC9FB4E6), Color(0xCCE8A58A), Color(0xCC9DC2AE), Color(0xCCD9AE5F)];
  static const Color teksBalok = Color(0xFF1E2640);
  static const Color nyawa = Color(0xFFE8A58A);

  static const LinearGradient backdrop = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [latarAtas, latarTengah, latarUngu, latarBawah],
    stops: [0, 0.4, 0.6, 1],
  );

  static const LinearGradient thumb = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [latarUngu, Color(0xFF5D6A9C)],
  );

  static BoxDecoration card({double radius = 22, Color color = kaca}) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tepi, width: 1.5),
      );
}
