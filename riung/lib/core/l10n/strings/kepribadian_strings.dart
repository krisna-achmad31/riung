import '../../../features/kepribadian/logic/character_accessory.dart';
import '../../models/personality_result.dart';

/// Nama & satu kalimat untuk satu hasil (tipe / temperamen / gaya keterikatan).
class ProfileText {
  const ProfileText({required this.name, required this.tagline, required this.strengths, required this.growth});

  final String name;
  final String tagline;
  final List<String> strengths;
  final String growth;
}

/// Teks fitur "Kenali dirimu": hub, tes, hasil, karakter & kartu bagikan.
/// Semua tes adalah alat refleksi, BUKAN diagnosis (lihat [disclaimer]).
abstract class KepribadianStrings {
  const KepribadianStrings();

  // ── Hub ──
  String get title;
  String get subtitle;
  String get disclaimer;
  String testName(PersonalityTest test);
  String testBlurb(PersonalityTest test);
  String questionCount(int count);
  String get notTakenYet;
  String get startTest;
  String get seeResult;
  String get retake;

  // ── Tes ──
  String progress(int current, int total);
  List<String> get scaleLabels;
  String get next;
  String get previous;
  String get finish;
  String question(String id);
  String get exitTitle;
  String get exitBody;

  // ── Hasil ──
  String get resultKicker;
  String get strengthsTitle;
  String get growthTitle;
  String get scoresTitle;
  String get gentleNote;
  String get blendWith;
  String axisLabel(String key);
  String get shareCard;
  String get saveImage;
  String get imageSaved;
  String get imageSaveFailed;
  String get imageShareFailed;
  String shareText(String name);
  String cardTagline(PersonalityTest test);

  // ── Gaya kartu (add-on) ──
  String get stylesTitle;
  String get stylesBody;
  String styleName(String id);
  String get styleOwned;
  String get styleSelected;
  String styleBuy(int price);
  String styleBought(String name);
  String styleConfirmLabel(String name);

  // ── Kustomisasi karakter (add-on aksesori) ──
  String get customizeTitle;
  String get customizeBody;
  String slotName(AccessorySlot slot);
  String accessoryName(CharacterAccessory accessory);
  String get accessoryEquipped;
  String get accessoryRemove;
  String accessoryBought(String name);
  String accessoryConfirmLabel(String name);
  String get accessoryExclusive;
  String get bundlesTitle;
  String get bundlesBody;
  String bundleName(AccessoryBundle bundle);
  String bundleItems(int count);
  String bundleSave(int coins);
  String bundleBuy(int price);
  String bundleBought(String name);
  String bundleConfirmLabel(String name);

  // ── Kartu di Beranda ──
  String get homeTitle;
  String get homeMonsterLabel;
  String homeMonsterProgress(int percent);
  String get homeSeeAll;
  String homeTestShort(PersonalityTest test);
  String get homeTakeTest;

  // ── Profil ──
  ProfileText jungType(String code);
  String poleStrength(String letter);
  String poleGrowth(String letter);
  ProfileText temperament(String key);
  ProfileText attachment(String key);

  // ── Pola dari jurnal ──
  String get signalsTitle;
  String get signalsNote;
  String get signalsEmpty;
  String signalEntries(int count);
  String signalMood(String label);
  String signalPeriod(String period);
  String signalMonster(String monsterName);
  String moodLabel(String moodId);
  String periodLabel(String period);
}

class KepribadianStringsId extends KepribadianStrings {
  const KepribadianStringsId();

