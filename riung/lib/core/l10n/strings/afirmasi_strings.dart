import '../../models/affirmation.dart';

/// Teks fitur Afirmasi: koleksi deck, kartu, bagikan, buat sendiri, pengingat.
abstract class AfirmasiStrings {
  const AfirmasiStrings();

  /// Terjemahan afirmasi bawaan (seed) menurut id; [fallback] = teks aslinya
  /// kalau bahasa ini tidak punya terjemahannya.
  String seededText(String id, String fallback);

  /// Teks tampil sebuah afirmasi: buatan sendiri TIDAK PERNAH diterjemahkan
  /// (itu kalimat user), bawaan diterjemahkan lewat [seededText].
  String textOf(Affirmation affirmation) =>
      affirmation.isCustom ? affirmation.teks : seededText(affirmation.id, affirmation.teks);

  // ── Koleksi ──
  String get title;
  String get subtitle;
  String get noDecks;
  String deckAgainst(String monsterName);
  String get customDeck;
  String cards(int count);

  // ── Kartu ──
  String get cardScreenTitle;
  String get cardLabelCustom;
  String cardLabelMonster(String monsterName);
  String swipeHint(int index, int total);
  String get favorite;
  String get share;

  // ── Bagikan ──
  String get shareTitle;
  String get shareNote;
  String get targetCopy;
  String get targetMore;
  String get saveAsImage;
  String get cardSaved;
  String get cardSaveFailed;
  String get cardShareFailed;
  String get textCopied;
  String shareText(String text);

  // ── Buat sendiri ──
  String get createTitle;
  String get createIntro;
  String get createHint;
  String get fightsAgainst;
  String get needInspiration;
  List<String> get inspirations;
  String get saveToCollection;

  // ── Pengingat ──
  String get reminderTitle;
  String get reminderSwitch;
  String get reminderNote;
  String get sendTime;
  List<(String, String)> get timeOptions;
  String get preview;
  String get previewSample;
  String get reminderInfo;
  String get reminderSaved;
}

class AfirmasiStringsId extends AfirmasiStrings {
  const AfirmasiStringsId();

  @override
  String seededText(String id, String fallback) => fallback;

  @override
  String get title => 'Afirmasi';
  @override
  String get subtitle => 'Kalimat kecil, pengaruh pelan-pelan';
  @override
  String get noDecks => 'Belum ada deck afirmasi.';
  @override
  String deckAgainst(String monsterName) => 'Melawan $monsterName';
  @override
  String get customDeck => 'Buatanku sendiri';
  @override
  String cards(int count) => '$count kartu';

  @override
  String get cardScreenTitle => 'Afirmasi hari ini';
  @override
  String get cardLabelCustom => 'AFIRMASI BUATANMU';
  @override
  String cardLabelMonster(String monsterName) => 'MEREDAKAN ${monsterName.toUpperCase()}';
  @override
  String swipeHint(int index, int total) => 'Geser buat kartu berikutnya · $index dari $total';
  @override
  String get favorite => 'Simpan';
  @override
  String get share => 'Bagikan';

  @override
  String get shareTitle => 'Bagikan kartu';
  @override
  String get shareNote => 'Bagikan kartunya tanpa membagikan isi jurnal atau datamu 🔒';
  @override
  String get targetCopy => 'Salin';
  @override
  String get targetMore => 'Lainnya';
  @override
  String get saveAsImage => 'Simpan sebagai gambar';
  @override
  String get cardSaved => 'Kartu tersimpan ke galeri.';
  @override
  String get cardSaveFailed => 'Gagal simpan kartu, coba lagi.';
  @override
  String get cardShareFailed => 'Gagal membagikan kartu, coba lagi.';
  @override
  String get textCopied => 'Teks afirmasi disalin.';
  @override
  String shareText(String text) => '$text — via Riung';

  @override
  String get createTitle => 'Afirmasi buatanmu';
  @override
  String get createIntro => 'Kalimat yang kamu tulis sendiri biasanya paling nempel. Pakai bahasamu sehari-hari aja, nggak perlu puitis.';
  @override
  String get createHint => 'Aku boleh istirahat tanpa merasa bersalah';
  @override
  String get fightsAgainst => 'Kalimat ini melawan…';
  @override
  String get needInspiration => 'Butuh inspirasi?';
  @override
  List<String> get inspirations => const [
        'Perasaan ini nggak enak, tapi dia akan lewat.',
        'Aku sudah melewati hari-hari yang lebih berat dari ini.',
      ];
  @override
  String get saveToCollection => 'Simpan ke koleksiku';

