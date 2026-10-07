import '../../config/kenali_dirimu_config.dart';

/// Teks fitur "Kenali Dirimu" (hub tes & kuis, hasil, Monster Kebiasaan).
/// Copy Indonesia persis dari frame `Glass — Kenali Dirimu · …` dan
/// `Glass — Monster · Si …` di `design/riung.pen`. Isi soal & deskripsi hasil
/// ada di `assets/data/know_yourself/*.json` (Indonesia saja).
abstract class KenaliStrings {
  const KenaliStrings();

  // ── Hub ─────────────────────────────────────────────────────────────
  String get title;
  String get hubHeading;
  String get hubIntro;
  String hubProgress(int done, int total);
  String get tabAll;
  String get tabKuis;
  String get tabTes;
  String sectionTitle(KenaliSection s);
  String sectionSub(KenaliSection s);
  String get healthPrivacyNote;
  String get hubFooter;
  String get hubFooterCrisis;
  String topicLabel(KenaliTopic t);
  String entryTitle(String id);
  String get kepribadianJung;
  String get kepribadianAttachment;
  String get kepribadianTemperament;
  String get openCharacter;
  String awoke(String monsterName);
  String asleepChip(String monsterName);
  String meta(int questions, int minutes);
  String get badgeChip;
  String get retake;

  // ── Intro ───────────────────────────────────────────────────────────
  String introKicker(KenaliSection s);
  String entryBlurb(String id, String fallback);
  String chipQuestions(int n);
  String chipMinutes(int m);
  String get chipPrivate;
  String wujudHeading(String monsterName);
  String introWakeNote(String monsterName);
  String get introBaraNote;
  String introLinkedNote(String monsterName);
  String get introBadgeNote;
  String get introHealthNote;
  String get introTip;
  String sourceLine(String reference);
  String healthSourceLine(String reference);
  String startButton(KenaliSection s);

  // ── Soal ────────────────────────────────────────────────────────────
  String progress(int current, int total);
  String get exitTitle;
  String get exitBody;
  String get previous;
  String get finish;

  // ── Hasil kuis / tes ────────────────────────────────────────────────
  String get resultHeading;
  String breakdownTitle(String testId);
  String breakdownNote(int perTrait, int traitCount);
  String awokeTitle(String monsterName);
  String awokeBody(String monsterId);
  String newPractices(int n);
  String stillAsleepTitle(String monsterName);
  String get stillAsleepBody;
  String traitTip(String testId, String trait);
  String get save;
  String get startTaming;
  String get done;
  String get disclaimer;
  String scoreLine(int score, int max);
  String linkedTitle(String monsterName);
  String linkedBody(String monsterName);
  String get seeMonster;
  String badgeTitle(String category);
  String get badgeBody;

  // ── Hasil tes kesehatan ─────────────────────────────────────────────
  String testHeader(String title);
  String resultDateKicker(String date);
  String healthScoreLine(String testId, int score, int max);
  String get stepsTitle;
  String stepTitle(KenaliStep s);
  String stepSub(KenaliStep s);
  String get proTitle;
  String proBody(String testId);
  String get proCta;
  String get crisisTitle;
  String get crisisSub;
  String get healthPrivacy;
  String retakeOn(String date);

  // ── Monster Kebiasaan ───────────────────────────────────────────────
  String wujudName(String monsterId, String trait);
  String wujudLine(String monsterId, String trait);
  String habitPill(String monsterId);
  String habitRealWorld(String monsterId);
  String get wokeFromEyebrow;
  String quizName(String monsterId);
  String habitWujudList(String monsterId, List<String> names);
  List<String> habitQuotes(String monsterId);
  String habitFact(String monsterId);
  String habitTechnique(String monsterId);
  String habitSpotlight(String monsterId);
  String habitOwl(String monsterId);
  String practiceTitle(String monsterId, int index);
  String practiceHowTo(String monsterId, int index);

  // ── Brankas: tab Pikiran / Kebiasaan ────────────────────────────────
  String tabPikiran(int n);
  String tabKebiasaan(int n);
  String pikiranSub(int tamed, int totalMonsters);
  String habitSub(int awake, int total, int tamed);
  String spotlightKicker(int percent);
  String wokeFrom(String monsterId);
  String spotlightProgress(int percent, int done, int total);
  String get stageMapButton;
  String get otherHabits;
  String get asleep;
  String wakeVia(String monsterId);
  String startArrow(String monsterId);
  String get ctaBody;
  String get ctaOpen;
  String get noneAwakeTitle;
  String get noneAwakeBody;
  String get asleepDetailBody;
  String get takeQuiz;

  // ── Peta latihan kebiasaan ──────────────────────────────────────────
  String stageTitle(String monsterName);
  String lockedAfter(int level);
  String get stepDone;
  String faceMonster(String monsterName);
  String get practiceDoneButton;
  String get practiceNote;
  String openFeature(KenaliFeature f);

  // ── Pintu masuk (Profil & Beranda) ──────────────────────────────────
  String get newPill;
  String profilCardSub(int total, int done);
  String get homeKicker;
  String get homeTitle;
  String homeMeta(String quiz, int minutes);

  // Riwayat
  String get historyTitle;
  String get historyButton;
  String get historyIntro;
  String get historyEmptyTitle;
  String get historyEmptyBody;
  String historyPrivacyNote(int perTest);
}

class KenaliStringsId extends KenaliStrings {
  const KenaliStringsId();

  @override
  String get title => 'Kenali Dirimu';
  @override
  String get hubHeading => 'Kenali pola dirimu';
  @override
  String get hubIntro => 'Tes dan kuis singkat untuk memahami dirimu. Beberapa hasil bisa membangunkan monster yang bisa kamu jinakkan.';
  @override
  String hubProgress(int done, int total) => '$done dari $total selesai';
  @override
  String get tabAll => 'Semua';
  @override
  String get tabKuis => 'Kuis Besar';
  @override
  String get tabTes => 'Tes';
  @override
  String sectionTitle(KenaliSection s) => switch (s) {
        KenaliSection.kuisBesar => 'Kuis Besar',
        KenaliSection.kepribadian => 'Kepribadian',
        KenaliSection.diriRelasi => 'Diri & Relasi',
        KenaliSection.kesehatan => 'Kesehatan Mental',
      };
  @override
  String sectionSub(KenaliSection s) => switch (s) {
        KenaliSection.kuisBesar => 'Profil kebiasaanmu. Tiap kuis membangunkan satu Monster Kebiasaan, dan jawabanmu menentukan wujudnya.',
        KenaliSection.kepribadian => 'Hasilnya membuka karakter pendamping khusus buatmu.',
        KenaliSection.diriRelasi => 'Cara kamu memandang diri dan bersikap ke orang lain.',
        KenaliSection.kesehatan => 'Tes skrining yang tenang dan privat. Tidak membangunkan monster.',
      };
  @override
  String get healthPrivacyNote =>
      'Hasilnya hanya disimpan di perangkatmu dan selalu ditemani langkah berikutnya, termasuk kapan sebaiknya bicara dengan profesional.';
  @override
  String get hubFooter => 'Semua tes di sini adalah alat refleksi diri, bukan diagnosis. Kalau kamu sedang dalam bahaya, buka ';
  @override
  String get hubFooterCrisis => 'Bantuan krisis kapan saja.';
  @override
  String topicLabel(KenaliTopic t) => switch (t) {
        KenaliTopic.kebiasaan => 'KEBIASAAN',
        KenaliTopic.tidur => 'TIDUR',
        KenaliTopic.emosi => 'EMOSI',
        KenaliTopic.relasi => 'RELASI',
        KenaliTopic.pikiran => 'PIKIRAN',
        KenaliTopic.kepribadian => 'KEPRIBADIAN',
        KenaliTopic.diri => 'DIRI',
        KenaliTopic.kesejahteraan => 'KESEJAHTERAAN',
        KenaliTopic.perhatian => 'PERHATIAN',
        KenaliTopic.masaLalu => 'MASA LALU',
      };
  @override
  String entryTitle(String id) => switch (id) {
        'procrastination_profile' => 'Profil Menundamu',
        'phone_relationship_test' => 'Kamu & HP-mu',
        'evening_sleep_test' => 'Malam & Tidurmu',
        'anger_test' => 'Amarahmu',
        'people_pleaser_test' => 'Pandangan Orang',
        'decision_making_test' => 'Kamu & Keputusan',
        'self_esteem_test' => 'Harga Diri',
        'stress_coping_test' => 'Gaya Menghadapi Stres',
        'inner_critic_test' => 'Kritikus Batin',
        'toxic_trait_test' => 'Sifat Toksik',
        'difficult_person_test' => 'Orang yang Sulit?',
        'eq_test' => 'Kecerdasan Emosi',
        'likeable_person_test' => 'Orang yang Menyenangkan',
        'depression_test' => 'Depresi',
        'anxiety_test' => 'Kecemasan',
        'burnout_test' => 'Burnout',
        'well_being_test' => 'Kesejahteraan',
        'adhd_test' => 'ADHD',
        'ocd_test' => 'OCD',
        'bpd_test' => 'BPD',
        'neurodivergent_test' => 'Neurodivergen',
        'childhood_trauma_test' => 'Trauma Masa Kecil',
        'narcissistic_partner_test' => 'Pasangan Narsistik?',
        _ => id,
      };
  @override
  String get kepribadianJung => 'Tipe Kepribadian';
  @override
  String get kepribadianAttachment => 'Gaya Keterikatan';
  @override
  String get kepribadianTemperament => 'Empat Temperamen';
  @override
  String get openCharacter => 'Buka karakter';
  @override
  String awoke(String monsterName) => 'Terbangun: $monsterName';
  @override
  String asleepChip(String monsterName) => '$monsterName tetap tidur';
  @override
  String meta(int questions, int minutes) => '$questions soal · $minutes mnt';
  @override
  String get badgeChip => 'Lencana';
  @override
  String get retake => 'Ulangi';

