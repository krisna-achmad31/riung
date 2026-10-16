import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/config/economy.dart';
import 'package:riung/core/config/appbeku_catalog.dart';
import 'package:riung/features/toko/logic/toko_data.dart';
import 'package:riung/features/kepribadian/logic/character_accessory.dart';
import 'package:riung/features/kepribadian/logic/card_style.dart';
import 'package:riung/features/meditasi/logic/meditation_catalog.dart';
import 'package:riung/features/betterme/data/betterme_content.dart';
import 'package:riung/core/services/api/api_config_store.dart';

void main() {
  final economy =
      jsonDecode(File('../docs/economy-props.json').readAsStringSync()) as Map;
  final catalog =
      jsonDecode(File('../docs/catalog.json').readAsStringSync()) as Map;
  test('bundled economic fallback matches the backend snapshot', () {
    expect(economy['earn'], {
      'checkin': EconomyEarn.checkinHarian,
      'journal': EconomyEarn.jurnal,
      'meditation': EconomyEarn.meditasi,
      'mission': EconomyEarn.misiHarian,
      'minigameWin': EconomyEarn.menangGame,
      'monsterTamed': EconomyEarn.monsterJinak,
      'bettermeLesson': EconomyEarn.betterMeLesson,
      'streak7': EconomyEarn.streak7Hari,
      'streak30': EconomyEarn.streak30Hari,
      'premiumYearlyDaily': EconomyPremium.koinHarianTahunan,
    });
    expect(
      economy['monsterProgress']['focus'],
      EconomyEarn.fokusProgressPercent,
    );
    expect(
      economy['monsterProgress']['minigameWin'],
      EconomyEarn.minigameWinProgressPercent,
    );
    expect(
      economy['monsterProgress']['minigameLose'],
      EconomyEarn.minigameLoseProgressPercent,
    );
    expect(economy['spend']['focus25'], EconomySpend.fokus25Menit);
    expect(economy['spend']['focus45'], EconomySpend.fokus45Menit);
    expect(economy['spend']['focus60'], EconomySpend.fokus60Menit);
    expect(economy['spend']['focusBundle5'], EconomySpend.fokusBundle5Sesi);
    expect(economy['spend']['streakShield'], EconomySpend.pelindungStreak);
    expect(
      economy['appbeku']['maxPaidUnlocksPerDay'],
      EconomyScroll.maxPaidUnlocksPerDay,
    );
    expect(
      economy['appbeku']['escalationPerUnlock'],
      EconomyScroll.escalationPerUnlock,
    );
    expect(
      economy['appbeku']['unlockCooldownSeconds'],
      EconomyScroll.unlockCooldownSeconds,
    );
    for (var i = 0; i < EconomyCoinPacks.all.length; i++) {
      final pack = EconomyCoinPacks.all[i];
      expect(economy['coinPacks'][i]['coins'], pack.coins);
      expect(economy['coinPacks'][i]['bonus'], pack.bonus);
      expect(economy['coinPacks'][i]['priceIdr'], pack.priceIdr);
    }
    expect(
      economy['premium']['monthlyPriceIdr'],
      EconomyPremium.hargaBulananIdr,
    );
    expect(
      economy['premium']['yearlyPriceIdr'],
      EconomyPremium.hargaTahunanIdr,
    );
  });
  test(
    'all existing purchasable assets have a matching server catalog id and price',
    () {
      final cosmetics = {
        for (final row in catalog['monsterCosmetics']) row['id']: row,
      };
      for (final item in tokoCosmetics) {
        expect(cosmetics[item.id]['price'], item.price);
        expect(cosmetics[item.id]['slot'], item.slot.name);
      }
      final accessories = {
        for (final row in catalog['accessories']) row['id']: row,
      };
      for (final item in CharacterAccessory.values) {
        expect(accessories[item.id]['price'], item.price);
        expect(accessories[item.id]['inventoryId'], item.cosmeticId);
      }
      final styles = {for (final row in catalog['cardStyles']) row['id']: row};
      for (final item in CardStyle.values) {
        expect(styles[item.id]['price'], item.price);
      }
      final apps = (catalog['appbeku']['apps'] as List)
          .map((row) => row['id'])
          .toSet();
      expect(apps, contains(AppBekuCatalog.instagram.packageName));
      expect(apps, contains(AppBekuCatalog.tiktok.packageName));
      final sessions = (catalog['meditations'] as List)
          .map((row) => row['id'])
          .toSet();
      expect(sessions, containsAll(MeditationCatalog.all.map((s) => s.id)));
      final lessons = (catalog['betterme']['lessons'] as List)
          .map((row) => row['id'])
          .toSet();
      expect(
        lessons,
        containsAll(betterMeLevels.expand((l) => l.sessions).map((s) => s.id)),
      );
    },
  );
  test(
    'live server zero prices are respected, and constants remain a fallback',
    () {
      ApiConfigStore.instance.raw = {
        'catalog': {
          'monsterCosmetics': [
            {'id': 'topi_rajut', 'price': 0},
          ],
        },
        'economy': {
          'spend': {'focus25': 0},
        },
      };
      expect(TokoCosmetic.byId('topi_rajut')!.price, 0);
      expect(ApiConfigStore.instance.value('spend', 'focus25', 25), 0);
      ApiConfigStore.instance.raw = {};
      expect(TokoCosmetic.byId('topi_rajut')!.price, EconomySpend.skinCommon);
    },
  );
}
