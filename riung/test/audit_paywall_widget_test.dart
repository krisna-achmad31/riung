// Audit kelayakan 2026-10-17 — Paywall Premium: loading/fallback harga,
// panjang string harga multi-region di 360dp, dan state pending/restore.
// Konvensi `REPRO <ID>` sama dengan test/audit_billing_api_test.dart; test
// tanpa prefix REPRO mengunci perilaku yang sudah diperbaiki.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riung/core/l10n/language_scope.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/core/state/state.dart';
import 'package:riung/core/widgets/widgets.dart';
import 'package:riung/features/toko/screens/paywall_premium_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Play extends Fake implements InAppPurchase {
  _Play(this.products);
  final stream = StreamController<List<PurchaseDetails>>.broadcast();
  Completer<List<ProductDetails>> products;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => stream.stream;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async =>
      ProductDetailsResponse(productDetails: await products.future, notFoundIDs: const []);
  @override
  Future<void> restorePurchases({String? applicationUserName}) async => stream.add(const []);
}

/// Akun sudah login — melewati sheet "Simpan pembelianmu".
class _SignedIn extends StubAuthService {
  @override
  bool get isAnonymous => false;
}

ProductDetails _p(String id, String price, String ccy) =>
    ProductDetails(id: id, title: id, description: '', price: price, rawPrice: 1, currencyCode: ccy);