  static const _questions = {
    // Jung: E/I
    'j_ei_1': 'Aku merasa berenergi setelah ngobrol dengan banyak orang.',
    'j_ei_2': 'Setelah seharian bersama orang lain, aku butuh waktu sendiri untuk mengisi ulang.',
    'j_ei_3': 'Aku mudah membuka obrolan dengan orang yang baru kukenal.',
    'j_ei_4': 'Aku lebih nyaman memikirkan sesuatu sendirian sebelum membicarakannya.',
    'j_ei_5': 'Aku senang jadi pusat perhatian di lingkaran pertemananku.',
    'j_ei_6': 'Aku lebih suka ngobrol berdua atau kelompok kecil daripada di keramaian.',
    // S/N
    'j_sn_1': 'Aku lebih percaya pada hal yang bisa kulihat dan buktikan langsung.',
    'j_sn_2': 'Aku sering asyik memikirkan kemungkinan dan makna di balik sesuatu.',
    'j_sn_3': 'Aku suka instruksi yang jelas dengan langkah-langkah konkret.',
    'j_sn_4': 'Aku tertarik pada ide baru meski belum jelas gunanya.',
    'j_sn_5': 'Aku memperhatikan detail kecil yang sering terlewat orang lain.',
    'j_sn_6': 'Aku biasanya melihat gambaran besar dulu sebelum detailnya.',
    // T/F
    'j_tf_1': 'Saat memutuskan sesuatu, aku mengutamakan logika dan fakta.',
    'j_tf_2': 'Perasaan orang lain sangat memengaruhi keputusanku.',
    'j_tf_3': 'Aku bisa menilai sebuah ide tanpa terbawa perasaan soal orang yang mengusulkannya.',
    'j_tf_4': 'Aku berusaha menjaga keharmonisan, bahkan kalau harus mengalah.',
    'j_tf_5': 'Aku lebih suka jujur apa adanya daripada menjaga suasana.',
    'j_tf_6': 'Aku mudah ikut merasakan apa yang dirasakan orang di sekitarku.',
    // J/P
    'j_jp_1': 'Aku tenang kalau rencanaku sudah tersusun jelas.',
    'j_jp_2': 'Aku lebih suka membiarkan rencana mengalir dan menyesuaikan di jalan.',
    'j_jp_3': 'Aku suka menyelesaikan tugas jauh sebelum tenggat.',
    'j_jp_4': 'Aku sering baru bersemangat mengerjakan sesuatu mendekati tenggat.',
    'j_jp_5': 'Aku nyaman dengan jadwal dan rutinitas yang teratur.',
    'j_jp_6': 'Aku suka membuka banyak pilihan dan menunda memutuskan.',
    // Temperamen
    't_san_1': 'Aku mudah bersemangat dan menularkannya ke orang lain.',
    't_kol_1': 'Aku suka memimpin dan mengambil keputusan dengan cepat.',
    't_mel_1': 'Aku memikirkan sesuatu dengan sangat teliti dan mendalam.',
    't_fle_1': 'Aku tetap tenang saat orang lain panik.',
    't_san_2': 'Aku cepat akrab dan suka suasana ramai.',
    't_kol_2': 'Aku tidak sabar menghadapi hal yang berjalan lambat.',
    't_mel_2': 'Aku punya standar tinggi terhadap hasil kerjaku.',
    't_fle_2': 'Aku sabar dan tidak mudah tersulut emosi.',
    't_san_3': 'Aku sering bertindak spontan lalu memikirkannya belakangan.',
    't_kol_3': 'Aku fokus pada tujuan dan hasil akhirnya.',
    't_mel_3': 'Aku sering merenungkan hal yang salah atau yang bisa lebih baik.',
    't_fle_3': 'Aku lebih suka mengalah daripada ribut.',
    't_san_4': 'Suasana hatiku cepat naik, tapi juga cepat berubah.',
    't_kol_4': 'Aku terbuka menyampaikan pendapat, kadang terlalu lugas.',
    't_mel_4': 'Aku peka terhadap suasana dan perasaan yang halus.',
    't_fle_4': 'Aku nyaman dengan ritme yang santai dan stabil.',
    't_san_5': 'Aku suka bercerita dan bikin orang tertawa.',
    't_kol_5': 'Tantangan justru membuatku makin termotivasi.',
    't_mel_5': 'Aku butuh waktu tenang untuk berpikir dan merasa.',
    't_fle_5': 'Aku sering jadi penengah kalau ada perselisihan.',
    // Keterikatan
    'a_cemas_1': 'Aku sering khawatir orang terdekatku akan meninggalkanku.',
    'a_hindar_1': 'Aku merasa tidak nyaman kalau orang terlalu dekat secara emosi.',
    'a_cemas_2': 'Aku butuh sering diyakinkan bahwa aku disayangi.',
    'a_hindar_2': 'Aku lebih suka mengurus masalahku sendiri daripada bercerita.',
    'a_cemas_3': 'Kalau pesanku lama dibalas, pikiranku langsung ke mana-mana.',
    'a_hindar_3': 'Aku sulit bergantung pada orang lain.',
    'a_cemas_4': 'Aku takut perhatian orang terdekatku berkurang tanpa aku tahu sebabnya.',
    'a_hindar_4': 'Aku nyaman berbagi perasaan terdalamku dengan orang dekat.',
    'a_cemas_5': 'Aku jarang cemas soal apakah orang terdekatku benar-benar peduli.',
    'a_hindar_5': 'Aku cenderung menjaga jarak begitu hubungan terasa mulai serius.',
    'a_cemas_6': 'Aku mudah merasa cemburu atau tersisih.',
    'a_hindar_6': 'Aku senang bergantung dan dibutuhkan oleh orang yang kusayangi.',
  };

  static const _jung = {
    'ENFP': ProfileText(name: 'Si Pemercik Ide', tagline: 'Penuh ide, hangat, dan gampang membuat orang bersemangat.', strengths: [], growth: ''),
    'ENFJ': ProfileText(name: 'Si Penghangat', tagline: 'Peka pada orang lain dan pandai menyatukan mereka.', strengths: [], growth: ''),
    'ENTP': ProfileText(name: 'Si Penantang', tagline: 'Suka mengajak berdebat sehat dan mencoba cara baru.', strengths: [], growth: ''),
    'ENTJ': ProfileText(name: 'Si Nakhoda', tagline: 'Tegas menata arah dan menggerakkan orang menuju tujuan.', strengths: [], growth: ''),
    'ESFP': ProfileText(name: 'Si Penghidup Suasana', tagline: 'Hidup di saat ini dan membuat sekitarnya ikut hidup.', strengths: [], growth: ''),
    'ESFJ': ProfileText(name: 'Si Perajut Kebersamaan', tagline: 'Peduli, rapi mengurus orang-orang terdekatnya.', strengths: [], growth: ''),
    'ESTP': ProfileText(name: 'Si Pelaku Sigap', tagline: 'Cepat membaca situasi dan langsung bertindak.', strengths: [], growth: ''),
    'ESTJ': ProfileText(name: 'Si Penata', tagline: 'Menyusun aturan dan memastikan semuanya berjalan.', strengths: [], growth: ''),
    'INFP': ProfileText(name: 'Si Pemimpi Lembut', tagline: 'Punya dunia batin yang kaya dan nilai yang dipegang teguh.', strengths: [], growth: ''),
    'INFJ': ProfileText(name: 'Si Penerawang Hati', tagline: 'Tenang, dalam, dan sering paham apa yang tak terucap.', strengths: [], growth: ''),
    'INTP': ProfileText(name: 'Si Penjelajah Logika', tagline: 'Senang membongkar cara kerja segala hal.', strengths: [], growth: ''),
    'INTJ': ProfileText(name: 'Si Perancang Jangka Panjang', tagline: 'Menyusun rencana jauh ke depan dengan kepala dingin.', strengths: [], growth: ''),
    'ISFP': ProfileText(name: 'Si Seniman Tenang', tagline: 'Lembut, peka pada keindahan, dan setia pada dirinya sendiri.', strengths: [], growth: ''),
    'ISFJ': ProfileText(name: 'Si Penjaga Setia', tagline: 'Diam-diam merawat dan bisa diandalkan.', strengths: [], growth: ''),
    'ISTP': ProfileText(name: 'Si Perakit', tagline: 'Tenang, praktis, dan jago memecahkan masalah dengan tangan sendiri.', strengths: [], growth: ''),
    'ISTJ': ProfileText(name: 'Si Teliti Andal', tagline: 'Konsisten, jujur, dan memegang janji.', strengths: [], growth: ''),
  };