  @override
  String introKicker(KenaliSection s) => switch (s) {
        KenaliSection.kuisBesar => 'Kuis Besar',
        KenaliSection.kesehatan => 'Kesehatan Mental',
        _ => 'Tes',
      };
  @override
  String entryBlurb(String id, String fallback) => switch (id) {
        'procrastination_profile' => 'Cari tahu alasan di balik kebiasaanmu menunda. Menunda bukan soal malas, tapi soal mengelola perasaan.',
        _ => fallback,
      };
  @override
  String chipQuestions(int n) => '$n soal';
  @override
  String chipMinutes(int m) => '± $m menit';
  @override
  String get chipPrivate => 'Privat';
  @override
  String wujudHeading(String monsterName) => 'WUJUD ${monsterName.toUpperCase()} YANG MUNGKIN';
  @override
  String introWakeNote(String monsterName) =>
      'Yang terbangun selalu $monsterName, wujudnya sesuai jawabanmu. Kamu bisa menjinakkannya lewat latihan, bukan dengan membeli apa pun.';
  @override
  String get introBaraNote =>
      'Si Bara bangun saat amarahmu sering mengambil alih. Kalau amarahmu sudah terkelola baik, Si Bara tetap tidur. Kamu bisa menjinakkannya lewat latihan, bukan dengan membeli apa pun.';
  @override
  String introLinkedNote(String monsterName) => 'Tes ini tidak membangunkan monster baru. Hasilnya bisa menautkanmu ke $monsterName, monster pikiran yang bisa kamu jinakkan lewat latihan.';
  @override
  String get introBadgeNote => 'Hasilnya berupa lencana refleksi, bukan peringkat.';
  @override
  String get introHealthNote => 'Tes skrining ini tidak membangunkan monster. Hasilnya hanya disimpan di perangkatmu.';
  @override
  String get introTip => 'Jawab sesuai yang paling sering kamu alami, bukan yang menurutmu seharusnya.';
  @override
  String sourceLine(String reference) => '${_sumber(reference)}.';
  @override
  String healthSourceLine(String reference) => '${_sumber(reference)}. Alat skrining, bukan diagnosis.';
  static String _sumber(String ref) {
    final r = ref.trim();
    if (r.startsWith('Diadaptasi') || r.startsWith('Berdasarkan')) return r;
    return 'Berdasarkan $r';
  }

  @override
  String startButton(KenaliSection s) => s == KenaliSection.kuisBesar ? 'Mulai kuis' : 'Mulai tes';

  @override
  String progress(int current, int total) => '$current dari $total';
  @override
  String get exitTitle => 'Keluar dari tes?';
  @override
  String get exitBody => 'Jawabanmu sejauh ini tidak disimpan. Kamu bisa mulai lagi kapan saja.';
  @override
  String get previous => 'Sebelumnya';
  @override
  String get finish => 'Lihat hasil';

  @override
  String get resultHeading => 'Hasilmu';
  @override
  String breakdownTitle(String testId) => switch (testId) {
        'procrastination_profile' => 'Alasan kamu menunda',
        'phone_relationship_test' => 'Cara kamu memakai HP',
        'evening_sleep_test' => 'Alasan kamu begadang',
        'people_pleaser_test' => 'Cara kamu menyenangkan orang',
        'decision_making_test' => 'Cara kamu memutuskan',
        'stress_coping_test' => 'Cara kamu menghadapi stres',
        'inner_critic_test' => 'Suara kritikus batinmu',
        _ => 'Polamu',
      };
  @override
  String breakdownNote(int perTrait, int traitCount) {
    final semua = switch (traitCount) { 2 => 'keduanya', 3 => 'ketiganya', 4 => 'keempatnya', _ => 'semuanya' };
    return 'Dihitung dari $perTrait jawaban per alasan. Semua orang punya $semua, yang berbeda hanya seberapa kuat.';
  }

  @override
  String awokeTitle(String monsterName) => '$monsterName terbangun';
  @override
  String awokeBody(String monsterId) {
    final noun = switch (monsterId) {
      'nanti' => 'menunda',
      'gulir' => 'menggulir tanpa henti',
      'begadang' => 'begadang',
      'bunglon' => 'menyenangkan semua orang',
      'bimbang' => 'ragu memutuskan',
      'bara' => 'meledak saat marah',
      _ => 'itu',
    };
    return 'Kebiasaan $noun itu sekarang punya wujud. Dia bukan dirimu, hanya pola yang bisa dijinakkan.';
  }

