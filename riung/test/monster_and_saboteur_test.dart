import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riung/core/l10n/app_language.dart';
import 'package:riung/core/l10n/l10n.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/features/monster/logic/habit_monsters.dart';
import 'package:riung/features/monster/logic/saboteur_content.dart';
import 'package:riung/features/toko/logic/monster_loadout.dart';
import 'package:riung/features/toko/logic/toko_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final strings = AppStrings.of(AppLanguage.indonesia);

  group('HabitMonsters', () {
    test('6 monster kebiasaan dengan 3 latihan berurutan', () {
      const habitIds = ['nanti', 'gulir', 'begadang', 'bunglon', 'bimbang', 'bara'];
      for (final id in habitIds) {
        expect(HabitMonsters.isHabit(id), isTrue);
        final practices = HabitMonsters.practicesOf(id);
        expect(practices.length, 3, reason: 'Monster $id harus punya 3 latihan');
        for (final p in practices) {
          expect(p.icon, isNotNull);
        }
      }

      expect(HabitMonsters.isHabit('waswas'), isFalse);
      expect(HabitMonsters.practicesOf('unknown'), isEmpty);
    });

    test('saboteurFor membangun model Saboteur dengan benar', () {
      final s = HabitMonsters.saboteurFor('nanti', strings);
      expect(s.id, 'nanti');
      expect(s.nama, isNotEmpty);
      expect(s.distorsiCbt, isNotEmpty);
      expect(s.deskripsi, isNotEmpty);
      expect(s.isBoss, isFalse);
    });
  });

  group('SaboteurContent', () {
    test('7 saboteur dasar memiliki narasi dan 3 teknik penangkal dengan multiplier 5x, 3x, 2x', () {
      const coreIds = ['hakim', 'waswas', 'sempurna', 'cermin', 'kabut', 'mengelak', 'meronta'];
      for (final id in coreIds) {
        final content = saboteurContentFor(id, strings.monster);
        expect(content, isNotNull, reason: 'Konten narasi untuk $id harus ada');
        expect(content!.apaKatanya, isNotEmpty);
        expect(content.faktanya, isNotEmpty);
        expect(content.duniaNyata, isNotEmpty);
        expect(content.techniques.length, 3);
        expect(content.techniques[0].multiplier, 5);
        expect(content.techniques[1].multiplier, 3);
        expect(content.techniques[2].multiplier, 2);
      }

      expect(saboteurContentFor('unknown_monster', strings.monster), isNull);
    });
  });

  group('MonsterLoadout', () {
    late LocalPrefsStore prefs;
    late MonsterLoadout loadout;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await LocalPrefsStore.init();
      await prefs.setMonsterCosmetics({});
      loadout = MonsterLoadout(prefs);
    });

    test('of hanya mengembalikan kosmetik yang dimiliki (owned) dan boleh dipakai', () async {
      final hat = TokoCosmetic.byId('topi_rajut');
      expect(hat, isNotNull);

      // Simpan pemakaian topi_rajut untuk waswas
      await loadout.save('waswas', [hat!]);

      // Jika belum dimiliki: of() kosong
      expect(loadout.of('waswas', {}), isEmpty);
      expect(loadout.idsOf('waswas', {}), isEmpty);

      // Jika sudah dimiliki: of() mengembalikan item
      final worn = loadout.of('waswas', {'topi_rajut'});
      expect(worn.length, 1);
      expect(worn.first.id, 'topi_rajut');
      expect(loadout.idsOf('waswas', {'topi_rajut'}), ['topi_rajut']);
    });

    test('Kosmetik eksklusif tidak bisa dipakai oleh monster lain', () async {
      // bingkai_emas eksklusif untuk cermin
      final bingkai = TokoCosmetic.byId('bingkai_emas');
      if (bingkai != null && bingkai.exclusive) {
        expect(bingkai.wearableBy('cermin'), isTrue);
        expect(bingkai.wearableBy('waswas'), isFalse);

        // Jika dipaksakan save ke waswas
        await loadout.save('waswas', [bingkai]);
        expect(loadout.of('waswas', {bingkai.id}), isEmpty);
      }
    });
  });
}
