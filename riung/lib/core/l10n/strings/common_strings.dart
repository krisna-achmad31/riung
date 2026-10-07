import 'package:intl/intl.dart';

/// Teks yang dipakai berulang di banyak layar (tombol umum, status umum).
/// Teks khusus satu fitur ada di class strings fitur itu.
abstract class CommonStrings {
  const CommonStrings();

  String get batal;
  String get simpan;
  String get lanjut;
  String get kembali;
  String get tutup;
  String get oke;
  String get ya;
  String get tidak;
  String get hapus;
  String get selesai;
  String get cobaLagi;
  String get memproses;
  String get nantiSaja;
  String get keluar;
  String get languageTitle;
  String get languageSheetTitle;
  String get navHome;
  String get navExplore;
  String get navFocus;
  String get navMonster;
  String get navProfile;

  // ── Komponen bersama ──
  String tickets(int count);
  String daysCount(int days);
  String get loadFailed;
  String get offlineBanner;
  String get didYouKnow;
  String premiumLockedBody(String freeTierNote);
  String premiumPriceLine(int monthlyPrice, int trialDays);
  String get seePremium;
  String get skipForNow;

  /// Nama tampil monster. Nama karakter sengaja sama di semua bahasa
  /// (bukan terjemahan) — dipusatkan di sini supaya kalau nanti mau
  /// diterjemahkan cukup override di satu tempat.
  String monsterName(String id) => _monsterNames[id] ?? id;

  static const Map<String, String> _monsterNames = {
    'meronta': 'Si Meronta',
    'waswas': 'Si Waswas',
    'kabut': 'Si Kabut',
    'cermin': 'Si Cermin',
    'sempurna': 'Si Sempurna',
    'mengelak': 'Si Mengelak',
    'hakim': 'Si Hakim',
    'nanti': 'Si Nanti',
    'gulir': 'Si Gulir',
    'begadang': 'Si Begadang',
    'bunglon': 'Si Bunglon',
    'bimbang': 'Si Bimbang',
    'bara': 'Si Bara',
  };
}

class CommonStringsId extends CommonStrings {
  const CommonStringsId();

  @override
  String get batal => 'Batal';
  @override
  String get simpan => 'Simpan';
  @override
  String get lanjut => 'Lanjut';
  @override
  String get kembali => 'Kembali';
  @override
  String get tutup => 'Tutup';
  @override
  String get oke => 'Oke';
  @override
  String get ya => 'Ya';
  @override
  String get tidak => 'Tidak';
  @override
  String get hapus => 'Hapus';
  @override
  String get selesai => 'Selesai';
  @override
  String get cobaLagi => 'Coba lagi';
  @override
  String get memproses => 'Memproses…';
  @override
  String get nantiSaja => 'Nanti saja';
  @override
  String get keluar => 'Keluar';
  @override
  String get languageTitle => 'Bahasa';
  @override
  String get languageSheetTitle => 'Pilih bahasa';
  @override
  String get navHome => 'Beranda';
  @override
  String get navExplore => 'Jelajah';
  @override
  String get navFocus => 'Fokus';
  @override
  String get navMonster => 'Monster';
  @override
  String get navProfile => 'Profil';

  @override
  String tickets(int count) => '$count tiket';
  @override
  String daysCount(int days) => '$days hari';
  @override
  String get loadFailed => 'Gagal memuat. Cek koneksi internetmu.';
  @override
  String get offlineBanner => 'Kamu lagi offline — jurnal & check-in tetap tersimpan di perangkat';
  @override
  String get didYouKnow => 'Tahukah kamu?';
  @override
  String premiumLockedBody(String freeTierNote) => 'Konten ini bagian dari Riung Premium. $freeTierNote';
  @override
  String premiumPriceLine(int monthlyPrice, int trialDays) => 'Rp${_rupiah(monthlyPrice)}/bln · trial $trialDays hari gratis';
  @override
  String get seePremium => 'Lihat Riung Premium';
  @override
  String get skipForNow => 'Lewati dulu';
}

class CommonStringsEn extends CommonStrings {
  const CommonStringsEn();

  @override
  String get batal => 'Cancel';
  @override
  String get simpan => 'Save';
  @override
  String get lanjut => 'Continue';
  @override
  String get kembali => 'Back';
  @override
  String get tutup => 'Close';
  @override
  String get oke => 'Okay';
  @override
  String get ya => 'Yes';
  @override
  String get tidak => 'No';
  @override
  String get hapus => 'Delete';
  @override
  String get selesai => 'Done';
  @override
  String get cobaLagi => 'Try again';
  @override
  String get memproses => 'Processing…';
  @override
  String get nantiSaja => 'Maybe later';
  @override
  String get keluar => 'Exit';
  @override
  String get languageTitle => 'Language';
  @override
  String get languageSheetTitle => 'Choose language';
  @override
  String get navHome => 'Home';
  @override
  String get navExplore => 'Explore';
  @override
  String get navFocus => 'Focus';
  @override
  String get navMonster => 'Monsters';
  @override
  String get navProfile => 'Profile';

  @override
  String tickets(int count) => count == 1 ? '1 ticket' : '$count tickets';
  @override
  String daysCount(int days) => days == 1 ? '1 day' : '$days days';
  @override
  String get loadFailed => 'Failed to load. Check your internet connection.';
  @override
  String get offlineBanner => "You're offline — journal & check-ins are still saved on your device";
  @override
  String get didYouKnow => 'Did you know?';
  @override
  String premiumLockedBody(String freeTierNote) => 'This content is part of Riung Premium. $freeTierNote';
  @override
  String premiumPriceLine(int monthlyPrice, int trialDays) => 'Rp${_rupiah(monthlyPrice)}/mo · $trialDays-day free trial';
  @override
  String get seePremium => 'See Riung Premium';
  @override
  String get skipForNow => 'Skip for now';
}

/// Format rupiah dengan pemisah ribuan titik (59000 → 59.000).
String _rupiah(int amount) => NumberFormat.decimalPattern('id_ID').format(amount);
