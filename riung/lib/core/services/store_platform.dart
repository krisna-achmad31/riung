import 'package:flutter/foundation.dart';

/// Toko aplikasi tempat pembelian uang asli diproses: Google Play di
/// Android, App Store di iOS. Satu sumber untuk cabang billing, tautan
/// "kelola langganan", dan nama toko di copy.
enum StorePlatform {
  googlePlay,
  appStore;

  /// Ikut [defaultTargetPlatform], jadi test bisa menggantinya lewat
  /// `debugDefaultTargetPlatformOverride`.
  static StorePlatform get current => defaultTargetPlatform == TargetPlatform.iOS ? appStore : googlePlay;

  bool get isAppStore => this == appStore;

  /// Nama toko di copy — sama di semua bahasa.
  String get label => isAppStore ? 'App Store' : 'Google Play';

  /// Nama aplikasi tokonya ("di Play Store").
  String get appLabel => isAppStore ? 'App Store' : 'Play Store';

  /// Bentuk pendek untuk label sempit ("Harga di Play").
  String get shortLabel => isAppStore ? 'App Store' : 'Play';

  /// Halaman langganan milik toko. App Store tidak punya tautan per produk.
  Uri manageSubscriptionsUri(String? productId) => switch (this) {
        googlePlay => Uri.parse(
            'https://play.google.com/store/account/subscriptions'
            '${productId != null ? '?sku=$productId&package=id.riung.riung' : ''}',
          ),
        appStore => Uri.parse('https://apps.apple.com/account/subscriptions'),
      };
}
