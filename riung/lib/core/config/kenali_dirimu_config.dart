/// Katalog "Kenali Dirimu" — satu-satunya tempat pemetaan tes → bagian hub,
/// topik, dan monster yang dibangunkan/ditautkan (CLAUDE.md aturan #8:
/// mapping di config, bukan hardcode di layar). Isi soal & rentang skor
/// ada di `assets/data/know_yourself/*.json`.
///
/// Garis yang tidak boleh dilanggar:
/// - Tes [KenaliSection.kesehatan] TIDAK PERNAH memberi monster, koin, atau
///   peringkat — hasilnya cuma refleksi + langkah berikutnya.
/// - Hanya [KenaliSection.kuisBesar] yang membangunkan Monster Kebiasaan.
///   Tes Diri & Relasi hanya MENAUTKAN ke Monster Pikiran yang sudah ada.
library;

enum KenaliSection { kuisBesar, kepribadian, diriRelasi, kesehatan }

/// Kicker topik di kartu hub ("KEBIASAAN", "EMOSI", …).
enum KenaliTopic { kebiasaan, tidur, emosi, relasi, pikiran, kepribadian, diri, kesejahteraan, perhatian, masaLalu }

/// Langkah kecil di hasil tes kesehatan (frame `Langkah kecil`).
enum KenaliStep { napas, cekPikiran, checkin, jurnalRasa, tidurTenang, meditasi }

/// Fitur app yang bisa dibuka dari langkah kecil / latihan di peta.
enum KenaliFeature { fokus, jurnal, checkin, meditasi, aplikasiBeku, tidur, afirmasi, laporan }

class KenaliEntry {
  const KenaliEntry({
    required this.id,
    required this.file,
    required this.section,
    required this.topic,
    this.monsterId,
    this.traitMonsters = const {},
    this.healthyTraits = const {},
    this.wakeMinScore,
    this.badge = false,
    this.wujudOrder = const [],
  });

  /// Sama dengan `id` di JSON tes.
  final String id;
  final String file;
  final KenaliSection section;
  final KenaliTopic topic;

  /// Kuis Besar: Monster Kebiasaan yang dibangunkan. Diri & Relasi:
  /// Monster Pikiran yang ditautkan (chip di hub & kartu di hasil).
  final String? monsterId;

  /// Trait dominan → monster tertaut (mis. Kritikus Batin).
  final Map<String, String> traitMonsters;

  /// Trait sehat yang TIDAK membangunkan monster (mis. "Intentional").
  final Set<String> healthyTraits;

  /// Tes jumlah: monster bangun hanya bila skor ≥ nilai ini.
  final int? wakeMinScore;

  /// Hasilnya berupa lencana (bukan monster).
  final bool badge;

  /// Urutan wujud di layar intro (default: urutan trait di soal).
  final List<String> wujudOrder;

  String get asset => '${KenaliDirimuConfig.assetDir}/$file';

  /// Terjemahan teks tes (`<assetDir>/<kode bahasa>/<file>`), mis. `en/`.
  String translationAsset(String languageCode) => '${KenaliDirimuConfig.assetDir}/$languageCode/$file';

  bool get wakesMonster => section == KenaliSection.kuisBesar && monsterId != null;

  /// Monster yang dibangunkan/ditautkan untuk satu hasil, atau null.
  String? monsterFor({String? dominantTrait, int? score}) {
    if (section == KenaliSection.kesehatan) return null;
    if (dominantTrait != null && healthyTraits.contains(dominantTrait)) return null;
    final minScore = wakeMinScore;
    if (minScore != null && (score ?? 0) < minScore) return null;
    if (dominantTrait != null && traitMonsters[dominantTrait] != null) return traitMonsters[dominantTrait];
    return monsterId;
  }
}

abstract final class KenaliDirimuConfig {
  static const assetDir = 'assets/data/know_yourself';

  /// Perkiraan menit = jumlah soal ÷ 4, dibulatkan (24 soal ≈ 6 menit).
  static const int soalPerMenit = 4;