  static const _poleStrengths = {
    'E': 'Mudah menghangatkan suasana dan menggerakkan orang.',
    'I': 'Dalam dan fokus saat memikirkan sesuatu.',
    'S': 'Teliti dan membumi pada hal yang nyata.',
    'N': 'Melihat pola dan kemungkinan yang orang lain lewatkan.',
    'T': 'Jernih menimbang fakta dan sebab-akibat.',
    'F': 'Peka dan tulus menjaga perasaan orang.',
    'J': 'Terencana dan bisa diandalkan.',
    'P': 'Luwes dan cepat menyesuaikan diri.',
  };

  static const _poleGrowths = {
    'E': 'Sisihkan jeda sendiri supaya energimu tidak habis.',
    'I': 'Sesekali bagikan pikiranmu lebih awal, orang lain ingin tahu.',
    'S': 'Beri ruang pada kemungkinan yang belum terbukti.',
    'N': 'Turunkan ide besar jadi satu langkah kecil hari ini.',
    'T': 'Sampaikan kejujuranmu dengan kehangatan.',
    'F': 'Kamu juga berhak mendapat giliran, jangan selalu mengalah.',
    'J': 'Sisakan ruang untuk rencana yang berubah.',
    'P': 'Tetapkan satu tenggat kecil untuk menjaga momentum.',
  };

  static const _temperaments = {
    'sanguinis': ProfileText(
      name: 'Sanguinis',
      tagline: 'Ceria, ramah, dan penuh warna.',
      strengths: ['Mudah bergaul dan menularkan semangat', 'Cepat bangkit dan melihat sisi terang'],
      growth: 'Latih menuntaskan satu hal sebelum pindah ke yang berikutnya.',
    ),
    'koleris': ProfileText(
      name: 'Koleris',
      tagline: 'Tegas, berani, dan berorientasi pada hasil.',
      strengths: ['Berani mengambil keputusan dan memimpin', 'Gigih mengejar tujuan'],
      growth: 'Beri ruang untuk mendengar sebelum memutuskan.',
    ),
    'melankolis': ProfileText(
      name: 'Melankolis',
      tagline: 'Dalam, teliti, dan peka.',
      strengths: ['Cermat dan bermutu dalam bekerja', 'Peka pada perasaan dan makna'],
      growth: 'Ingat bahwa cukup baik sudah baik, tidak harus sempurna.',
    ),
    'flegmatis': ProfileText(
      name: 'Flegmatis',
      tagline: 'Tenang, sabar, dan penyeimbang.',
      strengths: ['Stabil dan menenangkan orang lain', 'Pendengar dan penengah yang baik'],
      growth: 'Suarakan keinginanmu, kamu tidak harus selalu mengalah.',
    ),
  };

  static const _attachments = {
    'aman': ProfileText(
      name: 'Aman',
      tagline: 'Nyaman dekat dengan orang lain dan nyaman sendiri.',
      strengths: ['Mudah percaya dan terbuka pada orang dekat', 'Bisa meminta dan memberi dukungan'],
      growth: 'Tetap dengarkan tanda-tanda tubuh dan hatimu saat hubungan terasa berat.',
    ),
    'cemas': ProfileText(
      name: 'Cemas',
      tagline: 'Sangat menyayangi, dan sering butuh kepastian.',
      strengths: ['Peduli dan peka pada hubungan', 'Berani menunjukkan kebutuhan akan kedekatan'],
      growth: 'Coba tenangkan diri sendiri dulu lewat napas atau menulis sebelum meminta kepastian.',
    ),
    'menghindar': ProfileText(
      name: 'Menghindar',
      tagline: 'Menghargai kemandirian dan ruang pribadi.',
      strengths: ['Mandiri dan tenang menghadapi masalah', 'Menghargai batas diri sendiri dan orang lain'],
      growth: 'Coba bagikan satu hal kecil pada orang yang kamu percaya, pelan-pelan.',
    ),
    'cemas_menghindar': ProfileText(
      name: 'Cemas-Menghindar',
      tagline: 'Ingin dekat, tapi juga takut terluka.',
      strengths: ['Sangat sadar pada dinamika hubungan', 'Punya kapasitas besar untuk memahami diri'],
      growth: 'Beri dirimu waktu; membangun rasa aman itu bisa dilatih pelan-pelan, sendiri atau dengan pendamping profesional.',
    ),
  };

  static const _moods = {
    'berat': 'berat',
    'agak_berat': 'agak berat',
    'datar': 'datar',
    'cukup_baik': 'cukup baik',
    'senang': 'senang',
  };

  @override
  String get title => 'Kenali dirimu';
  @override
  String get subtitle => 'Tiga cara melihat dirimu, dengan karakter khusus buatmu.';
  @override
  String get disclaimer => 'Ini alat refleksi diri, bukan diagnosis atau penilaian klinis. Hasilnya bisa berubah seiring waktu dan situasi.';
  @override
  String testName(PersonalityTest test) {
    switch (test) {
      case PersonalityTest.jung:
        return '16 tipe gaya Jung';
      case PersonalityTest.temperament:
        return 'Empat temperamen';
      case PersonalityTest.attachment:
        return 'Gaya keterikatan';
    }
  }

  @override
  String testBlurb(PersonalityTest test) {
    switch (test) {
      case PersonalityTest.jung:
        return 'Cara kamu mengisi energi, menangkap informasi, memutuskan, dan menata hidup.';
      case PersonalityTest.temperament:
        return 'Warna dasar wataku menurut tradisi empat temperamen.';
      case PersonalityTest.attachment:
        return 'Pola kedekatanmu dengan orang-orang yang kamu sayangi.';
    }
  }

