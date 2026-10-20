import 'package:flutter/services.dart';

/// Batas panjang teks bebas — satu-satunya sumber angka ini (CLAUDE.md #3
/// berlaku juga untuk batas input). Nama mengikuti kontrak server
/// (`PATCH /v1/me/profile`: displayName ≤ 40).
///
/// Dipasang lewat `inputFormatters` (bukan `maxLength`) supaya tidak muncul
/// penghitung karakter yang tidak ada di desain.
class InputLimits {
  InputLimits._();

  static const nama = 40;
  static const jurnal = 5000;
  static const onboardingCerita = 1000;
  static const checkinCatatan = 500;
  static const afirmasi = 140;
  static const refleksiBetterMe = 2000;

  /// Formatter standar: buang karakter kontrol & penanda arah teks
  /// tersembunyi (U+202A–202E, U+2066–2069 — bisa dipakai menyamarkan
  /// teks), buang baris baru bila [multiline] false, lalu potong ke [max].
  /// Teks tidak pernah dirender sebagai HTML, jadi tidak perlu escape.
  static List<TextInputFormatter> formatters(int max, {bool multiline = true}) => [
        FilteringTextInputFormatter.deny(multiline ? _unsafeMultiline : _unsafeSingleLine),
        LengthLimitingTextInputFormatter(max),
      ];

  /// Untuk teks yang masuk dari luar keyboard (draft lama, tempel lewat
  /// kode): terapkan aturan yang sama lalu rapikan spasi tepi.
  static String sanitize(String text, int max, {bool multiline = true}) {
    final cleaned = text.replaceAll(multiline ? _unsafeMultiline : _unsafeSingleLine, '').trim();
    final runes = cleaned.runes;
    return runes.length <= max ? cleaned : String.fromCharCodes(runes.take(max)).trim();
  }

  static final _unsafeMultiline = RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F\u202A-\u202E\u2066-\u2069]');
  static final _unsafeSingleLine = RegExp('[\u0000-\u001F\u007F\u202A-\u202E\u2066-\u2069]');
}
