import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riung/core/config/economy.dart';
import 'package:riung/core/models/personality_result.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/core/state/state.dart';
import 'package:riung/features/kepribadian/logic/card_style.dart';
import 'package:riung/features/kepribadian/logic/character_accessory.dart';

/// Kepemilikan kosmetik global, item eksklusif per kategori, paket berdiskon
/// (dihitung dari item yang belum dimiliki), dan gaya kartu per karakter.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalPrefsStore prefs;
  late WalletNotifier wallet;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await LocalPrefsStore.init();
    await prefs.setOwnedCosmetics({});
    await prefs.setPurchasedCoinsReserve(0);
    await prefs.setPersonalityAccessories({});
    final users = LocalUserRepository(prefs: prefs, db: LocalDatabaseService(), crypto: JournalCryptoService());
    wallet = WalletNotifier(
      userRepository: users,
      walletFunctions: LocalWalletFunctionsService(prefs: prefs, userRepository: users),
      prefs: prefs,
    );
    await wallet.load('u1');
  });

  test('item eksklusif hanya muncul dan bisa dipakai di kategorinya', () async {
    final jung = CharacterAccessory.catalogFor(PersonalityTest.jung, AccessorySlot.head);
    expect(jung, contains(CharacterAccessory.jungCrown));
    expect(jung, isNot(contains(CharacterAccessory.tempFlame)));
    expect(jung, isNot(contains(CharacterAccessory.attNightCap)));
    // Umum selalu ada, dan tampil lebih dulu dari eksklusif.
    expect(jung.first.category, isNull);

    final loadout = AccessoryLoadout(prefs);
    await loadout.equip(PersonalityTest.temperament, CharacterAccessory.jungCrown); // ditolak
    expect(loadout.of(PersonalityTest.temperament), isEmpty);
    await loadout.equip(PersonalityTest.temperament, CharacterAccessory.tempFlame);
    expect(loadout.of(PersonalityTest.temperament), [CharacterAccessory.tempFlame]);
    expect(loadout.of(PersonalityTest.jung), isEmpty);
  });

  test('setiap paket berisi item dari slot berbeda dan kategorinya konsisten', () {
    for (final bundle in AccessoryBundle.values) {
      final slots = bundle.items.map((a) => a.slot).toSet();
      expect(slots.length, bundle.items.length, reason: '${bundle.id}: satu item per slot');
      for (final item in bundle.items) {
        expect(item.category, bundle.category, reason: '${bundle.id}/${item.id}');
      }
    }
  });

  test('harga paket = jumlah item yang belum dimiliki dikurangi diskon, dibulatkan', () {
    expect(AccessoryBundle.cozy.fullPrice({}), 3 * EconomySpend.aksesorisKecil);
    expect(AccessoryBundle.cozy.price({}), 145); // 180 × 0.8 = 144 → 145
    expect(AccessoryBundle.heavenly.price({}), 530); // 660 × 0.8 = 528 → 530
    for (final b in AccessoryBundle.values) {
      expect(b.price({}), lessThan(b.fullPrice({})));
      expect(b.price({}) % EconomySpend.aksesorisBundelPembulatan, 0);
    }
  });

  test('item yang sudah dimiliki tidak ikut ditagih', () {
    final owned = {CharacterAccessory.halo.cosmeticId};
    expect(AccessoryBundle.heavenly.missing(owned), [CharacterAccessory.wings, CharacterAccessory.starStickers]);
    expect(AccessoryBundle.heavenly.fullPrice(owned), 300 + 60);
    expect(AccessoryBundle.heavenly.price(owned), 290); // 360 × 0.8 = 288 → 290
    // Sisa satu item: bukan paket lagi (harga normal), sembunyikan.
    final almost = {CharacterAccessory.halo.cosmeticId, CharacterAccessory.wings.cosmeticId};
    expect(AccessoryBundle.heavenly.worthBuying(almost), isFalse);
    expect(AccessoryBundle.heavenly.price({for (final a in AccessoryBundle.heavenly.items) a.cosmeticId}), 0);
  });

  test('beli paket: satu kali potong, semua item milik, koin kurang tidak membeli', () async {
    final bundle = AccessoryBundle.cozy;
    final ids = [for (final a in bundle.items) a.cosmeticId];
    final price = bundle.price(wallet.ownedCosmetics);

    // Saldo awal bisa berbeda antar-lingkungan: paksa harga di atas saldo.
    final gagal = await wallet.buyCosmeticBundle(bundleId: bundle.id, ids: ids, price: wallet.coins + 5);
    expect(gagal, isFalse);
    expect(ids.any(wallet.ownsCosmetic), isFalse);

    await wallet.earn(amount: 300, reason: 'test');
    final before = wallet.coins;
    final ok = await wallet.buyCosmeticBundle(bundleId: bundle.id, ids: ids, price: price);
    expect(ok, isTrue);
    expect(before - wallet.coins, price);
    expect(ids.every(wallet.ownsCosmetic), isTrue);

    // Kepemilikan global: karakter mana pun bisa memakainya.
    final loadout = AccessoryLoadout(prefs);
    await loadout.equip(PersonalityTest.attachment, CharacterAccessory.beanie);
    expect(loadout.of(PersonalityTest.attachment), [CharacterAccessory.beanie]);
  });

  test('gaya kartu disimpan terpisah per karakter', () async {
    await prefs.setPersonalityCardStyle(PersonalityTest.jung, CardStyle.values.last.id);
    expect(prefs.personalityCardStyle(PersonalityTest.jung), CardStyle.values.last.id);
    expect(prefs.personalityCardStyle(PersonalityTest.temperament), isNot(CardStyle.values.last.id));
  });
}