  @override
  String questionCount(int count) => '$count pertanyaan';
  @override
  String get notTakenYet => 'Belum diisi';
  @override
  String get startTest => 'Mulai';
  @override
  String get seeResult => 'Lihat hasil';
  @override
  String get retake => 'Ulangi tes';

  @override
  String progress(int current, int total) => '$current dari $total';
  @override
  List<String> get scaleLabels => const ['Sangat tidak setuju', 'Tidak setuju', 'Netral', 'Setuju', 'Sangat setuju'];
  @override
  String get next => 'Lanjut';
  @override
  String get previous => 'Sebelumnya';
  @override
  String get finish => 'Lihat hasil';
  @override
  String question(String id) => _questions[id] ?? id;
  @override
  String get exitTitle => 'Keluar dari tes?';
  @override
  String get exitBody => 'Jawabanmu belum tersimpan. Kamu bisa mengulang kapan saja.';

  @override
  String get resultKicker => 'KARAKTERMU';
  @override
  String get strengthsTitle => 'Kekuatanmu';
  @override
  String get growthTitle => 'Yang bisa dilatih';
  @override
  String get scoresTitle => 'Kecenderunganmu';
  @override
  String get gentleNote => 'Tidak ada hasil yang lebih baik dari yang lain. Ini cuma cermin untuk mengenal dirimu.';
  @override
  String get blendWith => 'campuran dengan';
  @override
  String axisLabel(String key) {
    const labels = {
      'E': 'Ekstrovert', 'I': 'Introvert', 'S': 'Sensing (nyata)', 'N': 'Intuisi (ide)', 'T': 'Berpikir', 'F': 'Merasa', 'J': 'Terencana', 'P': 'Spontan',
      'sanguinis': 'Sanguinis', 'koleris': 'Koleris', 'melankolis': 'Melankolis', 'flegmatis': 'Flegmatis',
      'cemas': 'Kecemasan', 'menghindar': 'Penghindaran',
    };
    return labels[key] ?? key;
  }

  @override
  String get shareCard => 'Bagikan kartu';
  @override
  String get saveImage => 'Simpan gambar';
  @override
  String get imageSaved => 'Kartu tersimpan di galeri.';
  @override
  String get imageSaveFailed => 'Belum bisa menyimpan gambar. Coba lagi.';
  @override
  String get imageShareFailed => 'Belum bisa membagikan kartu. Coba lagi.';
  @override
  String shareText(String name) => 'Aku $name di Riung 🌙 Kenali karakter dirimu juga: https://play.google.com/store/apps/details?id=com.riung.riung #Riung #KenaliDirimu';
  @override
  String cardTagline(PersonalityTest test) => 'Kenali dirimu di Riung';

  @override
  String get stylesTitle => 'Gaya kartu';
  @override
  String get stylesBody => 'Ganti tampilan kartumu. Hanya tampilan, tidak memengaruhi hasil atau progres apa pun.';
  @override
  String styleName(String id) {
    const names = {'klasik': 'Klasik', 'taman': 'Taman', 'arkade': 'Arkade', 'galaksi': 'Galaksi', 'aurora': 'Aurora'};
    return names[id] ?? id;
  }

  @override
  String get styleOwned => 'Dimiliki';
  @override
  String get styleSelected => 'Dipakai';
  @override
  String styleBuy(int price) => '$price koin';
  @override
  String styleBought(String name) => 'Gaya $name terbuka.';
  @override
  String styleConfirmLabel(String name) => 'Gaya kartu $name';

  @override
  String get customizeTitle => 'Kustomisasi karakter';
  @override
  String get customizeBody => 'Pasang printilan di karaktermu. Hanya tampilan, tidak memengaruhi hasil atau progres apa pun.';
  @override
  String slotName(AccessorySlot slot) {
    switch (slot) {
      case AccessorySlot.head:
        return 'Kepala';
      case AccessorySlot.face:
        return 'Wajah';
      case AccessorySlot.neck:
        return 'Leher';
      case AccessorySlot.back:
        return 'Punggung';
    }
  }

  @override
  String accessoryName(CharacterAccessory accessory) {
    const names = {
      CharacterAccessory.beanie: 'Kupluk',
      CharacterAccessory.ribbon: 'Pita',
      CharacterAccessory.flower: 'Bunga',
      CharacterAccessory.witchHat: 'Topi penyihir',
      CharacterAccessory.headphones: 'Headphone',
      CharacterAccessory.halo: 'Lingkaran cahaya',
      CharacterAccessory.roundGlasses: 'Kacamata bulat',
      CharacterAccessory.starStickers: 'Stiker bintang',
      CharacterAccessory.sunglasses: 'Kacamata hitam',
      CharacterAccessory.scarf: 'Syal',
      CharacterAccessory.necklace: 'Kalung',
      CharacterAccessory.backpack: 'Ransel',
      CharacterAccessory.cape: 'Jubah',
      CharacterAccessory.wings: 'Sayap',
      CharacterAccessory.jungCrown: 'Mahkota rune',
      CharacterAccessory.jungMask: 'Topeng persona',
      CharacterAccessory.jungCompass: 'Kompas batin',
      CharacterAccessory.jungLantern: 'Lentera batin',
      CharacterAccessory.tempFlame: 'Api semangat',
      CharacterAccessory.tempMonocle: 'Monokel cermat',
      CharacterAccessory.tempLeaf: 'Kalung daun',
      CharacterAccessory.tempWave: 'Ombak tenang',
      CharacterAccessory.attNightCap: 'Topi tidur',
      CharacterAccessory.attHeartCharm: 'Hati mungil',
      CharacterAccessory.attBlanket: 'Selimut aman',
      CharacterAccessory.attCompanion: 'Teman kecil',
    };
    return names[accessory] ?? accessory.id;
  }