  @override
  String newPractices(int n) => '$n latihan baru di peta';
  @override
  String stillAsleepTitle(String monsterName) => '$monsterName tetap tidur';
  @override
  String get stillAsleepBody => 'Pola ini sedang terkelola dengan baik. Kalau suatu saat terasa berubah, kamu bisa ulangi kuisnya.';
  @override
  String traitTip(String testId, String trait) => switch ('$testId/$trait') {
        'procrastination_profile/Perfectionist' => 'Takut hasilnya kurang sempurna? Mulai versi jeleknya dulu, 2 menit saja.',
        'procrastination_profile/Overwhelmed' => 'Tugasnya terasa terlalu besar? Pecah jadi 3 langkah, lalu kerjakan yang paling kecil.',
        'procrastination_profile/BusyBee' => 'Sibuk tapi yang penting belum tersentuh? Kerjakan satu hal penting dulu sebelum yang kecil-kecil.',
        'procrastination_profile/ThrillSeeker' => 'Baru jalan kalau sudah mepet? Bikin tenggat kecilmu sendiri, sehari lebih awal.',
        'phone_relationship_test/Scroller' => 'Sebelum buka HP, tarik 3 napas dan tanya: "Sebenarnya aku butuh apa sekarang?"',
        'phone_relationship_test/Anxious' => 'Takut ketinggalan? Matikan satu notifikasi yang paling sering bikin kamu gelisah.',
        'phone_relationship_test/Intentional' => 'Kamu yang pegang kendali atas HP-mu. Pertahankan kebiasaan baik ini.',
        'evening_sleep_test/Revenge' => 'Malam terasa satu-satunya waktu milikmu? Sisihkan 15 menit untuk dirimu di sore hari.',
        'evening_sleep_test/Anxious' => 'Pikiran ramai sebelum tidur? Tulis yang mengganjal di kertas, lalu biarkan dia menunggu sampai besok.',
        'evening_sleep_test/Dopamine' => 'Satu video lagi terus? Taruh HP di luar jangkauan 30 menit sebelum tidur.',
        'people_pleaser_test/Chameleon' => 'Coba tunda "iya": bilang "Aku cek dulu, ya", lalu tanya dirimu apa yang sebenarnya kamu mau.',
        'people_pleaser_test/Peacekeeper' => 'Beda pendapat bukan berarti bertengkar. Mulai dari satu kalimat jujur yang kecil.',
        'people_pleaser_test/Rescuer' => 'Membantu itu baik, asal kamu juga kebagian. Tanyakan dulu, "Kamu mau dibantu atau didengar?"',
        'decision_making_test/Overthinker' => 'Beri batas waktu untuk memilih. Pilihan yang cukup baik itu sudah cukup.',
        'decision_making_test/Consensus' => 'Sebelum tanya orang lain, tulis dulu pilihanmu sendiri. Baru bandingkan.',
        'decision_making_test/Impulsive' => 'Sebelum memutuskan hal besar, beri jeda satu malam.',
        'stress_coping_test/ProblemFocused' => 'Kamu sigap bertindak. Jangan lupa beri ruang juga untuk perasaanmu.',
        'stress_coping_test/EmotionFocused' => 'Kamu peka pada rasa. Setelah tenang, coba pilih satu langkah kecil yang bisa dilakukan.',
        'stress_coping_test/Avoidant' => 'Menghindar memberi lega sebentar. Coba hadapi bagian terkecil dari masalahnya dulu.',
        'inner_critic_test/Taskmaster' => 'Suara yang menuntut sempurna bisa dijawab: "Cukup baik juga sudah cukup."',
        'inner_critic_test/GuiltTripper' => 'Kesalahan lama tidak perlu dihukum terus. Bicaralah pada dirimu seperti ke sahabat.',
        'inner_critic_test/MindReader' => 'Kamu belum tentu tahu isi kepala orang. Cari bukti, bukan tebakan.',
        _ => 'Kenali polanya dulu. Perubahan kecil yang konsisten lebih kuat dari tekad besar sesaat.',
      };
  @override
  String get save => 'Simpan';
  @override
  String get startTaming => 'Mulai jinakkan';
  @override
  String get done => 'Selesai';
  @override
  String get disclaimer => 'Ini alat refleksi diri, bukan diagnosis. Hasilnya bisa berubah seiring waktu dan situasi.';
  @override
  String scoreLine(int score, int max) => 'Skor $score dari $max';
  @override
  String linkedTitle(String monsterName) => 'Terkait dengan $monsterName';
  @override
  String linkedBody(String monsterName) => 'Pola ini mirip $monsterName, monster pikiran yang bisa kamu jinakkan lewat latihan.';
  @override
  String get seeMonster => 'Lihat monster';
  @override
  String badgeTitle(String category) => 'Lencana: $category';
  @override
  String get badgeBody => 'Lencana ini penanda refleksi untukmu sendiri, bukan peringkat.';

  @override
  String testHeader(String title) => 'Tes $title';
  @override
  String resultDateKicker(String date) => 'HASILMU · ${date.toUpperCase()}';
  @override
  String healthScoreLine(String testId, int score, int max) {
    final kurun = switch (testId) {
      'anxiety_test' || 'well_being_test' => '2 minggu terakhir',
      'depression_test' => '1 minggu terakhir',
      _ => 'saat ini',
    };
    return 'Skor $score dari $max. Ini gambaran $kurun, bukan label untuk dirimu.';
  }

  @override
  String get stepsTitle => 'Langkah kecil yang bisa membantu';
  @override
  String stepTitle(KenaliStep s) => switch (s) {
        KenaliStep.napas => 'Napas 4-7-8',
        KenaliStep.cekPikiran => 'Cek pikiran cemas',
        KenaliStep.checkin => 'Check-in harian',
        KenaliStep.jurnalRasa => 'Tulis yang kamu rasakan',
        KenaliStep.tidurTenang => 'Cerita pengantar tidur',
        KenaliStep.meditasi => 'Meditasi singkat',
      };
  @override
  String stepSub(KenaliStep s) => switch (s) {
        KenaliStep.napas => 'Meditasi · 3 mnt',
        KenaliStep.cekPikiran => 'Jurnal CBT · 5 mnt',
        KenaliStep.checkin => 'Lihat polanya minggu ini',
        KenaliStep.jurnalRasa => 'Jurnal · 5 mnt',
        KenaliStep.tidurTenang => 'Tidur · 10 mnt',
        KenaliStep.meditasi => 'Meditasi · 5 mnt',
      };
  @override
  String get proTitle => 'Kapan bicara dengan profesional';
  @override
  String proBody(String testId) {
    final gejala = switch (testId) {
      'anxiety_test' => 'rasa cemas',
      'depression_test' => 'rasa sedih atau hampa',
      'burnout_test' => 'rasa lelah dan hilang semangat',
      'well_being_test' => 'rasa tidak bahagia',
      'adhd_test' => 'sulit fokus dan mengatur diri',
      'ocd_test' => 'pikiran atau dorongan berulang',
      'bpd_test' => 'emosi yang naik-turun',
      'neurodivergent_test' => 'tantangan sehari-hari ini',
      'childhood_trauma_test' => 'luka dari masa kecil',
      'narcissistic_partner_test' => 'perlakuan pasanganmu',
      _ => 'hal ini',
    };
    return 'Kalau $gejala mengganggu tidur, kerja, atau hubunganmu lebih dari dua minggu, psikolog atau psikiater bisa membantu. Itu langkah yang berani, bukan tanda lemah.';
  }

  @override
  String get proCta => 'Cara mencari bantuan';
  @override
  String get crisisTitle => 'Butuh bantuan sekarang';
  @override
  String get crisisSub => 'Layanan krisis, selalu bisa diakses';
  @override
  String get healthPrivacy => 'Hasil ini hanya disimpan di perangkatmu. Tes kesehatan tidak memberi monster, koin, atau peringkat.';
  @override
  String retakeOn(String date) => 'Ulangi $date';

