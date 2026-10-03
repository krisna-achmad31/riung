import '../../../core/config/economy.dart';
import '../../../core/models/personality_result.dart';
import '../../../core/services/local_prefs_store.dart';

/// Tempat aksesori di karakter. Satu aksesori per slot.
enum AccessorySlot { head, face, neck, back }

enum AccessoryTier { kecil, biasa, langka }

/// Aksesori kosmetik ("printilan") untuk karakter hasil tes — dibeli dengan
/// koin, murni tampilan (tidak memengaruhi hasil tes atau progres apa pun,
/// CLAUDE.md aturan #4). Harga dari `EconomySpend`: kecil / biasa / langka.
///
/// Kepemilikan GLOBAL (beli sekali, bisa dipakai ketiga karakter). [category]
/// non-null = item eksklusif satu kategori tes: hanya muncul & bisa dipakai
/// di karakter tes itu, jadi katalog bertambah tanpa menagih item yang sama
/// berulang.
enum CharacterAccessory {
  // ── Umum ──
  beanie(AccessorySlot.head, AccessoryTier.kecil),
  ribbon(AccessorySlot.head, AccessoryTier.kecil),
  flower(AccessorySlot.head, AccessoryTier.kecil),
  witchHat(AccessorySlot.head, AccessoryTier.biasa),
  headphones(AccessorySlot.head, AccessoryTier.biasa),
  halo(AccessorySlot.head, AccessoryTier.langka),
  roundGlasses(AccessorySlot.face, AccessoryTier.kecil),
  starStickers(AccessorySlot.face, AccessoryTier.kecil),
  sunglasses(AccessorySlot.face, AccessoryTier.biasa),
  scarf(AccessorySlot.neck, AccessoryTier.kecil),
  necklace(AccessorySlot.neck, AccessoryTier.biasa),
  backpack(AccessorySlot.back, AccessoryTier.biasa),
  cape(AccessorySlot.back, AccessoryTier.langka),
  wings(AccessorySlot.back, AccessoryTier.langka),

  // ── Eksklusif tes 16 tipe gaya Jung ──
  jungCrown(AccessorySlot.head, AccessoryTier.langka, category: PersonalityTest.jung),
  jungMask(AccessorySlot.face, AccessoryTier.biasa, category: PersonalityTest.jung),
  jungCompass(AccessorySlot.neck, AccessoryTier.biasa, category: PersonalityTest.jung),
  jungLantern(AccessorySlot.back, AccessoryTier.langka, category: PersonalityTest.jung),

  // ── Eksklusif tes empat temperamen ──
  tempFlame(AccessorySlot.head, AccessoryTier.biasa, category: PersonalityTest.temperament),
  tempMonocle(AccessorySlot.face, AccessoryTier.kecil, category: PersonalityTest.temperament),
  tempLeaf(AccessorySlot.neck, AccessoryTier.kecil, category: PersonalityTest.temperament),
  tempWave(AccessorySlot.back, AccessoryTier.langka, category: PersonalityTest.temperament),

  // ── Eksklusif tes gaya keterikatan ──
  attNightCap(AccessorySlot.head, AccessoryTier.kecil, category: PersonalityTest.attachment),
  attHeartCharm(AccessorySlot.face, AccessoryTier.kecil, category: PersonalityTest.attachment),
  attBlanket(AccessorySlot.neck, AccessoryTier.biasa, category: PersonalityTest.attachment),
  attCompanion(AccessorySlot.back, AccessoryTier.langka, category: PersonalityTest.attachment);

  const CharacterAccessory(this.slot, this.tier, {this.category});

  final AccessorySlot slot;
  final AccessoryTier tier;

  /// Null = umum (semua karakter). Selain itu hanya untuk karakter tes ini.
  final PersonalityTest? category;

  String get id => name;

  /// Id di set `ownedCosmetics` milik dompet.
  String get cosmeticId => 'acc_$name';

  int get price {
    switch (tier) {
      case AccessoryTier.kecil:
        return EconomySpend.aksesorisKecil;
      case AccessoryTier.biasa:
        return EconomySpend.skinCommon;
      case AccessoryTier.langka:
        return EconomySpend.skinEpic;
    }
  }

  /// Bisa dipakai di karakter [test]? (umum, atau eksklusif tes itu)
  bool availableFor(PersonalityTest test) => category == null || category == test;