  /// Tes kesehatan disarankan diulang setelah sekian hari ("Ulangi 16 Okt").
  static const int ulangiKesehatanHari = 14;

  /// Riwayat menyimpan paling banyak sekian percobaan terakhir per tes.
  static const int riwayatPerTes = 10;

  /// Tiga tes kepribadian lama (fitur `kepribadian/`) ikut dihitung di hub.
  static const int jumlahTesKepribadian = 3;

  static int menitUntuk(int jumlahSoal) => (jumlahSoal / soalPerMenit).round().clamp(1, 60);

  static const entries = <KenaliEntry>[
    // Kuis Besar — tiap kuis membangunkan satu Monster Kebiasaan.
    KenaliEntry(
      id: 'procrastination_profile',
      file: 'procrastination_profile_test.json',
      section: KenaliSection.kuisBesar,
      topic: KenaliTopic.kebiasaan,
      monsterId: 'nanti',
      wujudOrder: ['Perfectionist', 'Overwhelmed', 'BusyBee', 'ThrillSeeker'],
    ),
    KenaliEntry(
      id: 'phone_relationship_test',
      file: 'phone_relationship_test.json',
      section: KenaliSection.kuisBesar,
      topic: KenaliTopic.kebiasaan,
      monsterId: 'gulir',
      healthyTraits: {'Intentional'},
      wujudOrder: ['Scroller', 'Anxious'],
    ),
    KenaliEntry(
      id: 'evening_sleep_test',
      file: 'evening_sleep_test.json',
      section: KenaliSection.kuisBesar,
      topic: KenaliTopic.tidur,
      monsterId: 'begadang',
      wujudOrder: ['Revenge', 'Anxious', 'Dopamine'],
    ),
    KenaliEntry(
      id: 'anger_test',
      file: 'anger_test.json',
      section: KenaliSection.kuisBesar,
      topic: KenaliTopic.emosi,
      monsterId: 'bara',
      // Rentang "Reaktif Sedang" ke atas.
      wakeMinScore: 14,
    ),
    KenaliEntry(
      id: 'people_pleaser_test',
      file: 'people_pleaser_test.json',
      section: KenaliSection.kuisBesar,
      topic: KenaliTopic.relasi,
      monsterId: 'bunglon',
      wujudOrder: ['Chameleon', 'Rescuer', 'Peacekeeper'],
    ),
    KenaliEntry(
      id: 'decision_making_test',
      file: 'decision_making_test.json',
      section: KenaliSection.kuisBesar,
      topic: KenaliTopic.pikiran,
      monsterId: 'bimbang',
      wujudOrder: ['Overthinker', 'Consensus', 'Impulsive'],
    ),
    // Diri & Relasi — menautkan ke Monster Pikiran, tidak membangunkan.
    KenaliEntry(id: 'self_esteem_test', file: 'self_esteem_test.json', section: KenaliSection.diriRelasi, topic: KenaliTopic.diri, monsterId: 'hakim'),
    KenaliEntry(id: 'stress_coping_test', file: 'stress_coping_test.json', section: KenaliSection.diriRelasi, topic: KenaliTopic.emosi, monsterId: 'mengelak'),
    KenaliEntry(
      id: 'inner_critic_test',
      file: 'inner_critic_test.json',
      section: KenaliSection.diriRelasi,
      topic: KenaliTopic.pikiran,
      monsterId: 'sempurna',
      traitMonsters: {'Taskmaster': 'sempurna', 'GuiltTripper': 'hakim', 'MindReader': 'cermin'},
    ),
    KenaliEntry(id: 'toxic_trait_test', file: 'toxic_trait_test.json', section: KenaliSection.diriRelasi, topic: KenaliTopic.kepribadian),
    KenaliEntry(id: 'difficult_person_test', file: 'difficult_person_test.json', section: KenaliSection.diriRelasi, topic: KenaliTopic.kepribadian, monsterId: 'meronta'),
    KenaliEntry(id: 'eq_test', file: 'eq_test.json', section: KenaliSection.diriRelasi, topic: KenaliTopic.emosi, badge: true),
    KenaliEntry(id: 'likeable_person_test', file: 'likeable_person_test.json', section: KenaliSection.diriRelasi, topic: KenaliTopic.kepribadian, badge: true),
    // Kesehatan Mental — skrining tenang & privat, TANPA monster.
    KenaliEntry(id: 'depression_test', file: 'depression_test.json', section: KenaliSection.kesehatan, topic: KenaliTopic.emosi),
    KenaliEntry(id: 'anxiety_test', file: 'anxiety_test.json', section: KenaliSection.kesehatan, topic: KenaliTopic.emosi),
    KenaliEntry(id: 'burnout_test', file: 'burnout_test.json', section: KenaliSection.kesehatan, topic: KenaliTopic.kesejahteraan),
    KenaliEntry(id: 'well_being_test', file: 'well_being_test.json', section: KenaliSection.kesehatan, topic: KenaliTopic.kesejahteraan),
    KenaliEntry(id: 'adhd_test', file: 'adhd_test.json', section: KenaliSection.kesehatan, topic: KenaliTopic.perhatian),
    KenaliEntry(id: 'ocd_test', file: 'ocd_test.json', section: KenaliSection.kesehatan, topic: KenaliTopic.pikiran),
    KenaliEntry(id: 'bpd_test', file: 'bpd_test.json', section: KenaliSection.kesehatan, topic: KenaliTopic.emosi),
    KenaliEntry(id: 'neurodivergent_test', file: 'neurodivergent_test.json', section: KenaliSection.kesehatan, topic: KenaliTopic.perhatian),
    KenaliEntry(id: 'childhood_trauma_test', file: 'childhood_trauma_test.json', section: KenaliSection.kesehatan, topic: KenaliTopic.masaLalu),
    KenaliEntry(id: 'narcissistic_partner_test', file: 'narcissistic_partner_test.json', section: KenaliSection.kesehatan, topic: KenaliTopic.relasi),
  ];