  @override
  String wujudName(String monsterId, String trait) => switch ('$monsterId/$trait') {
        'nanti/Perfectionist' => 'Si Takut Salah',
        'nanti/Overwhelmed' => 'Si Kewalahan',
        'nanti/BusyBee' => 'Si Sibuk Palsu',
        'nanti/ThrillSeeker' => 'Si Pengejar Adrenalin',
        'gulir/Scroller' => 'Si Penggulir Tanpa Sadar',
        'gulir/Anxious' => 'Si Cemas Ketinggalan',
        'gulir/Intentional' => 'Si Tuan Atas Teknologinya',
        'begadang/Revenge' => 'Si Balas Dendam Malam',
        'begadang/Anxious' => 'Si Cemas Sebelum Tidur',
        'begadang/Dopamine' => 'Si Pemburu Dopamin',
        'bunglon/Chameleon' => 'Si Bunglon',
        'bunglon/Rescuer' => 'Sang Penyelamat',
        'bunglon/Peacekeeper' => 'Si Penjaga Damai',
        'bimbang/Overthinker' => 'Si Overthinker',
        'bimbang/Consensus' => 'Si Pencari Restu',
        'bimbang/Impulsive' => 'Si Tergesa-gesa',
        _ => trait,
      };
  @override
  String wujudLine(String monsterId, String trait) => switch ('$monsterId/$trait') {
        'nanti/Perfectionist' => 'Menunda karena takut hasilnya tidak sempurna',
        'nanti/Overwhelmed' => 'Tugas terasa terlalu besar untuk dimulai',
        'nanti/BusyBee' => 'Sibuk hal kecil supaya tetap merasa produktif',
        'nanti/ThrillSeeker' => 'Baru bergerak saat deadline sudah mepet',
        'gulir/Scroller' => 'Jempol terus menggulir tanpa benar-benar memilih',
        'gulir/Anxious' => 'Terus mengecek karena takut ketinggalan',
        'begadang/Revenge' => 'Merebut waktu pribadi di malam hari',
        'begadang/Anxious' => 'Pikiran ramai begitu kepala menyentuh bantal',
        'begadang/Dopamine' => 'Satu video lagi, satu episode lagi',
        'bunglon/Chameleon' => 'Berubah warna mengikuti maunya orang lain',
        'bunglon/Rescuer' => 'Selalu menolong sampai lupa diri sendiri',
        'bunglon/Peacekeeper' => 'Mengalah demi menghindari konflik',
        'bimbang/Overthinker' => 'Menimbang terus sampai kesempatannya lewat',
        'bimbang/Consensus' => 'Menunggu restu orang lain sebelum memilih',
        'bimbang/Impulsive' => 'Memutuskan terburu-buru lalu menyesal',
        _ => '',
      };
  @override
  String habitPill(String monsterId) => switch (monsterId) {
        'nanti' => 'Prokrastinasi',
        'gulir' => 'Scroll kompulsif',
        'begadang' => 'Revenge bedtime',
        'bunglon' => 'People pleasing',
        'bimbang' => 'Ragu memutuskan',
        'bara' => 'Amarah meledak',
        _ => '',
      };
  @override
  String habitRealWorld(String monsterId) => switch (monsterId) {
        'nanti' => 'Menunda yang penting sampai panik di menit terakhir, lalu menyalahkan diri sendiri.',
        'gulir' => 'Buka HP "sebentar", sadar-sadar sudah satu jam, dan rasanya malah makin capek.',
        'begadang' => 'Tahu harus tidur, tapi malam terasa satu-satunya waktu milikmu, jadi kamu terus terjaga.',
        'bunglon' => 'Berubah warna mengikuti maunya orang lain, sampai lupa warnamu sendiri.',
        'bimbang' => 'Menimbang terus sampai kesempatannya lewat, atau menyerahkan keputusan ke orang lain.',
        'bara' => 'Marah duluan, menyesal belakangan. Kata-kata keluar sebelum sempat dipikir.',
        _ => '',
      };
  @override
  String get wokeFromEyebrow => 'BANGUN DARI';
  @override
  String quizName(String monsterId) => switch (monsterId) {
        'nanti' => 'Kuis Profil Menundamu',
        'gulir' => 'Kuis Kamu & HP-mu',
        'begadang' => 'Kuis Malam & Tidurmu',
        'bunglon' => 'Kuis Pandangan Orang',
        'bimbang' => 'Kuis Kamu & Keputusan',
        'bara' => 'Kuis Amarahmu',
        _ => '',
      };
  @override
  String habitWujudList(String monsterId, List<String> names) => monsterId == 'bara'
      ? 'Bangun saat amarahmu sering mengambil alih. Kalau amarahmu sudah terkelola baik, Si Bara tetap tidur.'
      : 'Wujud yang mungkin: ${names.join(' · ')}';
  @override
  List<String> habitQuotes(String monsterId) => switch (monsterId) {
        'nanti' => const ['"Nanti aja, masih ada waktu."', '"Aku kerja lebih baik kalau udah mepet."', '"Beresin yang kecil-kecil dulu deh."'],
        'gulir' => const ['"Cek bentar aja."', '"Satu video lagi, terus tidur."', '"Nanti aku ketinggalan."'],
        'begadang' => const ['"Ini satu-satunya waktuku sendiri."', '"Sejam lagi deh."', '"Besok kan bisa ngopi."'],
        'bunglon' => const ['"Iya, nggak apa-apa kok."', '"Nanti dia kecewa sama aku."', '"Aku aja yang ngalah."'],
        'bimbang' => const ['"Gimana kalau aku salah pilih?"', '"Aku tanya pendapat semua orang dulu."', '"Nanti aja mutusinnya."'],
        'bara' => const ['"Dia yang mulai duluan!"', '"Aku cuma jujur."', '"Biar dia tahu rasa."'],
        _ => const [],
      };
  @override
  String habitFact(String monsterId) => switch (monsterId) {
        'nanti' =>
          'Menunda bukan soal malas. Itu cara otak menghindari rasa tidak nyaman: takut gagal, bosan, atau kewalahan. Memecah tugas jadi langkah kecil terbukti menurunkan penundaan.',
        'gulir' =>
          'Feed tanpa ujung dan notifikasi dirancang untuk terus memancing perhatian. Jeda singkat sebelum membuka HP membantu kamu memilih, bukan sekadar bereaksi.',
        'begadang' =>
          'Kurang tidur membuat emosi lebih reaktif dan fokus menurun keesokan harinya. Jam bangun yang konsisten adalah salah satu teknik CBT-I yang paling efektif.',
        'bunglon' =>
          'Selalu berusaha menyenangkan orang lain berkaitan dengan kelelahan emosional. Bersikap asertif bukan berarti egois. Itu cara jujur untuk menjaga hubungan.',
        'bimbang' =>
          'Mengejar pilihan yang "sempurna" berkaitan dengan rasa menyesal dan cemas. Orang yang memilih yang "cukup baik" cenderung lebih puas dengan hasilnya.',
        'bara' =>
          'Gelombang marah di tubuh biasanya mereda dalam hitungan menit kalau tidak terus "disiram" pikiran. Memberi jeda melindungi hubunganmu dan dirimu.',
        _ => '',
      };
  @override
  String habitTechnique(String monsterId) => switch (monsterId) {
        'nanti' => 'Aturan 2 menit: kerjakan 2 menit pertama saja. Seringnya, memulai adalah bagian tersulit.',
        'gulir' => 'Sebelum buka HP, tarik 3 napas dan tanya: "Sebenarnya aku butuh apa sekarang?"',
        'begadang' => 'Ritual turun mesin 30 menit: lampu redup, HP di luar jangkauan, tulis hal yang masih mengganjal.',
        'bunglon' => 'Tunda "iya": bilang "Aku cek dulu, ya", lalu tanya ke dirimu apa yang sebenarnya kamu mau.',
        'bimbang' => 'Tulis 2 kolom: apa yang penting buatmu dan apa yang kamu takutkan. Pilih berdasarkan kolom pertama, dengan batas waktu.',
        'bara' => 'Jeda 90 detik: menjauh sebentar, napas panjang, lalu bicara dengan kalimat "aku merasa…".',
        _ => '',
      };
  @override
  String habitSpotlight(String monsterId) => switch (monsterId) {
        'nanti' => 'Suara "nanti aja" yang bikin tugas penting menumpuk.',
        'gulir' => 'Jempol yang terus menggulir meski kamu sudah capek.',
        'begadang' => 'Mata yang tetap terjaga padahal badan sudah minta tidur.',
        'bunglon' => 'Warna yang terus berubah demi menyenangkan semua orang.',
        'bimbang' => 'Timbangan yang tak kunjung berhenti bergoyang.',
        'bara' => 'Api kecil yang cepat sekali menyala.',
        _ => '',
      };
  @override
  String habitOwl(String monsterId) => switch (monsterId) {
        'nanti' => 'Cukup mulai 2 menit dulu. Si Nanti paling takut sama langkah pertama.',
        'gulir' => 'Kita nggak musuhan sama HP. Cuma belajar siapa yang pegang kendali.',
        'begadang' => 'Waktu untuk dirimu itu penting. Tidur juga termasuk waktu untuk dirimu.',
        'bunglon' => 'Warnamu sendiri juga layak ditunjukkan. Pelan-pelan, mulai dari hal kecil.',
        'bimbang' => 'Nggak ada pilihan yang sempurna. Pilihan yang cukup baik itu sudah cukup.',
        'bara' => 'Marah itu wajar. Yang kita latih jedanya, bukan menekan perasaannya.',
        _ => '',
      };
  @override
  String practiceTitle(String monsterId, int index) => switch ('$monsterId/$index') {
        'nanti/0' => 'Mulai 2 menit saja',
        'nanti/1' => 'Pecah jadi 3 langkah',
        'nanti/2' => 'Tentukan jam mulai',
        'gulir/0' => 'Jeda 3 napas',
        'gulir/1' => 'Zona bebas HP',
        'gulir/2' => 'Ganti dengan hal nyata',
        'begadang/0' => 'Tulis yang mengganjal',
        'begadang/1' => 'Ritual turun mesin',
        'begadang/2' => 'Jam bangun yang sama',
        'bunglon/0' => 'Kenali maumu sendiri',
        'bunglon/1' => 'Tunda bilang "iya"',
        'bunglon/2' => 'Bilang "tidak" yang kecil',
        'bimbang/0' => 'Pilih yang cukup baik',
        'bimbang/1' => 'Batas waktu memilih',
        'bimbang/2' => 'Nilai, bukan takut',
        'bara/0' => 'Jeda 90 detik',
        'bara/1' => 'Peta pemicu amarah',
        'bara/2' => 'Kalimat "aku merasa"',
        _ => '',
      };
  @override
  String practiceHowTo(String monsterId, int index) => switch ('$monsterId/$index') {
        'nanti/0' => 'Pilih satu tugas yang kamu tunda. Nyalakan sesi Fokus dan kerjakan 2 menit pertamanya saja. Kalau mau lanjut, silakan. Kalau berhenti, itu juga sudah menang.',
        'nanti/1' => 'Tulis tugas besarmu di jurnal, lalu pecah jadi 3 langkah yang masing-masing bisa selesai kurang dari 15 menit.',
        'nanti/2' => 'Tentukan jam pasti untuk mulai besok, misalnya "jam 9 aku buka dokumennya". Saat check-in, catat apakah kamu menepatinya.',
        'gulir/0' => 'Setiap kali tanganmu meraih HP, berhenti sebentar. Tarik 3 napas pelan dan tanya, "Sebenarnya aku butuh apa sekarang?"',
        'gulir/1' => 'Pilih satu zona bebas HP, misalnya meja makan atau kasur. Pakai Aplikasi Beku untuk mengunci aplikasi yang paling sering kamu buka.',
        'gulir/2' => 'Saat ingin menggulir, ganti dengan satu hal nyata selama 10 menit: jalan sebentar, minum air, atau ngobrol dengan orang di dekatmu.',
        'begadang/0' => 'Sebelum tidur, tulis semua yang masih mengganjal di jurnal. Kepala jadi lebih ringan karena tidak harus mengingatnya.',
        'begadang/1' => '30 menit sebelum tidur: redupkan lampu, taruh HP di luar jangkauan, lalu dengarkan cerita atau suara tidur yang menenangkan.',
        'begadang/2' => 'Pilih satu jam bangun dan pertahankan beberapa hari berturut-turut, termasuk akhir pekan. Jaga streak-mu.',
        'bunglon/0' => 'Tulis di jurnal: hari ini, apa yang sebenarnya kamu mau? Bukan yang orang lain mau darimu.',
        'bunglon/1' => 'Saat diminta sesuatu, jawab "Aku cek dulu, ya." Pakai jeda itu untuk bertanya ke dirimu sendiri. Afirmasi bisa membantumu tetap berani.',
        'bunglon/2' => 'Pilih satu permintaan kecil yang sebenarnya ingin kamu tolak, lalu bilang "tidak" dengan sopan. Menjaga batas juga melindungi dirimu.',
        'bimbang/0' => 'Untuk satu keputusan kecil hari ini, pilih opsi pertama yang "cukup baik", lalu ucapkan afirmasi bahwa itu sudah cukup.',
        'bimbang/1' => 'Pasang sesi Fokus singkat sebagai batas waktu. Saat waktunya habis, putuskan dengan informasi yang sudah ada.',
        'bimbang/2' => 'Di jurnal, tulis 2 kolom: apa yang penting buatmu dan apa yang kamu takutkan. Pilih berdasarkan kolom pertama.',
        'bara/0' => 'Saat amarah naik, menjauh sebentar. Ikuti satu meditasi napas singkat sampai gelombangnya mereda.',
        'bara/1' => 'Lihat laporan mood dan faktormu. Kapan biasanya amarahmu muncul? Kenali pemicunya supaya kamu lebih siap.',
        'bara/2' => 'Latih kalimat "Aku merasa … saat … karena …". Afirmasi bisa membantumu bicara dengan tenang.',
        _ => '',
      };

