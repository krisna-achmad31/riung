import '../app_language.dart';
import '../app_strings.dart';

extension JournalBackupLocalization on AppStrings {
  JournalBackupStrings get journalBackup =>
      JournalBackupStrings(language == AppLanguage.indonesia);
}

class JournalBackupStrings {
  const JournalBackupStrings(this._id);

  final bool _id;

  String get screenTitle => _id ? 'Cadangan jurnal' : 'Journal backup';

  String get localUnbacked => _id
      ? 'Tersimpan di HP ini · Belum dicadangkan'
      : 'Stored on this device · No backup yet';

  String get title =>
      _id ? 'Cadangkan & pulihkan jurnal' : 'Back up & restore journal';
  String get localOnly =>
      _id ? 'Jurnal tersimpan di HP ini' : 'Journal stored on this device';
  String get neverSaved => _id
      ? 'Belum ada cadangan tercatat di HP ini'
      : 'No backup recorded on this device';
  String lastSaved(String date) =>
      _id ? 'Cadangan terakhir $date' : 'Last backup $date';
  String get intro => _id
      ? 'Untuk pindah HP, simpan file cadangan di lokasi yang bisa kamu akses dari HP baru. Kamu perlu file dan kata sandinya untuk memulihkan jurnal.'
      : 'To move devices, save the backup file somewhere you can access from your new device. You’ll need both the file and its password to restore your journal.';
  String get backup => _id ? 'Buat cadangan' : 'Create backup';
  String get restore => _id ? 'Pulihkan dari file' : 'Restore from file';
  String get password => _id ? 'Kata sandi cadangan' : 'Backup password';
  String get confirmPassword => _id ? 'Ulangi kata sandi' : 'Confirm password';
  String get showPassword => _id ? 'Tampilkan kata sandi' : 'Show password';
  String get hidePassword => _id ? 'Sembunyikan kata sandi' : 'Hide password';
  String get passwordHint => _id
      ? 'Minimal 6 karakter, dengan huruf kecil, huruf besar, angka, dan simbol. Simpan kata sandi ini untuk pemulihan.'
      : 'Use at least 6 characters, including a lowercase letter, an uppercase letter, a number, and a symbol. Keep this password for recovery.';
  String get passwordMismatch =>
      _id ? 'Kata sandinya berbeda.' : 'The passwords differ.';
  String get passwordRequired =>
      _id ? 'Masukkan kata sandi cadangan.' : 'Enter the backup password.';
  String get passwordTooShort =>
      _id ? 'Gunakan minimal 6 karakter.' : 'Use at least 6 characters.';
  String get passwordMissingTypes => _id
      ? 'Sertakan huruf kecil, huruf besar, angka, dan simbol.'
      : 'Include a lowercase letter, an uppercase letter, a number, and a symbol.';
  String get pickerUnavailable => _id
      ? 'Pemilih file belum tersedia. Perbarui aplikasi, lalu buka ulang Riung.'
      : 'The file picker is unavailable. Update the app, then reopen Riung.';
  String get unlockRequired => _id
      ? 'Buat PIN jurnal untuk melindungi entri yang dipulihkan.'
      : 'Set a journal PIN to protect restored entries.';
  String get backupPinRequired => _id
      ? 'Buka kunci jurnal sebelum membuat cadangan.'
      : 'Unlock your journal before creating a backup.';
  String get noEntries => _id
      ? 'Belum ada entri untuk dicadangkan.'
      : 'There are no entries to back up.';
  String get saved => _id ? 'File cadangan disimpan.' : 'Backup file saved.';
  String get saveFailed => _id
      ? 'File cadangan gagal disimpan. Coba lagi.'
      : 'Could not save the backup file. Try again.';
  String get openFailed => _id
      ? 'File tidak bisa dibuka. Periksa file dan kata sandinya.'
      : 'Could not open the backup. Check the file and password.';
  String get restoreFailed => _id
      ? 'Jurnal gagal dipulihkan. Coba lagi.'
      : 'Could not restore the journal. Try again.';
  String get fileTooLarge => _id
      ? 'File cadangan melebihi batas 20 MB.'
      : 'The backup file exceeds the 20 MB limit.';
  String preview(int count, String dates) => _id
      ? '$count entri ($dates) siap dipulihkan. Entri yang sudah ada akan dilewati.'
      : '$count entries ($dates) are ready to restore. Existing entries will be skipped.';
  String restored(int added, int skipped) => _id
      ? '$added entri ditambahkan, $skipped dilewati.'
      : '$added entries added, $skipped skipped.';
  String get signInTitle =>
      _id ? 'Cadangkan jurnal tamu?' : 'Back up your guest journal?';
  String signInBody(int count) => _id
      ? 'Ada $count entri jurnal tamu di HP ini. Entri itu tidak akan muncul di akun yang kamu masuki. Buat cadangan agar kamu bisa memulihkannya.'
      : 'There are $count guest journal entries on this device. They won’t appear in the account you sign in to. Create a backup so you can restore them.';
  String get backUpFirst => _id ? 'Cadangkan dulu' : 'Back up first';
  String get continueSignIn => _id ? 'Lanjut masuk' : 'Continue signing in';
  String get journalCheckFailed => _id
      ? 'Jurnal tamu gagal diperiksa. Coba masuk lagi.'
      : 'Could not check your guest journal. Try signing in again.';
}
