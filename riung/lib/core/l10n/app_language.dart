/// Bahasa yang didukung app. Tambah bahasa baru = tambah nilai enum ini,
/// lalu implementasikan tiap class strings di `l10n/strings/` untuk bahasa
/// itu (kompiler memaksa semuanya lengkap, lihat [AppStrings]).
enum AppLanguage {
  indonesia('id', 'Bahasa Indonesia', 'id_ID'),
  english('en', 'English', 'en_US');

  const AppLanguage(this.code, this.nativeName, this.intlLocale);

  /// Kode ISO 639-1 — disimpan di prefs & dipakai sebagai `Locale`.
  final String code;

  /// Nama bahasa dalam bahasanya sendiri (sengaja TIDAK diterjemahkan, supaya
  /// pengguna yang nyasar ke bahasa asing tetap bisa menemukan bahasanya).
  final String nativeName;

  /// Locale untuk `intl` (`DateFormat`, dsb).
  final String intlLocale;

  static const AppLanguage defaultLanguage = AppLanguage.indonesia;

  static AppLanguage fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return defaultLanguage;
  }
}