  @override
  String tabPikiran(int n) => 'Pikiran · $n';
  @override
  String tabKebiasaan(int n) => 'Kebiasaan · $n';
  @override
  String pikiranSub(int tamed, int totalMonsters) => '$tamed dari 7 sudah jinak · $totalMonsters monster';
  @override
  String habitSub(int awake, int total, int tamed) => '$awake dari $total sudah bangun · $tamed jinak';
  @override
  String spotlightKicker(int percent) => 'BARU BANGUN · $percent%';
  @override
  String wokeFrom(String monsterId) => 'Bangun dari ${quizName(monsterId)}.';
  @override
  String spotlightProgress(int percent, int done, int total) => '$percent% menuju jinak · $done dari $total latihan';
  @override
  String get stageMapButton => 'Peta latihan';
  @override
  String get otherHabits => 'Monster kebiasaan lainnya';
  @override
  String get asleep => 'Tertidur';
  @override
  String wakeVia(String monsterId) => 'Bangun lewat ${quizName(monsterId)}';
  @override
  String startArrow(String monsterId) => monsterId == 'bara' ? 'Mulai tes →' : 'Mulai kuis →';
  @override
  String get ctaBody => 'Monster kebiasaan bangun dari kuis — bukan dari toko.';
  @override
  String get ctaOpen => 'Buka →';
  @override
  String get noneAwakeTitle => 'Belum ada yang bangun';
  @override
  String get noneAwakeBody => 'Ikuti satu Kuis Besar untuk membangunkan monster kebiasaan pertamamu.';
  @override
  String get asleepDetailBody => 'Monster ini masih tidur. Dia bangun kalau jawaban kuismu menunjukkan polanya.';
  @override
  String get takeQuiz => 'Ikuti kuisnya';

  @override
  String stageTitle(String monsterName) => 'Peta latihan $monsterName';
  @override
  String lockedAfter(int level) => 'Terbuka setelah level $level';
  @override
  String get stepDone => 'Sudah selesai';
  @override
  String faceMonster(String monsterName) => 'Hadapi $monsterName';
  @override
  String get practiceDoneButton => 'Sudah kulakukan';
  @override
  String get practiceNote => 'Latihan kecil ini membuka langkah berikutnya di peta. Tidak perlu sempurna, yang penting dicoba.';
  @override
  String openFeature(KenaliFeature f) => switch (f) {
        KenaliFeature.fokus => 'Buka Fokus',
        KenaliFeature.jurnal => 'Buka Jurnal',
        KenaliFeature.checkin => 'Check-in sekarang',
        KenaliFeature.meditasi => 'Buka Meditasi',
        KenaliFeature.aplikasiBeku => 'Buka Aplikasi Beku',
        KenaliFeature.tidur => 'Buka Tidur',
        KenaliFeature.afirmasi => 'Buka Afirmasi',
        KenaliFeature.laporan => 'Buka Laporan',
      };

  @override
  String get newPill => 'BARU';
  @override
  String profilCardSub(int total, int done) => '$total tes & kuis · $done selesai';
  @override
  String get homeKicker => 'KENALI DIRIMU';
  @override
  String get homeTitle => 'Sering bilang "iya" padahal ingin bilang "tidak"?';
  @override
  String homeMeta(String quiz, int minutes) => '$quiz · $minutes mnt';

  // Riwayat (tombol jam di header hub)
  @override
  String get historyTitle => 'Riwayat';
  @override
  String get historyButton => 'Riwayat hasil';
  @override
  String get historyIntro => 'Hasil tes dan kuismu dari waktu ke waktu. Ketuk untuk melihatnya lagi.';
  @override
  String get historyEmptyTitle => 'Belum ada riwayat';
  @override
  String get historyEmptyBody => 'Selesaikan satu tes atau kuis, hasilnya akan tersimpan di sini.';
  @override
  String historyPrivacyNote(int perTest) =>
      'Riwayat hanya tersimpan di perangkatmu dan terenkripsi, paling banyak $perTest hasil terakhir per tes.';
}

class KenaliStringsEn extends KenaliStrings {
  const KenaliStringsEn();

