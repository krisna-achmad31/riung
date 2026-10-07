import '../../services/auth_service.dart';

/// Teks fitur Launch: splash, masuk, daftar, lupa sandi, izin notifikasi,
/// plus terjemahan error auth ([AuthError]).
abstract class LaunchStrings {
  const LaunchStrings();

  // ── Splash ──
  String get tagline;
  String get connectFailed;

  // ── Form auth (dipakai bersama) ──
  String get emailLabel;
  String get emailHint;
  String get passwordHint;
  String get passwordLabel;
  String get orDivider;
  String get continueWithGoogle;
  String get signIn;
  String get signUp;
  String get hasAccount;
  String get noAccount;

  // ── Masuk ──
  String get fillFirst;
  String get welcomeBack;
  String get monstersWaiting;
  String get forgotPassword;

  // ── Daftar ──
  String get invalidEmail;
  String get passwordTooShort;
  String get createAccount;
  String get createAccountSub;
  String get migrationWarning;

  // ── Lupa sandi ──
  String get forgotTitle;
  String get forgotSub;
  String get sending;
  String get sendResetLink;
  String get linkSent;
  String get rememberedPassword;

  // ── Izin notifikasi ──
  String get permissionTitle;
  String get permissionBody;
  String get permissionAsking;
  String get permissionEnable;
  String get permissionGranted;
  String get permissionDenied;

  /// Terjemahan error auth. [code] = kode mentah Firebase (hanya dipakai
  /// untuk pesan generik supaya bisa dilaporkan ke developer).
  String authError(AuthError error, String? code);
}

class LaunchStringsId extends LaunchStrings {
  const LaunchStringsId();

  @override
  String get tagline => 'Jinakkan monster dalam pikiranmu';
  @override
  String get connectFailed => 'Gagal tersambung. Cek koneksi internetmu.';

  @override
  String get emailHint => 'nama@email.com';
  @override
  String get passwordHint => 'Minimal 6 karakter';
  @override
  String get emailLabel => 'Email';
  @override
  String get passwordLabel => 'Kata sandi';
  @override
  String get orDivider => 'atau';
  @override
  String get continueWithGoogle => 'Lanjutkan dengan Google';
  @override
  String get signIn => 'Masuk';
  @override
  String get signUp => 'Daftar';
  @override
  String get hasAccount => 'Sudah punya akun?';
  @override
  String get noAccount => 'Belum punya akun?';

  @override
  String get fillFirst => 'Isi email & kata sandi dulu, ya.';
  @override
  String get welcomeBack => 'Selamat datang kembali';
  @override
  String get monstersWaiting => 'Monster-monstermu menunggumu.';
  @override
  String get forgotPassword => 'Lupa kata sandi?';

  @override
  String get invalidEmail => 'Format email belum valid';
  @override
  String get passwordTooShort => 'Kata sandi minimal 6 karakter';
  @override
  String get createAccount => 'Buat akunmu';
  @override
  String get createAccountSub => 'Gratis untuk mulai. Datamu aman dan nggak dibagikan.';
  @override
  String get migrationWarning => 'Akun berhasil dibuat, tapi progresmu belum sempat disalin. Coba buka ulang app.';

  @override
  String get forgotTitle => 'Lupa kata sandi? Tenang.';
  @override
  String get forgotSub => 'Masukkan emailmu, kami kirim tautan untuk membuat kata sandi baru.';
  @override
  String get sending => 'Mengirim…';
  @override
  String get sendResetLink => 'Kirim tautan reset';
  @override
  String get linkSent => 'Tautan terkirim! Cek kotak masuk atau folder spam, berlaku 30 menit.';
  @override
  String get rememberedPassword => 'Ingat lagi kata sandimu?';

  @override
  String get permissionTitle => 'Biar kami ingatkan dengan lembut';
  @override
  String get permissionBody =>
      'Satu pengingat kecil tiap pagi untuk check-in, tanpa spam, tanpa drama. Kamu bisa mengaturnya kapan saja.';
  @override
  String get permissionAsking => 'Meminta izin…';
  @override
  String get permissionEnable => 'Nyalakan pengingat';
  @override
  String get permissionGranted => 'Pengingat dinyalakan. Sampai jumpa besok pagi.';
  @override
  String get permissionDenied => 'Oke, kamu bisa menyalakannya lagi kapan saja lewat Pengaturan.';

