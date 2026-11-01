/// ID OAuth "Web client" (client_type 3 di `google-services.json`) untuk
/// project Firebase ini, dipakai `google_sign_in` v7+ sebagai
/// `serverClientId` di Android (lihat
/// `FirebaseAuthService._ensureGoogleInitialized`). BUKAN Android client id,
/// BUKAN API key. Lihat `docs/setup-firebase.md` § Google kalau perlu
/// generate ulang (mis. ganti project Firebase).
const String googleServerClientId =
    '809457116609-sptl3dffda8utnvp10nnmesh3c2q1rle.apps.googleusercontent.com';

/// Tombol "Lanjutkan dengan Apple" di Daftar/Masuk (iOS). Masih dimatikan
/// sampai provider Apple aktif di Firebase Console, App ID punya capability
/// Sign in with Apple, dan OAuth code flow (Team ID, Key ID, .p8) terisi
/// supaya pencabutan token saat hapus akun jalan. Lihat
/// `docs/setup-firebase.md` § Apple.
const bool appleSignInEnabled = false;