  @override
  String get title => 'Know Yourself';
  @override
  String get hubHeading => 'Get to know your patterns';
  @override
  String get hubIntro => 'Short tests and quizzes to understand yourself. Some results can wake a monster you can tame.';
  @override
  String hubProgress(int done, int total) => '$done of $total done';
  @override
  String get tabAll => 'All';
  @override
  String get tabKuis => 'Big Quizzes';
  @override
  String get tabTes => 'Tests';
  @override
  String sectionTitle(KenaliSection s) => switch (s) {
        KenaliSection.kuisBesar => 'Big Quizzes',
        KenaliSection.kepribadian => 'Personality',
        KenaliSection.diriRelasi => 'Self & Relationships',
        KenaliSection.kesehatan => 'Mental Health',
      };
  @override
  String sectionSub(KenaliSection s) => switch (s) {
        KenaliSection.kuisBesar => 'Your habit profile. Each quiz wakes one Habit Monster, and your answers shape its form.',
        KenaliSection.kepribadian => 'Your result unlocks a companion character made for you.',
        KenaliSection.diriRelasi => 'How you see yourself and treat others.',
        KenaliSection.kesehatan => 'Calm, private screening tests. They never wake a monster.',
      };
  @override
  String get healthPrivacyNote => 'Results stay on your device and always come with next steps, including when to talk to a professional.';
  @override
  String get hubFooter => 'Every test here is a self-reflection tool, not a diagnosis. If you are in danger, open ';
  @override
  String get hubFooterCrisis => 'Crisis help anytime.';
  @override
  String topicLabel(KenaliTopic t) => switch (t) {
        KenaliTopic.kebiasaan => 'HABITS',
        KenaliTopic.tidur => 'SLEEP',
        KenaliTopic.emosi => 'EMOTIONS',
        KenaliTopic.relasi => 'RELATIONSHIPS',
        KenaliTopic.pikiran => 'THOUGHTS',
        KenaliTopic.kepribadian => 'PERSONALITY',
        KenaliTopic.diri => 'SELF',
        KenaliTopic.kesejahteraan => 'WELL-BEING',
        KenaliTopic.perhatian => 'ATTENTION',
        KenaliTopic.masaLalu => 'THE PAST',
      };
  @override
  String entryTitle(String id) => switch (id) {
        'procrastination_profile' => 'Your Procrastination Profile',
        'phone_relationship_test' => 'You & Your Phone',
        'evening_sleep_test' => 'Your Evenings & Sleep',
        'anger_test' => 'Your Anger',
        'people_pleaser_test' => "Other People's Eyes",
        'decision_making_test' => 'You & Decisions',
        'self_esteem_test' => 'Self-Esteem',
        'stress_coping_test' => 'Stress Coping Style',
        'inner_critic_test' => 'Inner Critic',
        'toxic_trait_test' => 'Toxic Traits',
        'difficult_person_test' => 'A Difficult Person?',
        'eq_test' => 'Emotional Intelligence',
        'likeable_person_test' => 'A Likeable Person',
        'depression_test' => 'Depression',
        'anxiety_test' => 'Anxiety',
        'burnout_test' => 'Burnout',
        'well_being_test' => 'Well-being',
        'adhd_test' => 'ADHD',
        'ocd_test' => 'OCD',
        'bpd_test' => 'BPD',
        'neurodivergent_test' => 'Neurodivergence',
        'childhood_trauma_test' => 'Childhood Trauma',
        'narcissistic_partner_test' => 'A Narcissistic Partner?',
        _ => id,
      };
  @override
  String get kepribadianJung => 'Personality Type';
  @override
  String get kepribadianAttachment => 'Attachment Style';
  @override
  String get kepribadianTemperament => 'Four Temperaments';
  @override
  String get openCharacter => 'Unlock character';
  @override
  String awoke(String monsterName) => 'Awake: $monsterName';
  @override
  String asleepChip(String monsterName) => '$monsterName stays asleep';
  @override
  String meta(int questions, int minutes) => '$questions questions · $minutes min';
  @override
  String get badgeChip => 'Badge';
  @override
  String get retake => 'Retake';

  @override
  String introKicker(KenaliSection s) => switch (s) {
        KenaliSection.kuisBesar => 'Big Quiz',
        KenaliSection.kesehatan => 'Mental Health',
        _ => 'Test',
      };
  @override
  String entryBlurb(String id, String fallback) => switch (id) {
        'procrastination_profile' => "Find out the reasons behind your procrastination. It's not about laziness, it's about managing feelings.",
        _ => fallback,
      };
  @override
  String chipQuestions(int n) => '$n questions';
  @override
  String chipMinutes(int m) => '± $m min';
  @override
  String get chipPrivate => 'Private';
  @override
  String wujudHeading(String monsterName) => 'POSSIBLE FORMS OF ${monsterName.toUpperCase()}';
  @override
  String introWakeNote(String monsterName) =>
      "It's always $monsterName who wakes up; its form follows your answers. You tame it through practice, never by buying anything.";
  @override
  String get introBaraNote =>
      'Si Bara wakes when anger often takes over. If your anger is already well managed, Si Bara stays asleep. You tame it through practice, never by buying anything.';
  @override
  String introLinkedNote(String monsterName) =>
      "This test doesn't wake a new monster. Your result can link you to $monsterName, a thought monster you can tame through practice.";
  @override
  String get introBadgeNote => 'Your result is a reflection badge, not a ranking.';
  @override
  String get introHealthNote => "This screening test never wakes a monster. Results stay on your device only.";
  @override
  String get introTip => 'Answer with what you experience most often, not what you think you should.';
  @override
  String sourceLine(String reference) => 'Source: ${reference.trim()}.';
  @override
  String healthSourceLine(String reference) => 'Source: ${reference.trim()}. A screening tool, not a diagnosis.';
  @override
  String startButton(KenaliSection s) => s == KenaliSection.kuisBesar ? 'Start quiz' : 'Start test';

  @override
  String progress(int current, int total) => '$current of $total';
  @override
  String get exitTitle => 'Leave the test?';
  @override
  String get exitBody => "Your answers so far won't be saved. You can start again anytime.";
  @override
  String get previous => 'Previous';
  @override
  String get finish => 'See result';

  @override
  String get resultHeading => 'Your result';
  @override
  String breakdownTitle(String testId) => switch (testId) {
        'procrastination_profile' => 'Why you procrastinate',
        'phone_relationship_test' => 'How you use your phone',
        'evening_sleep_test' => 'Why you stay up late',
        'people_pleaser_test' => 'How you please others',
        'decision_making_test' => 'How you decide',
        'stress_coping_test' => 'How you handle stress',
        'inner_critic_test' => "Your inner critic's voice",
        _ => 'Your pattern',
      };
  @override
  String breakdownNote(int perTrait, int traitCount) =>
      'Calculated from $perTrait answers per reason. Everyone has all $traitCount; what differs is only how strong they are.';
  @override
  String awokeTitle(String monsterName) => '$monsterName woke up';
  @override
  String awokeBody(String monsterId) => "That habit now has a form. It isn't you, just a pattern that can be tamed.";
  @override
  String newPractices(int n) => '$n new practices on the map';
  @override
  String stillAsleepTitle(String monsterName) => '$monsterName stays asleep';
  @override
  String get stillAsleepBody => 'This pattern is well managed right now. If it ever feels different, you can retake the quiz.';
  @override
  String traitTip(String testId, String trait) =>
      'Get to know the pattern first. Small, consistent changes beat a big burst of willpower.';
  @override
  String get save => 'Save';
  @override
  String get startTaming => 'Start taming';
  @override
  String get done => 'Done';
  @override
  String get disclaimer => 'This is a self-reflection tool, not a diagnosis. Results can change with time and circumstances.';
  @override
  String scoreLine(int score, int max) => 'Score $score of $max';
  @override
  String linkedTitle(String monsterName) => 'Linked to $monsterName';
  @override
  String linkedBody(String monsterName) => 'This pattern resembles $monsterName, a thought monster you can tame through practice.';
  @override
  String get seeMonster => 'See monster';
  @override
  String badgeTitle(String category) => 'Badge: $category';
  @override
  String get badgeBody => 'This badge is a reflection marker just for you, not a ranking.';