  @override
  String authError(AuthError error, String? code) {
    switch (error) {
      case AuthError.emailInUse:
        return 'Email ini sudah terdaftar. Coba masuk aja.';
      case AuthError.invalidEmail:
        return 'Format emailnya belum bener nih.';
      case AuthError.weakPassword:
        return 'Kata sandinya kurang kuat, coba yang lain.';
      case AuthError.userNotFound:
        return 'Belum ada akun dengan email ini.';
      case AuthError.wrongCredential:
        return 'Email atau kata sandinya salah.';
      case AuthError.tooManyRequests:
        return 'Kebanyakan percobaan. Coba lagi sebentar lagi.';
      case AuthError.network:
        return 'Koneksi internetnya kayaknya lagi bermasalah.';
      case AuthError.credentialInUse:
        return 'Akun Google ini udah dipakai buat akun lain.';
      case AuthError.requiresRecentLogin:
        return 'Demi keamanan, masuk ulang dulu sebelum hapus akun.';
      case AuthError.googleNoToken:
        return 'Google Sign-In tidak mengembalikan token. Coba lagi.';
      case AuthError.googleUnavailable:
        return 'Masuk dengan Google belum bisa dipakai di build ini. Coba pakai email dulu ya.';
      case AuthError.unknown:
        return 'Ada yang salah, coba lagi ya${code == null ? '' : ' ($code)'}.';
    }
  }
}

class LaunchStringsEn extends LaunchStrings {
  const LaunchStringsEn();

  @override
  String get tagline => 'Tame the monsters in your mind';
  @override
  String get connectFailed => 'Could not connect. Check your internet connection.';

  @override
  String get emailHint => 'name@email.com';
  @override
  String get passwordHint => 'At least 6 characters';
  @override
  String get emailLabel => 'Email';
  @override
  String get passwordLabel => 'Password';
  @override
  String get orDivider => 'or';
  @override
  String get continueWithGoogle => 'Continue with Google';
  @override
  String get signIn => 'Sign in';
  @override
  String get signUp => 'Sign up';
  @override
  String get hasAccount => 'Already have an account?';
  @override
  String get noAccount => "Don't have an account yet?";

  @override
  String get fillFirst => 'Please fill in your email & password first.';
  @override
  String get welcomeBack => 'Welcome back';
  @override
  String get monstersWaiting => 'Your monsters are waiting for you.';
  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get invalidEmail => 'That email format is not valid yet';
  @override
  String get passwordTooShort => 'Password must be at least 6 characters';
  @override
  String get createAccount => 'Create your account';
  @override
  String get createAccountSub => 'Free to start. Your data is safe and never shared.';
  @override
  String get migrationWarning =>
      "Your account was created, but your progress couldn't be copied over yet. Try reopening the app.";

  @override
  String get forgotTitle => 'Forgot your password? No worries.';
  @override
  String get forgotSub => "Enter your email and we'll send a link to create a new password.";
  @override
  String get sending => 'Sending…';
  @override
  String get sendResetLink => 'Send reset link';
  @override
  String get linkSent => 'Link sent! Check your inbox or spam folder, valid for 30 minutes.';
  @override
  String get rememberedPassword => 'Remembered your password?';

  @override
  String get permissionTitle => 'Let us remind you gently';
  @override
  String get permissionBody =>
      'One small reminder each morning for your check-in, no spam, no drama. You can adjust it anytime.';
  @override
  String get permissionAsking => 'Asking for permission…';
  @override
  String get permissionEnable => 'Turn on reminders';
  @override
  String get permissionGranted => 'Reminders are on. See you tomorrow morning.';
  @override
  String get permissionDenied => 'Okay, you can turn them on again anytime in Settings.';

  @override
  String authError(AuthError error, String? code) {
    switch (error) {
      case AuthError.emailInUse:
        return 'This email is already registered. Try signing in instead.';
      case AuthError.invalidEmail:
        return "That email format doesn't look right.";
      case AuthError.weakPassword:
        return 'That password is too weak, try another one.';
      case AuthError.userNotFound:
        return 'There is no account with this email yet.';
      case AuthError.wrongCredential:
        return 'Wrong email or password.';
      case AuthError.tooManyRequests:
        return 'Too many attempts. Please try again in a moment.';
      case AuthError.network:
        return 'Your internet connection seems to be having problems.';
      case AuthError.credentialInUse:
        return 'This Google account is already used by another account.';
      case AuthError.requiresRecentLogin:
        return 'For your security, please sign in again before deleting your account.';
      case AuthError.googleNoToken:
        return 'Google Sign-In did not return a token. Please try again.';
      case AuthError.googleUnavailable:
        return 'Sign in with Google is not available in this build. Please use email for now.';
      case AuthError.unknown:
        return 'Something went wrong, please try again${code == null ? '' : ' ($code)'}.';
    }
  }
}
