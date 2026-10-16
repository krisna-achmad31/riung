/// Server messages are debug-only; product copy is selected by error code.
String deleteSubscriptionWarning(bool english) => english
    ? 'Deleting your account does not cancel your Google Play subscription. Cancel it in Google Play before continuing.'
    : 'Menghapus akun tidak membatalkan langganan Google Play. Batalkan langganan di Google Play sebelum melanjutkan.';
String pendingSyncText(bool english) =>
    english ? 'Exercises waiting to sync' : 'Latihan menunggu sinkron';
String practiceCappedText(bool english) => english
    ? 'Exercise saved. No extra coins or progress were added for this activity.'
    : 'Latihan tersimpan. Aktivitas ini tidak menambah koin atau progres lagi.';

String apiErrorText(String code, {required bool english}) {
  const messages = <String, (String, String)>{
    'unauthenticated': ('Silakan masuk kembali.', 'Please sign in again.'),
    'app_check_failed': (
      'Verifikasi perangkat gagal. Coba lagi.',
      'Device verification failed. Try again.',
    ),
    'recent_login_required': (
      'Masuk kembali sebelum menghapus akun.',
      'Sign in again before deleting your account.',
    ),
    'permanent_account_required': (
      'Tautkan akun email atau Google terlebih dahulu.',
      'Link an email or Google account first.',
    ),
    'premium_required': (
      'Konten ini tersedia untuk Premium.',
      'This content is available with Premium.',
    ),
    'not_found': (
      'Data belum tersedia. Muat ulang dan coba lagi.',
      'This item is unavailable. Refresh and try again.',
    ),
    'insufficient_coins': (
      'Koin belum cukup. Yuk, lakukan latihan dulu.',
      'Not enough coins. Try an exercise first.',
    ),
    'price_changed': (
      'Harga berubah. Periksa harga terbaru sebelum melanjutkan.',
      'The price changed. Review the updated price before continuing.',
    ),
    'already_owned': (
      'Kamu sudah memiliki item ini.',
      'You already own this item.',
    ),
    'not_owned': (
      'Item ini belum kamu miliki.',
      'You do not own this item yet.',
    ),
    'limit_reached': (
      'Jatah hari ini sudah terpakai. Kamu bisa lanjut besok.',
      'Today’s allowance is used. You can continue tomorrow.',
    ),
    'cooldown': (
      'Jeda sejenak sebelum membuka lagi.',
      'Take a short break before unlocking again.',
    ),
    'ticket_invalid': (
      'Tiket Fokus belum bisa digunakan. Periksa tiketmu.',
      'This Focus ticket cannot be used. Check your tickets.',
    ),
    'purchase_invalid': (
      'Pembelian belum terverifikasi. Coba pulihkan pembelian.',
      'The purchase is unverified. Try restoring purchases.',
    ),
    'pin_locked': (
      'Verifikasi PIN dijeda. Coba lagi nanti.',
      'PIN verification is paused. Try again later.',
    ),
    'upgrade_required': (
      'Perbarui aplikasi untuk melanjutkan.',
      'Update the app to continue.',
    ),
    'rate_limited': (
      'Terlalu banyak permintaan. Coba beberapa saat lagi.',
      'Too many requests. Try again shortly.',
    ),
    'signup_limited': (
      'Batas akun baru hari ini tercapai. Coba besok.',
      'Today’s new account limit is reached. Try tomorrow.',
    ),
    'network': (
      'Belum terhubung. Latihanmu menunggu sinkron.',
      'Connection unavailable. Your exercises await sync.',
    ),
    'timeout': (
      'Koneksi terlalu lama. Coba lagi nanti.',
      'The connection timed out. Try again later.',
    ),
    'unavailable': (
      'Layanan sedang tidak tersedia. Coba lagi nanti.',
      'The service is unavailable. Try again later.',
    ),
    'internal': (
      'Layanan sedang mengalami gangguan. Coba lagi nanti.',
      'There is a service issue. Try again later.',
    ),
    'request_in_progress': (
      'Permintaan sedang diproses. Tunggu sebentar.',
      'Your request is processing. Please wait.',
    ),
    'invalid_request': (
      'Permintaan belum dapat diproses.',
      'The request could not be processed.',
    ),
    'idempotency_key_reuse': (
      'Permintaan belum dapat diproses.',
      'The request could not be processed.',
    ),
    'payload_too_large': (
      'Data terlalu besar untuk dikirim.',
      'The data is too large to send.',
    ),
    'unsupported_media_type': (
      'Format data belum didukung.',
      'This data format is unsupported.',
    ),
  };
  final message =
      messages[code] ??
      (
        'Terjadi kendala. Coba lagi nanti.',
        'Something went wrong. Try again later.',
      );
  return english ? message.$2 : message.$1;
}