  static CharacterAccessory? fromId(String? id) {
    for (final a in values) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Aksesori yang tampil untuk karakter [test] pada [slot] (umum dulu, lalu eksklusif).
  static List<CharacterAccessory> catalogFor(PersonalityTest test, AccessorySlot slot) {
    final items = values.where((a) => a.slot == slot && a.availableFor(test)).toList();
    items.sort((a, b) => (a.category == null ? 0 : 1).compareTo(b.category == null ? 0 : 1));
    return items;
  }
}

/// Paket aksesori dengan diskon ([EconomySpend.aksesorisBundelDiskonPersen])
/// dibanding beli satuan. Harga dihitung dari item yang BELUM dimiliki, jadi
/// pengguna yang sudah punya sebagian tidak dirugikan.
enum AccessoryBundle {
  cozy([CharacterAccessory.beanie, CharacterAccessory.scarf, CharacterAccessory.roundGlasses]),
  stylish([CharacterAccessory.headphones, CharacterAccessory.sunglasses, CharacterAccessory.necklace]),
  heavenly([CharacterAccessory.halo, CharacterAccessory.wings, CharacterAccessory.starStickers]),
  jungSet([CharacterAccessory.jungCrown, CharacterAccessory.jungMask, CharacterAccessory.jungCompass, CharacterAccessory.jungLantern],
      category: PersonalityTest.jung),
  temperamentSet([CharacterAccessory.tempFlame, CharacterAccessory.tempMonocle, CharacterAccessory.tempLeaf, CharacterAccessory.tempWave],
      category: PersonalityTest.temperament),
  attachmentSet([CharacterAccessory.attNightCap, CharacterAccessory.attHeartCharm, CharacterAccessory.attBlanket, CharacterAccessory.attCompanion],
      category: PersonalityTest.attachment);

  const AccessoryBundle(this.items, {this.category});

  final List<CharacterAccessory> items;

  /// Null = paket umum. Selain itu hanya ditawarkan di karakter tes ini.
  final PersonalityTest? category;

  String get id => name;

  bool availableFor(PersonalityTest test) => category == null || category == test;

  static List<AccessoryBundle> catalogFor(PersonalityTest test) => values.where((b) => b.availableFor(test)).toList();

  /// Item paket yang belum dimiliki ([owned] = id kosmetik yang dimiliki).
  List<CharacterAccessory> missing(Set<String> owned) => items.where((a) => !owned.contains(a.cosmeticId)).toList();

  /// Harga normal satuan untuk item yang belum dimiliki.
  int fullPrice(Set<String> owned) => missing(owned).fold(0, (sum, a) => sum + a.price);

  /// Harga paket: harga satuan item yang belum dimiliki dikurangi diskon,
  /// dibulatkan ke [EconomySpend.aksesorisBundelPembulatan].
  int price(Set<String> owned) {
    final full = fullPrice(owned);
    if (full == 0) return 0;
    final discounted = full * (100 - EconomySpend.aksesorisBundelDiskonPersen) / 100;
    const step = EconomySpend.aksesorisBundelPembulatan;
    return (discounted / step).round() * step;
  }

  int savings(Set<String> owned) => fullPrice(owned) - price(owned);

  /// Paket hanya masuk akal kalau ada ≥ 2 item yang belum dimiliki.
  bool worthBuying(Set<String> owned) => missing(owned).length >= 2;
}

/// Baca/tulis aksesori yang dipakai per tes lewat [LocalPrefsStore].
class AccessoryLoadout {
  const AccessoryLoadout(this.prefs);

  final LocalPrefsStore prefs;

  /// Aksesori yang sedang dipakai untuk karakter [test] (maks satu per slot).
  /// Item eksklusif kategori lain diabaikan.
  List<CharacterAccessory> of(PersonalityTest test) {
    final slots = prefs.personalityAccessories[test.name] ?? const {};
    return [
      for (final e in slots.entries)
        if (CharacterAccessory.fromId(e.value) case final a? when a.slot.name == e.key && a.availableFor(test)) a,
    ];
  }

  Future<void> equip(PersonalityTest test, CharacterAccessory accessory) async {
    if (!accessory.availableFor(test)) return;
    final all = {for (final e in prefs.personalityAccessories.entries) e.key: {...e.value}};
    final mine = all.putIfAbsent(test.name, () => {});
    mine[accessory.slot.name] = accessory.id;
    await prefs.setPersonalityAccessories(all);
  }

  Future<void> unequip(PersonalityTest test, AccessorySlot slot) async {
    final all = {for (final e in prefs.personalityAccessories.entries) e.key: {...e.value}};
    all[test.name]?.remove(slot.name);
    await prefs.setPersonalityAccessories(all);
  }
}