  @override
  String get accessoryEquipped => 'Dipakai';
  @override
  String get accessoryRemove => 'Lepas';
  @override
  String accessoryBought(String name) => '$name terbeli dan langsung dipakai.';
  @override
  String accessoryConfirmLabel(String name) => 'Aksesori $name';
  @override
  String get accessoryExclusive => 'Eksklusif';
  @override
  String get bundlesTitle => 'Paket hemat';
  @override
  String get bundlesBody => 'Beli beberapa sekaligus lebih murah. Yang sudah kamu punya tidak ikut ditagih.';
  @override
  String bundleName(AccessoryBundle bundle) {
    const names = {
      AccessoryBundle.cozy: 'Paket Nyaman',
      AccessoryBundle.stylish: 'Paket Gaya',
      AccessoryBundle.heavenly: 'Paket Surgawi',
      AccessoryBundle.jungSet: 'Paket Jiwa Jung',
      AccessoryBundle.temperamentSet: 'Paket Temperamen',
      AccessoryBundle.attachmentSet: 'Paket Keterikatan',
    };
    return names[bundle] ?? bundle.id;
  }

  @override
  String bundleItems(int count) => '$count item';
  @override
  String bundleSave(int coins) => 'Hemat $coins koin';
  @override
  String bundleBuy(int price) => 'Beli · $price koin';
  @override
  String bundleBought(String name) => '$name terbeli dan langsung dipakai.';
  @override
  String bundleConfirmLabel(String name) => name;

  @override
  String get homeTitle => 'Karaktermu';
  @override
  String get homeMonsterLabel => 'Monster yang sedang kamu jinakkan';
  @override
  String homeMonsterProgress(int percent) => '$percent% menuju jinak';
  @override
  String get homeSeeAll => 'Lihat semua';
  @override
  String homeTestShort(PersonalityTest test) {
    switch (test) {
      case PersonalityTest.jung:
        return 'Tipe';
      case PersonalityTest.temperament:
        return 'Temperamen';
      case PersonalityTest.attachment:
        return 'Keterikatan';
    }
  }

  @override
  String get homeTakeTest => 'Isi tes';

  @override
  ProfileText jungType(String code) {
    final base = _jung[code];
    if (base == null || code.length != 4) return const ProfileText(name: '', tagline: '', strengths: [], growth: '');
    return ProfileText(
      name: base.name,
      tagline: base.tagline,
      strengths: [poleStrength(code[0]), poleStrength(code[2])],
      growth: poleGrowth(code[3]),
    );
  }

  @override
  String poleStrength(String letter) => _poleStrengths[letter] ?? '';
  @override
  String poleGrowth(String letter) => _poleGrowths[letter] ?? '';
  @override
  ProfileText temperament(String key) => _temperaments[key] ?? const ProfileText(name: '', tagline: '', strengths: [], growth: '');
  @override
  ProfileText attachment(String key) => _attachments[key] ?? const ProfileText(name: '', tagline: '', strengths: [], growth: '');

  @override
  String get signalsTitle => 'Pola dari jurnalmu';
  @override
  String get signalsNote => 'Dihitung di perangkatmu dari suasana hati dan jam menulis, tanpa membaca isi tulisanmu.';
  @override
  String get signalsEmpty => 'Tulis beberapa entri jurnal dulu, nanti pola halusnya muncul di sini.';
  @override
  String signalEntries(int count) => '$count entri dalam 30 hari terakhir';
  @override
  String signalMood(String label) => 'Suasana yang paling sering: $label';
  @override
  String signalPeriod(String period) => 'Biasanya menulis di $period';
  @override
  String signalMonster(String monsterName) => 'Tema yang sering muncul: $monsterName';
  @override
  String moodLabel(String moodId) => _moods[moodId] ?? moodId;
  @override
  String periodLabel(String period) {
    const labels = {'morning': 'pagi hari', 'afternoon': 'siang hari', 'evening': 'sore hari', 'night': 'malam hari'};
    return labels[period] ?? period;
  }
}

class KepribadianStringsEn extends KepribadianStrings {
  const KepribadianStringsEn();

  static const _questions = {
    'j_ei_1': 'I feel energized after talking with lots of people.',
    'j_ei_2': 'After a whole day with others, I need time alone to recharge.',
    'j_ei_3': 'I easily start conversations with people I have just met.',
    'j_ei_4': 'I am more comfortable thinking things through alone before talking about them.',
    'j_ei_5': 'I enjoy being the center of attention among my friends.',
    'j_ei_6': 'I prefer one-on-one or small-group chats over crowds.',
    'j_sn_1': 'I trust what I can see and verify directly.',
    'j_sn_2': 'I often get absorbed in possibilities and the meaning behind things.',
    'j_sn_3': 'I like clear instructions with concrete steps.',
    'j_sn_4': 'I am drawn to new ideas even when their use is unclear.',
    'j_sn_5': 'I notice small details that others often miss.',
    'j_sn_6': 'I usually see the big picture before the details.',
    'j_tf_1': 'When deciding, I put logic and facts first.',
    'j_tf_2': 'Other people\'s feelings strongly shape my decisions.',
    'j_tf_3': 'I can judge an idea without being swayed by how I feel about the person behind it.',
    'j_tf_4': 'I try to keep the peace, even if it means giving in.',
    'j_tf_5': 'I would rather be honest than keep the mood smooth.',
    'j_tf_6': 'I easily feel what the people around me are feeling.',
    'j_jp_1': 'I feel calm when my plans are clearly laid out.',
    'j_jp_2': 'I prefer letting plans flow and adjusting along the way.',
    'j_jp_3': 'I like finishing tasks well before the deadline.',
    'j_jp_4': 'I often only get motivated close to a deadline.',
    'j_jp_5': 'I am comfortable with regular schedules and routines.',
    'j_jp_6': 'I like keeping my options open and putting off deciding.',
    't_san_1': 'I get excited easily and pass that energy on to others.',
    't_kol_1': 'I like leading and making quick decisions.',
    't_mel_1': 'I think things through very carefully and deeply.',
    't_fle_1': 'I stay calm when others panic.',
    't_san_2': 'I get close to people fast and enjoy lively settings.',
    't_kol_2': 'I get impatient when things move slowly.',
    't_mel_2': 'I hold high standards for my own work.',
    't_fle_2': 'I am patient and not easily provoked.',
    't_san_3': 'I often act on impulse and think about it afterwards.',
    't_kol_3': 'I focus on goals and the end result.',
    't_mel_3': 'I often dwell on what went wrong or could be better.',
    't_fle_3': 'I would rather give way than argue.',
    't_san_4': 'My mood lifts quickly, but it also changes quickly.',
    't_kol_4': 'I speak my mind openly, sometimes too bluntly.',
    't_mel_4': 'I am sensitive to subtle moods and feelings.',
    't_fle_4': 'I am comfortable with a relaxed, steady pace.',
    't_san_5': 'I love telling stories and making people laugh.',
    't_kol_5': 'Challenges only make me more motivated.',
    't_mel_5': 'I need quiet time to think and feel.',
    't_fle_5': 'I am often the peacemaker in a disagreement.',
    'a_cemas_1': 'I often worry that the people closest to me will leave.',
    'a_hindar_1': 'I feel uncomfortable when people get too close emotionally.',
    'a_cemas_2': 'I need frequent reassurance that I am loved.',
    'a_hindar_2': 'I prefer handling my problems alone rather than talking about them.',
    'a_cemas_3': 'When my message goes unanswered for long, my mind races.',
    'a_hindar_3': 'I find it hard to depend on other people.',
    'a_cemas_4': 'I fear the attention of those close to me will fade without my knowing why.',
    'a_hindar_4': 'I feel comfortable sharing my deepest feelings with people close to me.',
    'a_cemas_5': 'I rarely worry about whether the people close to me really care.',
    'a_hindar_5': 'I tend to keep my distance once a relationship starts feeling serious.',
    'a_cemas_6': 'I easily feel jealous or left out.',
    'a_hindar_6': 'I enjoy depending on, and being needed by, the people I love.',
  };