  @override
  String get reminderTitle => 'Pengingat afirmasi';
  @override
  String get reminderSwitch => 'Kirim afirmasi harian';
  @override
  String get reminderNote => 'Satu notifikasi per hari, isinya cuma kalimatnya. Nggak ada ajakan buka aplikasi.';
  @override
  String get sendTime => 'Jam kirim';
  @override
  List<(String, String)> get timeOptions => const [('07:00', 'Pagi'), ('12:30', 'Istirahat kerja'), ('21:00', 'Sebelum tidur')];
  @override
  String get preview => 'Pratinjau notifikasi';
  @override
  String get previewSample => '"Aku boleh istirahat tanpa merasa bersalah."';
  @override
  String get reminderInfo => 'Afirmasi dari koleksimu diputar bergantian. Kalimat buatanmu sendiri muncul lebih sering.';
  @override
  String get reminderSaved => 'Pengingat disimpan.';
}

class AfirmasiStringsEn extends AfirmasiStrings {
  const AfirmasiStringsEn();

  static const Map<String, String> _seeded = {
    'af_01': 'I do not have to be perfect to be worthy.',
    'af_02': 'My bad thoughts are not predictions.',
    'af_03': 'One small step today is enough.',
    'af_04': 'I measure myself by my own standards.',
  };

  @override
  String seededText(String id, String fallback) => _seeded[id] ?? fallback;

  @override
  String get title => 'Affirmations';
  @override
  String get subtitle => 'Small sentences, slow influence';
  @override
  String get noDecks => 'No affirmation decks yet.';
  @override
  String deckAgainst(String monsterName) => 'Against $monsterName';
  @override
  String get customDeck => 'My own';
  @override
  String cards(int count) => count == 1 ? '1 card' : '$count cards';

  @override
  String get cardScreenTitle => "Today's affirmation";
  @override
  String get cardLabelCustom => 'YOUR OWN AFFIRMATION';
  @override
  String cardLabelMonster(String monsterName) => 'CALMING ${monsterName.toUpperCase()}';
  @override
  String swipeHint(int index, int total) => 'Swipe for the next card · $index of $total';
  @override
  String get favorite => 'Save';
  @override
  String get share => 'Share';

  @override
  String get shareTitle => 'Share card';
  @override
  String get shareNote => 'Share the card without sharing your journal or your data 🔒';
  @override
  String get targetCopy => 'Copy';
  @override
  String get targetMore => 'More';
  @override
  String get saveAsImage => 'Save as image';
  @override
  String get cardSaved => 'Card saved to your gallery.';
  @override
  String get cardSaveFailed => 'Could not save the card, please try again.';
  @override
  String get cardShareFailed => 'Could not share the card, please try again.';
  @override
  String get textCopied => 'Affirmation text copied.';
  @override
  String shareText(String text) => '$text — via Riung';

  @override
  String get createTitle => 'Your own affirmation';
  @override
  String get createIntro => 'Sentences you write yourself usually stick the best. Use your everyday words, no need to be poetic.';
  @override
  String get createHint => 'I am allowed to rest without feeling guilty';
  @override
  String get fightsAgainst => 'This sentence fights…';
  @override
  String get needInspiration => 'Need inspiration?';
  @override
  List<String> get inspirations => const [
        'This feeling is unpleasant, but it will pass.',
        'I have gotten through harder days than this.',
      ];
  @override
  String get saveToCollection => 'Save to my collection';

  @override
  String get reminderTitle => 'Affirmation reminder';
  @override
  String get reminderSwitch => 'Send a daily affirmation';
  @override
  String get reminderNote => 'One notification a day, containing only the sentence. No nudge to open the app.';
  @override
  String get sendTime => 'Send time';
  @override
  List<(String, String)> get timeOptions => const [('07:00', 'Morning'), ('12:30', 'Work break'), ('21:00', 'Before bed')];
  @override
  String get preview => 'Notification preview';
  @override
  String get previewSample => '"I am allowed to rest without feeling guilty."';
  @override
  String get reminderInfo => 'Affirmations from your collection rotate. Sentences you wrote yourself show up more often.';
  @override
  String get reminderSaved => 'Reminder saved.';
}