Future<({_Play play, BillingService billing})> _pump(WidgetTester tester, {required Completer<List<ProductDetails>> products, bool signedIn = false}) async {
  tester.view.physicalSize = const Size(360, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  final prefs = await LocalPrefsStore.init();
  final repo = LocalUserRepository(prefs: prefs, db: LocalDatabaseService(), crypto: JournalCryptoService());
  final wallet = LocalWalletFunctionsService(prefs: prefs, userRepository: repo);
  final auth = signedIn ? _SignedIn() : StubAuthService();
  final play = _Play(products);
  final billing = BillingService(
    walletFunctions: wallet,
    userRepository: repo,
    currentUid: () => 'u_001',
    analytics: AnalyticsService(),
    isAnonymous: () => false,
    iap: play,
  );
  await billing.init();
  final language = LanguageNotifier(prefs: prefs);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(LanguageScope(notifier: language, child: AppScope(
    auth: AuthNotifier(auth, userRepository: repo),
    wallet: WalletNotifier(userRepository: repo, walletFunctions: wallet, prefs: prefs),
    streak: StreakNotifier(userRepository: repo),
    monsterProgress: MonsterProgressNotifier(userRepository: repo, walletFunctions: wallet),
    session: SessionNotifier(),
    appBeku: AppBekuNotifier(prefs: prefs),
    language: language,
    contentRepository: StubContentRepository(),
    userRepository: repo,
    pinService: JurnalPinService(),
    prefs: prefs,
    remoteConfig: RemoteConfigService(),
    billing: billing,
    analytics: AnalyticsService(),
    // Paywall di atas rute lain, seperti dibuka dari Toko/Profil — supaya
    // tombol X benar-benar bisa menutupnya.
    child: MaterialApp(navigatorKey: navigator, home: const SizedBox.shrink()),
  )));
  navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const PaywallPremiumScreen()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return (play: play, billing: billing);
}

/// Kumpulkan error overflow (bukan menggagalkan test) supaya bisa dipilah per lokasi.
List<String> _captureOverflows() {
  final found = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString();
    if (text.contains('overflowed')) {
      found.add(text);
    } else {
      previous?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = previous);
  return found;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('L-02: baris link "Pulihkan pembelian · Ketentuan" tidak overflow di 360dp (Wrap)', (tester) async {
    final overflows = _captureOverflows();
    final products = Completer<List<ProductDetails>>()..complete([_p('premium_yearly', 'Rp590.000', 'IDR')]);
    await _pump(tester, products: products);
    await tester.pump();
    expect(overflows.where((e) => e.contains('paywall_premium_screen.dart')), isEmpty);
  });

  testWidgets('M-01: selama produk Play dimuat → skeleton harga, tanpa Rupiah hardcode, CTA belum aktif', (tester) async {
    _captureOverflows();
    await _pump(tester, products: Completer());
    expect(find.byType(RiungSkeleton), findsNWidgets(2));
    expect(find.textContaining('Rp'), findsNothing);
    expect(find.textContaining('gratis 7 hari'), findsNothing, reason: 'H-02: trial belum diketahui');
  });

  testWidgets('M-01: Play gagal memuat produk → teks netral + "Coba lagi", tanpa Rupiah', (tester) async {
    _captureOverflows();
    final products = Completer<List<ProductDetails>>()..complete(const []);
    final rig = await _pump(tester, products: products);
    await tester.pump();
    expect(find.text('Harga tampil di Google Play'), findsNWidgets(2));
    expect(find.textContaining('Rp'), findsNothing);
    expect(find.text('Coba gratis 7 hari'), findsNothing, reason: 'H-02: tanpa offer trial, tanpa janji trial');
    await tester.tap(find.text('Langganan sekarang'));
    await tester.pump();
    expect(find.text('Paket belum tersedia di Play Store. Coba lagi nanti.'), findsOneWidget);

    // "Coba lagi" memuat ulang dari Play.
    rig.play.products = Completer<List<ProductDetails>>()..complete([_p('premium_yearly', 'Rp590.000', 'IDR'), _p('premium_monthly', 'Rp59.000', 'IDR')]);
    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Rp590.000/tahun'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });

  for (final (region, yearly, monthly) in [
    ('ID', 'Rp590.000', 'Rp59.000'),
    ('US', r'$39.99', r'$4.99'),
    ('IN (panjang)', '₹ 3.499,00 INR', '₹ 349,00 INR'),
    ('stress 40ch', 'IDR 1.490.000,00 (termasuk PPN 11%)', 'IDR 149.000,00 (termasuk PPN 11%)'),
  ]) {
    testWidgets('5. harga Play region $region: tampil apa adanya & tidak overflow di 360dp', (tester) async {
      final products = Completer<List<ProductDetails>>()
        ..complete([_p('premium_yearly', yearly, 'X'), _p('premium_monthly', monthly, 'X')]);
      final overflows = _captureOverflows();
      await _pump(tester, products: products);
      await tester.pump();
      expect(find.textContaining(yearly), findsOneWidget);
      expect(find.textContaining(monthly), findsOneWidget);
      if (region == 'US') expect(find.textContaining('Rp'), findsNothing);
      // Kartu harga (RiungRadioOption) membungkus teks → tidak overflow.
      expect(overflows.where((e) => e.contains('riung_radio_option.dart')), isEmpty);
    });
  }

  testWidgets('H-01: pembayaran pending → pesan menunggu, tombol & X aktif lagi', (tester) async {
    final products = Completer<List<ProductDetails>>()..complete([_p('premium_yearly', 'Rp590.000', 'IDR')]);
    _captureOverflows();
    final rig = await _pump(tester, products: products);
    await tester.pump();
    rig.play.stream.add([
      PurchaseDetails(
        productID: 'premium_yearly',
        verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: 't', source: 'google_play'),
        transactionDate: '0',
        status: PurchaseStatus.pending,
      ),
    ]);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Memproses...'), findsNothing);
    expect(find.text('Pembayaranmu sedang menunggu. Premium aktif otomatis begitu lunas.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPremiumScreen), findsNothing, reason: 'X tetap bisa menutup saat pembayaran tertunda');
  });

  testWidgets('H-01: buyPremium melempar (mis. /me gagal) → tidak macet di "Memproses…"', (tester) async {
    final products = Completer<List<ProductDetails>>()..complete([_p('premium_yearly', 'Rp590.000', 'IDR')]);
    _captureOverflows();
    // Tanpa ApiState → buyPremium melempar StateError (akun billing server tidak ada).
    await _pump(tester, products: products, signedIn: true);
    await tester.pump();
    await tester.tap(find.text('Langganan sekarang'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Memproses...'), findsNothing);
    expect(find.text('Pembelian gagal.'), findsOneWidget);
  });

  testWidgets('H-03: "Pulihkan pembelian" tanpa riwayat → pesan "belum ada pembelian", tidak macet', (tester) async {
    _captureOverflows();
    final products = Completer<List<ProductDetails>>()..complete([_p('premium_yearly', 'Rp590.000', 'IDR')]);
    await _pump(tester, products: products);
    await tester.pump();
    await tester.tap(find.text('Pulihkan pembelian'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Memproses...'), findsNothing);
    expect(find.text('Belum ada pembelian untuk dipulihkan.'), findsOneWidget);
  });
}