  static const _jung = {
    'ENFP': ProfileText(name: 'The Idea Spark', tagline: 'Full of ideas, warm, and great at lifting people\'s spirits.', strengths: [], growth: ''),
    'ENFJ': ProfileText(name: 'The Warm Guide', tagline: 'Attuned to others and good at bringing them together.', strengths: [], growth: ''),
    'ENTP': ProfileText(name: 'The Playful Challenger', tagline: 'Loves friendly debate and trying new ways.', strengths: [], growth: ''),
    'ENTJ': ProfileText(name: 'The Helmsman', tagline: 'Sets direction firmly and moves people toward the goal.', strengths: [], growth: ''),
    'ESFP': ProfileText(name: 'The Room Lighter', tagline: 'Lives in the moment and brings everyone to life.', strengths: [], growth: ''),
    'ESFJ': ProfileText(name: 'The Community Weaver', tagline: 'Caring and tidy in looking after the people close to them.', strengths: [], growth: ''),
    'ESTP': ProfileText(name: 'The Quick Mover', tagline: 'Reads a situation fast and acts right away.', strengths: [], growth: ''),
    'ESTJ': ProfileText(name: 'The Organizer', tagline: 'Sets the rules and makes sure things run.', strengths: [], growth: ''),
    'INFP': ProfileText(name: 'The Gentle Dreamer', tagline: 'A rich inner world and values held firmly.', strengths: [], growth: ''),
    'INFJ': ProfileText(name: 'The Heart Seer', tagline: 'Quiet, deep, and often senses what goes unsaid.', strengths: [], growth: ''),
    'INTP': ProfileText(name: 'The Logic Explorer', tagline: 'Loves taking apart how everything works.', strengths: [], growth: ''),
    'INTJ': ProfileText(name: 'The Long-Range Planner', tagline: 'Plans far ahead with a cool head.', strengths: [], growth: ''),
    'ISFP': ProfileText(name: 'The Quiet Artist', tagline: 'Gentle, alive to beauty, and true to themselves.', strengths: [], growth: ''),
    'ISFJ': ProfileText(name: 'The Steady Guardian', tagline: 'Quietly caring and dependable.', strengths: [], growth: ''),
    'ISTP': ProfileText(name: 'The Tinkerer', tagline: 'Calm, practical, and great at solving problems by hand.', strengths: [], growth: ''),
    'ISTJ': ProfileText(name: 'The Reliable Detail-Keeper', tagline: 'Consistent, honest, and keeps their word.', strengths: [], growth: ''),
  };

  static const _poleStrengths = {
    'E': 'Easily warms a room and gets people moving.',
    'I': 'Deep and focused when thinking something through.',
    'S': 'Careful and grounded in what is real.',
    'N': 'Sees patterns and possibilities others miss.',
    'T': 'Clear in weighing facts and cause and effect.',
    'F': 'Sensitive and sincere in caring for people\'s feelings.',
    'J': 'Organized and dependable.',
    'P': 'Flexible and quick to adapt.',
  };

  static const _poleGrowths = {
    'E': 'Set aside time alone so your energy does not run out.',
    'I': 'Now and then share your thoughts earlier, people want to hear them.',
    'S': 'Leave room for possibilities that are not yet proven.',
    'N': 'Turn the big idea into one small step today.',
    'T': 'Deliver your honesty with warmth.',
    'F': 'You deserve a turn too, do not always give way.',
    'J': 'Leave room for plans that change.',
    'P': 'Set one small deadline to keep momentum.',
  };

