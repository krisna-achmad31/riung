import 'package:flutter_test/flutter_test.dart';

import 'package:riung/core/config/economy.dart';
import 'package:riung/core/services/billing_service.dart';
import 'package:riung/features/toko/logic/billing_sku_mapping.dart';
import 'package:riung/features/toko/logic/toko_data.dart';

void main() {
  group('TokoCosmetics Katalog & Validasi', () {
    test('Semua kosmetik memiliki slot, harga ekonomi, dan asset yang valid', () {
      expect(tokoCosmetics, isNotEmpty);
      for (final c in tokoCosmetics) {
        expect(c.id, isNotEmpty);
        expect(c.monsterId, isNotEmpty);
        expect(c.artAsset, startsWith('assets/monsters/3d/'));
        expect(c.artAsset, endsWith('.webp'));
        expect(c.price, greaterThan(0));
        expect([60, 100, 300, 500], contains(c.price), reason: 'Harga harus sesuai konstanta EconomySpend');
      }
    });

    test('TokoRarity sesuai aturan harga (EconomySpend)', () {
      expect(TokoRarity.ofPrice(EconomySpend.skinLegendary), TokoRarity.legendary);
      expect(TokoRarity.ofPrice(EconomySpend.skinEpic), TokoRarity.epic);
      expect(TokoRarity.ofPrice(EconomySpend.skinCommon), TokoRarity.common);
      expect(TokoRarity.ofPrice(EconomySpend.aksesorisKecil), TokoRarity.common);
    });

    test('Kosmetik khas dan eksklusifitas per monster', () {
      // bingkai_emas eksklusif cermin (tapi bukan khas, tampil di etalase)
      final bingkai = TokoCosmetic.byId('bingkai_emas');
      expect(bingkai, isNotNull);
      expect(bingkai!.exclusive, isTrue);
      expect(bingkai.khas, isFalse);
      expect(bingkai.wearableBy('cermin'), isTrue);
      expect(bingkai.wearableBy('waswas'), isFalse);
      expect(bingkai.listedFor('waswas'), isTrue, reason: 'Tetap tampil di lemari walau tidak bisa dipakai jika bukan khas');

      // jam_pasir kosmetik khas Si Nanti
      final jamPasir = TokoCosmetic.byId('jam_pasir');
      expect(jamPasir, isNotNull);
      expect(jamPasir!.khas, isTrue);
      expect(jamPasir.exclusive, isTrue);
      expect(jamPasir.listedFor('nanti'), isTrue);
      expect(jamPasir.listedFor('waswas'), isFalse, reason: 'Kosmetik khas tidak tampil di lemari monster lain');
    });

    test('TokoFocusBundle hemat 20% dibanding 5 sesi satuan', () {
      expect(TokoFocusBundle.hargaSatuSesi, EconomySpend.fokus25Menit);
      expect(TokoFocusBundle.jumlahPaket, 5);
      expect(TokoFocusBundle.hargaPaket, EconomySpend.fokusBundle5Sesi);
      expect(TokoFocusBundle.hargaPaket, lessThan(TokoFocusBundle.hargaSatuSesi * 5));
    });
  });

  group('Billing SKU Mapping', () {
    test('billingSkuFor memetakan CoinPack ke CoinPackSku yang benar', () {
      final smallSku = billingSkuFor(EconomyCoinPacks.kantong);
      expect(smallSku, CoinPackSku.small);
      expect(smallSku.totalCoins, 80);
      expect(smallSku.productId, 'coin_pack_small');

      final mediumSku = billingSkuFor(EconomyCoinPacks.peti);
      expect(mediumSku, CoinPackSku.medium);
      expect(mediumSku.totalCoins, 330);
      expect(mediumSku.productId, 'coin_pack_medium');

      final largeSku = billingSkuFor(EconomyCoinPacks.brankas);
      expect(largeSku, CoinPackSku.large);
      expect(largeSku.totalCoins, 820);
      expect(largeSku.productId, 'coin_pack_large');
    });

    test('PremiumSku bulanan dan tahunan sesuai harga EconomyPremium', () {
      expect(PremiumSku.monthly.priceIdr, EconomyPremium.hargaBulananIdr);
      expect(PremiumSku.monthly.durationDays, 30);
      expect(PremiumSku.yearly.priceIdr, EconomyPremium.hargaTahunanIdr);
      expect(PremiumSku.yearly.durationDays, 365);
    });
  });
}
