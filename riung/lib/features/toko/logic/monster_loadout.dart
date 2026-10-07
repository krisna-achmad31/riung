import '../../../core/services/services.dart';
import 'toko_data.dart';

/// Baca/tulis kosmetik yang dipakai per monster (Lemari) lewat
/// [LocalPrefsStore] — maksimal satu kosmetik per slot.
class MonsterLoadout {
  const MonsterLoadout(this.prefs);

  final LocalPrefsStore prefs;

  /// Kosmetik yang dipakai [monsterId], hanya yang dimiliki ([owned]) dan
  /// boleh dipakai monster itu.
  List<TokoCosmetic> of(String monsterId, Set<String> owned) {
    final slots = prefs.monsterCosmetics[monsterId] ?? const {};
    return [
      for (final e in slots.entries)
        if (TokoCosmetic.byId(e.value) case final c? when c.slot.name == e.key && c.wearableBy(monsterId) && owned.contains(c.id)) c,
    ];
  }

  /// Id kosmetik siap dioper ke `RiungMonster.cosmetics`.
  List<String> idsOf(String monsterId, Set<String> owned) => [for (final c in of(monsterId, owned)) c.id];

  Future<void> save(String monsterId, Iterable<TokoCosmetic> worn) async {
    final all = {for (final e in prefs.monsterCosmetics.entries) e.key: {...e.value}};
    all[monsterId] = {for (final c in worn) if (c.wearableBy(monsterId)) c.slot.name: c.id};
    await prefs.setMonsterCosmetics(all);
  }
}