  static const _temperaments = {
    'sanguinis': ProfileText(
      name: 'Sanguine',
      tagline: 'Cheerful, friendly, and full of color.',
      strengths: ['Easy to get along with and spreads enthusiasm', 'Bounces back fast and sees the bright side'],
      growth: 'Practice finishing one thing before moving to the next.',
    ),
    'koleris': ProfileText(
      name: 'Choleric',
      tagline: 'Decisive, bold, and results-driven.',
      strengths: ['Bold at deciding and leading', 'Persistent in pursuing goals'],
      growth: 'Make room to listen before deciding.',
    ),
    'melankolis': ProfileText(
      name: 'Melancholic',
      tagline: 'Deep, thorough, and sensitive.',
      strengths: ['Careful and high-quality in their work', 'Sensitive to feelings and meaning'],
      growth: 'Remember that good enough is good, it need not be perfect.',
    ),
    'flegmatis': ProfileText(
      name: 'Phlegmatic',
      tagline: 'Calm, patient, and a steadying presence.',
      strengths: ['Stable and calming for others', 'A good listener and peacemaker'],
      growth: 'Voice what you want, you do not always have to give way.',
    ),
  };

  static const _attachments = {
    'aman': ProfileText(
      name: 'Secure',
      tagline: 'Comfortable with closeness and comfortable alone.',
      strengths: ['Trusts and opens up to close people easily', 'Can both ask for and give support'],
      growth: 'Keep listening to your body and heart when a relationship feels heavy.',
    ),
    'cemas': ProfileText(
      name: 'Anxious',
      tagline: 'Deeply caring, and often in need of reassurance.',
      strengths: ['Caring and attuned to the relationship', 'Brave in showing the need for closeness'],
      growth: 'Try calming yourself first through breathing or writing before asking for reassurance.',
    ),
    'menghindar': ProfileText(
      name: 'Avoidant',
      tagline: 'Values independence and personal space.',
      strengths: ['Independent and calm with problems', 'Respects their own and others\' boundaries'],
      growth: 'Try sharing one small thing with someone you trust, slowly.',
    ),
    'cemas_menghindar': ProfileText(
      name: 'Anxious-Avoidant',
      tagline: 'Wants closeness, but fears getting hurt.',
      strengths: ['Very aware of relationship dynamics', 'A big capacity for understanding themselves'],
      growth: 'Give yourself time; building a sense of safety can be practiced slowly, alone or with a professional.',
    ),
  };

  static const _moods = {
    'berat': 'heavy',
    'agak_berat': 'somewhat heavy',
    'datar': 'flat',
    'cukup_baik': 'fairly good',
    'senang': 'happy',
  };

  @override
  String get title => 'Know yourself';
  @override
  String get subtitle => 'Three ways to see yourself, with a character made just for you.';
  @override
  String get disclaimer => 'This is a self-reflection tool, not a diagnosis or clinical assessment. Results can change over time and with circumstances.';
  @override
  String testName(PersonalityTest test) {
    switch (test) {
      case PersonalityTest.jung:
        return '16 Jungian-style types';
      case PersonalityTest.temperament:
        return 'Four temperaments';
      case PersonalityTest.attachment:
        return 'Attachment style';
    }
  }

  @override
  String testBlurb(PersonalityTest test) {
    switch (test) {
      case PersonalityTest.jung:
        return 'How you recharge, take in information, decide, and organize your life.';
      case PersonalityTest.temperament:
        return 'The base color of your character in the four temperaments tradition.';
      case PersonalityTest.attachment:
        return 'Your pattern of closeness with the people you love.';
    }
  }

  @override
  String questionCount(int count) => '$count questions';
  @override
  String get notTakenYet => 'Not taken yet';
  @override
  String get startTest => 'Start';
  @override
  String get seeResult => 'See result';
  @override
  String get retake => 'Retake';

  @override
  String progress(int current, int total) => '$current of $total';
  @override
  List<String> get scaleLabels => const ['Strongly disagree', 'Disagree', 'Neutral', 'Agree', 'Strongly agree'];
  @override
  String get next => 'Next';
  @override
  String get previous => 'Previous';
  @override
  String get finish => 'See result';
  @override
  String question(String id) => _questions[id] ?? id;
  @override
  String get exitTitle => 'Leave the test?';
  @override
  String get exitBody => 'Your answers are not saved yet. You can retake it anytime.';

  @override
  String get resultKicker => 'YOUR CHARACTER';
  @override
  String get strengthsTitle => 'Your strengths';
  @override
  String get growthTitle => 'Something to practice';
  @override
  String get scoresTitle => 'Your tendencies';
  @override
  String get gentleNote => 'No result is better than another. This is just a mirror to know yourself.';
  @override
  String get blendWith => 'blended with';
  @override
  String axisLabel(String key) {
    const labels = {
      'E': 'Extraversion', 'I': 'Introversion', 'S': 'Sensing (concrete)', 'N': 'Intuition (ideas)', 'T': 'Thinking', 'F': 'Feeling', 'J': 'Planned', 'P': 'Spontaneous',
      'sanguinis': 'Sanguine', 'koleris': 'Choleric', 'melankolis': 'Melancholic', 'flegmatis': 'Phlegmatic',
      'cemas': 'Anxiety', 'menghindar': 'Avoidance',
    };
    return labels[key] ?? key;
  }

  @override
  String get shareCard => 'Share card';
  @override
  String get saveImage => 'Save image';
  @override
  String get imageSaved => 'Card saved to your gallery.';
  @override
  String get imageSaveFailed => 'Could not save the image. Please try again.';
  @override
  String get imageShareFailed => 'Could not share the card. Please try again.';
  @override
  String shareText(String name) => 'I am $name on Riung 🌙 Find your own character too: https://play.google.com/store/apps/details?id=com.riung.riung #Riung #KnowYourself';
  @override
  String cardTagline(PersonalityTest test) => 'Know yourself on Riung';

  @override
  String get stylesTitle => 'Card styles';
  @override
  String get stylesBody => 'Change how your card looks. Looks only, it does not affect any result or progress.';
  @override
  String styleName(String id) {
    const names = {'klasik': 'Classic', 'taman': 'Garden', 'arkade': 'Arcade', 'galaksi': 'Galaxy', 'aurora': 'Aurora'};
    return names[id] ?? id;
  }

  @override
  String get styleOwned => 'Owned';
  @override
  String get styleSelected => 'In use';
  @override
  String styleBuy(int price) => '$price coins';
  @override
  String styleBought(String name) => '$name style unlocked.';
  @override
  String styleConfirmLabel(String name) => '$name card style';