  @override
  String testHeader(String title) => '$title Test';
  @override
  String resultDateKicker(String date) => 'YOUR RESULT · ${date.toUpperCase()}';
  @override
  String healthScoreLine(String testId, int score, int max) => "Score $score of $max. It's a snapshot of right now, not a label for who you are.";
  @override
  String get stepsTitle => 'Small steps that can help';
  @override
  String stepTitle(KenaliStep s) => switch (s) {
        KenaliStep.napas => '4-7-8 breathing',
        KenaliStep.cekPikiran => 'Check anxious thoughts',
        KenaliStep.checkin => 'Daily check-in',
        KenaliStep.jurnalRasa => 'Write what you feel',
        KenaliStep.tidurTenang => 'Bedtime story',
        KenaliStep.meditasi => 'Short meditation',
      };
  @override
  String stepSub(KenaliStep s) => switch (s) {
        KenaliStep.napas => 'Meditation · 3 min',
        KenaliStep.cekPikiran => 'CBT journal · 5 min',
        KenaliStep.checkin => "See this week's pattern",
        KenaliStep.jurnalRasa => 'Journal · 5 min',
        KenaliStep.tidurTenang => 'Sleep · 10 min',
        KenaliStep.meditasi => 'Meditation · 5 min',
      };
  @override
  String get proTitle => 'When to talk to a professional';
  @override
  String proBody(String testId) =>
      "If this gets in the way of your sleep, work, or relationships for more than two weeks, a psychologist or psychiatrist can help. That's a brave step, not a sign of weakness.";
  @override
  String get proCta => 'How to find help';
  @override
  String get crisisTitle => 'Need help now';
  @override
  String get crisisSub => 'Crisis services, always accessible';
  @override
  String get healthPrivacy => 'This result stays on your device only. Health tests never give monsters, coins, or rankings.';
  @override
  String retakeOn(String date) => 'Retake $date';

  @override
  String habitPill(String monsterId) => switch (monsterId) {
        'nanti' => 'Procrastination',
        'gulir' => 'Compulsive scrolling',
        'begadang' => 'Revenge bedtime',
        'bunglon' => 'People pleasing',
        'bimbang' => 'Indecision',
        'bara' => 'Explosive anger',
        _ => '',
      };
  @override
  String get wokeFromEyebrow => 'WOKE FROM';
  @override
  String quizName(String monsterId) => switch (monsterId) {
        'nanti' => 'the Procrastination Profile quiz',
        'gulir' => 'the You & Your Phone quiz',
        'begadang' => 'the Evenings & Sleep quiz',
        'bunglon' => "the Other People's Eyes quiz",
        'bimbang' => 'the You & Decisions quiz',
        'bara' => 'the Your Anger quiz',
        _ => '',
      };
  @override
  String habitWujudList(String monsterId, List<String> names) => monsterId == 'bara'
      ? 'Wakes when anger often takes over. If your anger is well managed, Si Bara stays asleep.'
      : 'Possible forms: ${names.join(' · ')}';

  @override
  String tabPikiran(int n) => 'Thoughts · $n';
  @override
  String tabKebiasaan(int n) => 'Habits · $n';
  @override
  String pikiranSub(int tamed, int totalMonsters) => '$tamed of 7 tamed · $totalMonsters monsters';
  @override
  String habitSub(int awake, int total, int tamed) => '$awake of $total awake · $tamed tamed';
  @override
  String spotlightKicker(int percent) => 'JUST WOKE · $percent%';
  @override
  String wokeFrom(String monsterId) => 'Woke from ${quizName(monsterId)}.';
  @override
  String spotlightProgress(int percent, int done, int total) => '$percent% to tamed · $done of $total practices';
  @override
  String get stageMapButton => 'Practice map';
  @override
  String get otherHabits => 'Other habit monsters';
  @override
  String get asleep => 'Asleep';
  @override
  String wakeVia(String monsterId) => 'Wakes via ${quizName(monsterId)}';
  @override
  String startArrow(String monsterId) => monsterId == 'bara' ? 'Start test →' : 'Start quiz →';
  @override
  String get ctaBody => 'Habit monsters wake from quizzes — not from the shop.';
  @override
  String get ctaOpen => 'Open →';
  @override
  String get noneAwakeTitle => 'None awake yet';
  @override
  String get noneAwakeBody => 'Take one Big Quiz to wake your first habit monster.';
  @override
  String get asleepDetailBody => 'This monster is still asleep. It wakes if your quiz answers show the pattern.';
  @override
  String get takeQuiz => 'Take the quiz';

  @override
  String stageTitle(String monsterName) => "$monsterName's practice map";
  @override
  String lockedAfter(int level) => 'Unlocks after level $level';
  @override
  String get stepDone => 'Done';
  @override
  String faceMonster(String monsterName) => 'Face $monsterName';
  @override
  String get practiceDoneButton => 'I did it';
  @override
  String get practiceNote => "This small practice unlocks the next step on the map. It doesn't need to be perfect, just tried.";
  @override
  String openFeature(KenaliFeature f) => switch (f) {
        KenaliFeature.fokus => 'Open Focus',
        KenaliFeature.jurnal => 'Open Journal',
        KenaliFeature.checkin => 'Check in now',
        KenaliFeature.meditasi => 'Open Meditation',
        KenaliFeature.aplikasiBeku => 'Open App Freeze',
        KenaliFeature.tidur => 'Open Sleep',
        KenaliFeature.afirmasi => 'Open Affirmations',
        KenaliFeature.laporan => 'Open Report',
      };

  @override
  String get newPill => 'NEW';
  @override
  String profilCardSub(int total, int done) => '$total tests & quizzes · $done done';
  @override
  String get homeKicker => 'KNOW YOURSELF';
  @override
  String get homeTitle => 'Often say "yes" when you want to say "no"?';
  @override
  String homeMeta(String quiz, int minutes) => '$quiz · $minutes min';