  static KenaliEntry? byId(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  static List<KenaliEntry> inSection(KenaliSection s) => [for (final e in entries) if (e.section == s) e];

  /// Kuis Besar yang membangunkan [monsterId] (Monster Kebiasaan).
  static KenaliEntry? quizForMonster(String monsterId) {
    for (final e in entries) {
      if (e.wakesMonster && e.monsterId == monsterId) return e;
    }
    return null;
  }

  /// Tiga langkah kecil di hasil tes kesehatan, per tes.
  static List<KenaliStep> stepsFor(String testId) => switch (testId) {
        'anxiety_test' => const [KenaliStep.napas, KenaliStep.cekPikiran, KenaliStep.checkin],
        'depression_test' || 'childhood_trauma_test' => const [KenaliStep.jurnalRasa, KenaliStep.meditasi, KenaliStep.checkin],
        'burnout_test' || 'well_being_test' => const [KenaliStep.tidurTenang, KenaliStep.meditasi, KenaliStep.checkin],
        'ocd_test' || 'bpd_test' => const [KenaliStep.napas, KenaliStep.jurnalRasa, KenaliStep.checkin],
        _ => const [KenaliStep.meditasi, KenaliStep.jurnalRasa, KenaliStep.checkin],
      };

  static KenaliFeature featureForStep(KenaliStep s) => switch (s) {
        KenaliStep.napas || KenaliStep.meditasi => KenaliFeature.meditasi,
        KenaliStep.cekPikiran || KenaliStep.jurnalRasa => KenaliFeature.jurnal,
        KenaliStep.checkin => KenaliFeature.checkin,
        KenaliStep.tidurTenang => KenaliFeature.tidur,
      };

  /// Monster Kebiasaan, urut seperti di Kuis Besar.
  static List<String> get habitMonsters => [
        for (final e in entries)
          if (e.wakesMonster) e.monsterId!,
      ];

  /// Total tes & kuis di hub (JSON + tes kepribadian).
  static int get totalTes => entries.length + jumlahTesKepribadian;
}