  @override
  String get customizeTitle => 'Customize your character';
  @override
  String get customizeBody => 'Put little extras on your character. Looks only, it does not affect any result or progress.';
  @override
  String slotName(AccessorySlot slot) {
    switch (slot) {
      case AccessorySlot.head:
        return 'Head';
      case AccessorySlot.face:
        return 'Face';
      case AccessorySlot.neck:
        return 'Neck';
      case AccessorySlot.back:
        return 'Back';
    }
  }

  @override
  String accessoryName(CharacterAccessory accessory) {
    const names = {
      CharacterAccessory.beanie: 'Beanie',
      CharacterAccessory.ribbon: 'Ribbon',
      CharacterAccessory.flower: 'Flower',
      CharacterAccessory.witchHat: 'Witch hat',
      CharacterAccessory.headphones: 'Headphones',
      CharacterAccessory.halo: 'Halo',
      CharacterAccessory.roundGlasses: 'Round glasses',
      CharacterAccessory.starStickers: 'Star stickers',
      CharacterAccessory.sunglasses: 'Sunglasses',
      CharacterAccessory.scarf: 'Scarf',
      CharacterAccessory.necklace: 'Necklace',
      CharacterAccessory.backpack: 'Backpack',
      CharacterAccessory.cape: 'Cape',
      CharacterAccessory.wings: 'Wings',
      CharacterAccessory.jungCrown: 'Rune crown',
      CharacterAccessory.jungMask: 'Persona mask',
      CharacterAccessory.jungCompass: 'Inner compass',
      CharacterAccessory.jungLantern: 'Inner lantern',
      CharacterAccessory.tempFlame: 'Spirit flame',
      CharacterAccessory.tempMonocle: 'Careful monocle',
      CharacterAccessory.tempLeaf: 'Leaf necklace',
      CharacterAccessory.tempWave: 'Calm wave',
      CharacterAccessory.attNightCap: 'Night cap',
      CharacterAccessory.attHeartCharm: 'Tiny hearts',
      CharacterAccessory.attBlanket: 'Safe blanket',
      CharacterAccessory.attCompanion: 'Little companion',
    };
    return names[accessory] ?? accessory.id;
  }

  @override
  String get accessoryEquipped => 'Equipped';
  @override
  String get accessoryRemove => 'Remove';
  @override
  String accessoryBought(String name) => '$name bought and equipped.';
  @override
  String accessoryConfirmLabel(String name) => '$name accessory';
  @override
  String get accessoryExclusive => 'Exclusive';
  @override
  String get bundlesTitle => 'Value bundles';
  @override
  String get bundlesBody => 'Buying several at once costs less. Items you already own are not charged.';
  @override
  String bundleName(AccessoryBundle bundle) {
    const names = {
      AccessoryBundle.cozy: 'Cozy bundle',
      AccessoryBundle.stylish: 'Stylish bundle',
      AccessoryBundle.heavenly: 'Heavenly bundle',
      AccessoryBundle.jungSet: 'Jung soul bundle',
      AccessoryBundle.temperamentSet: 'Temperament bundle',
      AccessoryBundle.attachmentSet: 'Attachment bundle',
    };
    return names[bundle] ?? bundle.id;
  }

  @override
  String bundleItems(int count) => '$count items';
  @override
  String bundleSave(int coins) => 'Save $coins coins';
  @override
  String bundleBuy(int price) => 'Buy · $price coins';
  @override
  String bundleBought(String name) => '$name bought and equipped.';
  @override
  String bundleConfirmLabel(String name) => name;

  @override
  String get homeTitle => 'Your characters';
  @override
  String get homeMonsterLabel => 'The monster you are taming';
  @override
  String homeMonsterProgress(int percent) => '$percent% to tamed';
  @override
  String get homeSeeAll => 'See all';
  @override
  String homeTestShort(PersonalityTest test) {
    switch (test) {
      case PersonalityTest.jung:
        return 'Type';
      case PersonalityTest.temperament:
        return 'Temperament';
      case PersonalityTest.attachment:
        return 'Attachment';
    }
  }

  @override
  String get homeTakeTest => 'Take the test';

  @override
  ProfileText jungType(String code) {
    final base = _jung[code];
    if (base == null || code.length != 4) return const ProfileText(name: '', tagline: '', strengths: [], growth: '');
    return ProfileText(
      name: base.name,
      tagline: base.tagline,
      strengths: [poleStrength(code[0]), poleStrength(code[2])],
      growth: poleGrowth(code[3]),
    );
  }

  @override
  String poleStrength(String letter) => _poleStrengths[letter] ?? '';
  @override
  String poleGrowth(String letter) => _poleGrowths[letter] ?? '';
  @override
  ProfileText temperament(String key) => _temperaments[key] ?? const ProfileText(name: '', tagline: '', strengths: [], growth: '');
  @override
  ProfileText attachment(String key) => _attachments[key] ?? const ProfileText(name: '', tagline: '', strengths: [], growth: '');

  @override
  String get signalsTitle => 'Patterns from your journal';
  @override
  String get signalsNote => 'Computed on your device from mood and writing time, without reading what you wrote.';
  @override
  String get signalsEmpty => 'Write a few journal entries first, and gentle patterns will show up here.';
  @override
  String signalEntries(int count) => count == 1 ? '1 entry in the last 30 days' : '$count entries in the last 30 days';
  @override
  String signalMood(String label) => 'Most frequent mood: $label';
  @override
  String signalPeriod(String period) => 'Usually writes in the $period';
  @override
  String signalMonster(String monsterName) => 'Recurring theme: $monsterName';
  @override
  String moodLabel(String moodId) => _moods[moodId] ?? moodId;
  @override
  String periodLabel(String period) {
    const labels = {'morning': 'morning', 'afternoon': 'afternoon', 'evening': 'evening', 'night': 'night'};
    return labels[period] ?? period;
  }
}