  @override
  String wujudName(String monsterId, String trait) => switch ('$monsterId/$trait') {
        'nanti/Perfectionist' => 'The Perfectionist',
        'nanti/Overwhelmed' => 'The Overwhelmed',
        'nanti/BusyBee' => 'The Busy Bee',
        'nanti/ThrillSeeker' => 'The Thrill-Seeker',
        'gulir/Scroller' => 'The Mindless Scroller',
        'gulir/Anxious' => 'The Anxious Checker',
        'gulir/Intentional' => 'The Intentional User',
        'begadang/Revenge' => 'The Revenge Night Owl',
        'begadang/Anxious' => 'The Anxious Sleeper',
        'begadang/Dopamine' => 'The Dopamine Chaser',
        'bunglon/Chameleon' => 'The Chameleon',
        'bunglon/Rescuer' => 'The Rescuer',
        'bunglon/Peacekeeper' => 'The Peacekeeper',
        'bimbang/Overthinker' => 'The Overthinker',
        'bimbang/Consensus' => 'The Consensus Seeker',
        'bimbang/Impulsive' => 'The Impulsive Decider',
        _ => trait,
      };
  @override
  String wujudLine(String monsterId, String trait) => switch ('$monsterId/$trait') {
        'nanti/Perfectionist' => 'Delays because the result might not be perfect',
        'nanti/Overwhelmed' => 'The task feels too big to start',
        'nanti/BusyBee' => 'Busy with small things to still feel productive',
        'nanti/ThrillSeeker' => 'Only moves once the deadline is close',
        'gulir/Scroller' => 'The thumb keeps scrolling without really choosing',
        'gulir/Anxious' => 'Keeps checking for fear of missing out',
        'begadang/Revenge' => 'Reclaiming personal time late at night',
        'begadang/Anxious' => 'A busy mind as soon as your head hits the pillow',
        'begadang/Dopamine' => 'One more video, one more episode',
        'bunglon/Chameleon' => 'Changes color to match what others want',
        'bunglon/Rescuer' => 'Always helping until forgetting yourself',
        'bunglon/Peacekeeper' => 'Gives in to avoid conflict',
        'bimbang/Overthinker' => 'Weighs things until the chance is gone',
        'bimbang/Consensus' => "Waits for others' approval before choosing",
        'bimbang/Impulsive' => 'Decides in a rush, then regrets it',
        _ => '',
      };
  @override
  String habitRealWorld(String monsterId) => switch (monsterId) {
        'nanti' => 'Putting off what matters until panicking at the last minute, then blaming yourself.',
        'gulir' => 'Opening your phone "for a second", and suddenly an hour is gone and you feel even more tired.',
        'begadang' => "You know you should sleep, but the night feels like the only time that's yours, so you stay up.",
        'bunglon' => 'Changing color to match what others want, until you forget your own color.',
        'bimbang' => 'Weighing things until the chance passes, or handing the decision to someone else.',
        'bara' => 'Angry first, sorry later. Words come out before you can think.',
        _ => '',
      };
  @override
  List<String> habitQuotes(String monsterId) => switch (monsterId) {
        'nanti' => const ['"Later, there\'s still time."', '"I work better under pressure."', '"Let me clear the small stuff first."'],
        'gulir' => const ['"Just a quick check."', '"One more video, then sleep."', '"I\'ll miss out."'],
        'begadang' => const ['"This is the only time I have for myself."', '"Just one more hour."', '"I can have coffee tomorrow."'],
        'bunglon' => const ['"Yes, it\'s fine."', '"They\'ll be disappointed in me."', '"I\'ll just give in."'],
        'bimbang' => const ['"What if I choose wrong?"', '"Let me ask everyone first."', '"I\'ll decide later."'],
        'bara' => const ['"They started it!"', '"I\'m just being honest."', '"They deserve it."'],
        _ => const [],
      };
  @override
  String habitFact(String monsterId) => switch (monsterId) {
        'nanti' =>
          "Procrastination isn't laziness. It's the brain avoiding discomfort: fear of failure, boredom, or overwhelm. Breaking tasks into small steps is proven to reduce it.",
        'gulir' =>
          'Endless feeds and notifications are designed to keep pulling your attention. A short pause before opening your phone helps you choose instead of just react.',
        'begadang' =>
          'Lack of sleep makes emotions more reactive and focus weaker the next day. A consistent wake-up time is one of the most effective CBT-I techniques.',
        'bunglon' =>
          "Constantly pleasing others is linked to emotional exhaustion. Being assertive isn't selfish. It's an honest way to protect relationships.",
        'bimbang' =>
          'Chasing the "perfect" choice is linked to regret and anxiety. People who choose "good enough" tend to be more satisfied with the outcome.',
        'bara' =>
          "The wave of anger in the body usually fades within minutes if thoughts don't keep fueling it. Pausing protects your relationships and yourself.",
        _ => '',
      };
  @override
  String habitTechnique(String monsterId) => switch (monsterId) {
        'nanti' => 'The 2-minute rule: do just the first 2 minutes. Starting is often the hardest part.',
        'gulir' => 'Before opening your phone, take 3 breaths and ask: "What do I actually need right now?"',
        'begadang' => 'A 30-minute wind-down: dim lights, phone out of reach, write down what is still on your mind.',
        'bunglon' => 'Delay the "yes": say "Let me check first", then ask yourself what you actually want.',
        'bimbang' => 'Write 2 columns: what matters to you and what you fear. Choose based on the first, with a time limit.',
        'bara' => 'A 90-second pause: step away, breathe deeply, then speak with "I feel…".',
        _ => '',
      };
  @override
  String habitSpotlight(String monsterId) => switch (monsterId) {
        'nanti' => 'The "later" voice that lets important tasks pile up.',
        'gulir' => 'The thumb that keeps scrolling even when you are tired.',
        'begadang' => 'Eyes that stay open while your body begs for sleep.',
        'bunglon' => 'A color that keeps changing to please everyone.',
        'bimbang' => 'Scales that never stop wobbling.',
        'bara' => 'A small flame that catches fast.',
        _ => '',
      };
  @override
  String habitOwl(String monsterId) => switch (monsterId) {
        'nanti' => 'Just start with 2 minutes. Si Nanti fears the first step most.',
        'gulir' => "We're not at war with the phone. Just learning who's in control.",
        'begadang' => 'Time for yourself matters. Sleep counts as time for yourself too.',
        'bunglon' => 'Your own color deserves to be seen. Slowly, starting small.',
        'bimbang' => 'No choice is perfect. A good-enough choice is enough.',
        'bara' => "Anger is normal. We're practicing the pause, not suppressing the feeling.",
        _ => '',
      };
  @override
  String practiceTitle(String monsterId, int index) => switch ('$monsterId/$index') {
        'nanti/0' => 'Start with just 2 minutes',
        'nanti/1' => 'Break it into 3 steps',
        'nanti/2' => 'Set a start time',
        'gulir/0' => 'A 3-breath pause',
        'gulir/1' => 'Phone-free zone',
        'gulir/2' => 'Swap it for something real',
        'begadang/0' => "Write what's on your mind",
        'begadang/1' => 'Wind-down ritual',
        'begadang/2' => 'Same wake-up time',
        'bunglon/0' => 'Know what you want',
        'bunglon/1' => 'Delay the "yes"',
        'bunglon/2' => 'A small "no"',
        'bimbang/0' => 'Choose good enough',
        'bimbang/1' => 'A deadline to decide',
        'bimbang/2' => 'Values, not fear',
        'bara/0' => 'A 90-second pause',
        'bara/1' => 'Map your anger triggers',
        'bara/2' => 'The "I feel" sentence',
        _ => '',
      };
  @override
  String practiceHowTo(String monsterId, int index) => switch ('$monsterId/$index') {
        'nanti/0' => "Pick one task you've been putting off. Start a Focus session and do only the first 2 minutes. Keep going if you like; stopping is still a win.",
        'nanti/1' => 'Write your big task in the journal, then break it into 3 steps that each take under 15 minutes.',
        'nanti/2' => 'Set an exact time to start tomorrow, like "at 9 I open the document". At check-in, note whether you kept it.',
        'gulir/0' => 'Every time your hand reaches for the phone, pause. Take 3 slow breaths and ask, "What do I actually need right now?"',
        'gulir/1' => 'Pick one phone-free zone, like the dinner table or your bed. Use App Freeze to lock the apps you open most.',
        'gulir/2' => 'When you want to scroll, swap it for one real thing for 10 minutes: a short walk, a glass of water, or a chat with someone nearby.',
        'begadang/0' => "Before bed, write down everything still on your mind in the journal. Your head feels lighter when it doesn't have to hold it all.",
        'begadang/1' => '30 minutes before bed: dim the lights, put your phone out of reach, then listen to a calming story or sleep sound.',
        'begadang/2' => 'Choose one wake-up time and keep it several days in a row, weekends included. Keep your streak going.',
        'bunglon/0' => 'Write in your journal: today, what do you actually want? Not what others want from you.',
        'bunglon/1' => 'When asked for something, answer "Let me check first." Use that pause to ask yourself. Affirmations can help you stay brave.',
        'bunglon/2' => 'Pick one small request you actually want to decline, then say "no" kindly. Keeping boundaries protects you too.',
        'bimbang/0' => 'For one small decision today, pick the first "good enough" option, then say an affirmation that it is enough.',
        'bimbang/1' => "Set a short Focus session as a time limit. When time's up, decide with the information you already have.",
        'bimbang/2' => 'In your journal, write 2 columns: what matters to you and what you fear. Choose based on the first column.',
        'bara/0' => 'When anger rises, step away for a moment. Follow one short breathing meditation until the wave passes.',
        'bara/1' => 'Look at your mood and factor report. When does your anger usually show up? Knowing the triggers helps you prepare.',
        'bara/2' => 'Practice the sentence "I feel … when … because …". Affirmations can help you speak calmly.',
        _ => '',
      };

  // Riwayat (tombol jam di header hub)
  @override
  String get historyTitle => 'History';
  @override
  String get historyButton => 'Result history';
  @override
  String get historyIntro => 'Your test and quiz results over time. Tap one to see it again.';
  @override
  String get historyEmptyTitle => 'No history yet';
  @override
  String get historyEmptyBody => 'Finish a test or quiz and your result will be saved here.';
  @override
  String historyPrivacyNote(int perTest) =>
      'Your history is stored encrypted on this device only, up to the last $perTest results per test.';
}
