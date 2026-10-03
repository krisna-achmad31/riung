/// Teks naratif satu monster (bagian dari layar detail). Urutan [techniques]
/// HARUS sama dengan konfigurasi ikon/pengganda di `saboteur_content.dart`.
class SaboteurTexts {
  const SaboteurTexts({
    required this.apaKatanya,
    required this.faktanya,
    required this.duniaNyata,
    required this.techniques,
  });

  final String apaKatanya;
  final String faktanya;
  final String duniaNyata;
  final List<String> techniques;
}

/// Teks fitur Monster: brankas, detail (bos & anak buah), perayaan jinak.
abstract class MonsterStrings {
  const MonsterStrings();

  // ── Brankas ──
  String get loadError;
  String get vaultTitle;
  String vaultSub(int tamed);
  String get bossBadge;
  String get hakimBlurb;
  String progressToTamed(int percent);
  String get minions;
  String get tamedBadge;

  // ── Detail ──
  String get realWorld;
  String get whatItSays;
  String get theFact;
  String get antidotes;
  String get antidoteNote;
  String get wild;
  String get tamed;
  String tamedPercent(int percent);
  String get attack;
  String get cbtPractice;

  // —— Peta latihan Si Waswas (uji coba: peta per-monster) ——
  String get stageMapTitle;
  String get stageMapIntro;
  String stageLevelLabel(int level);
  String get stageOwlIntro;
  String get stageNodeJournalTitle;
  String get stageNodeJournalDone;
  String get stageNodeBreathTitle;
  String get stageNodeBreathDone;
  String get stageNodeAfirmasiTitle;
  String get stageNodeAfirmasiDone;
  String get stageNodeBossTitle;
  String stageNodeBossSub(int percent);
  String get stageNodeLabelDone;

  // ── Detail Si Hakim ──
  String get hakimIntro;
  String bossPercent(int percent);
  String get minionsHeading;
  String get minionsNote;

  // ── Perayaan ──
  String monsterNumberTamed(int number);
  String friendNow(String monsterName);
  String get celebrationBody;
  String get bonusCoins;
  String get tamedLabel;
  String get shareAchievement;
  String get shareNote;
  String get cardShareFailed;
  String shareCaption(String monsterName, int tamed);

  // ── Konten naratif & deskripsi ──
  Map<String, SaboteurTexts> get saboteurTexts;

  /// Deskripsi singkat monster dalam bahasa aktif; [fallback] (dari data
  /// konten) dipakai kalau bahasa ini tidak punya terjemahannya.
  String saboteurDescription(String id, String fallback);
}

class MonsterStringsId extends MonsterStrings {
  const MonsterStringsId();

  @override
  String get loadError => 'Gagal memuat monstermu.';
  @override
  String get vaultTitle => 'Monstermu';
  @override
  String vaultSub(int tamed) => '$tamed dari 7 sudah jinak';
  @override
  String get bossBadge => 'BOS';
  @override
  String get hakimBlurb => 'Suara yang bilang kamu "pasti gagal". Enam anak buahnya melemah kalau dia melemah.';
  @override
  String progressToTamed(int percent) => '$percent% menuju jinak';
  @override
  String get minions => 'Anak buahnya';
  @override
  String get tamedBadge => 'JINAK';

  @override
  String get realWorld => 'DI DUNIA NYATA, DIA ADALAH…';
  @override
  String get whatItSays => 'APA KATANYA';
  @override
  String get theFact => 'FAKTANYA';
  @override
  String get antidotes => 'TEKNIK PENANGKAL';
  @override
  String get antidoteNote => 'Teknik yang tepat = serangan lebih besar di mini-game.';
  @override
  String get wild => 'Liar';
  @override
  String get tamed => 'Jinak';
  @override
  String tamedPercent(int percent) => '$percent% JINAK';
  @override
  String get attack => 'Serang';
  @override
  String get cbtPractice => 'Latihan CBT';

  @override
  String get stageMapTitle => 'Peta latihan Si Waswas';
  @override
  String get stageMapIntro => 'Bukan sekali serang langsung menang — latihan kecil dulu, baru hadapi dia.';
  @override
  String stageLevelLabel(int level) => 'Level $level';
  @override
  String get stageOwlIntro => 'Hai, aku temenmu di sini. Yuk susuri petanya pelan-pelan — nggak harus semuanya sekaligus.';
  @override
  String get stageNodeJournalTitle => 'Tulis satu kekhawatiran';
  @override
  String get stageNodeJournalDone => 'Sudah ditulis hari ini';
  @override
  String get stageNodeBreathTitle => 'Latihan napas';
  @override
  String get stageNodeBreathDone => 'Sudah napas hari ini';
  @override
  String get stageNodeAfirmasiTitle => 'Bicara ke diri sendiri';
  @override
  String get stageNodeAfirmasiDone => 'Sudah bicara ke diri sendiri hari ini';
  @override
  String get stageNodeBossTitle => 'Hadapi Si Waswas';
  @override
  String stageNodeBossSub(int percent) => '$percent% menuju jinak';
  @override
  String get stageNodeLabelDone => 'Selesai';

  @override
  String get hakimIntro =>
      'Bos dari semua monster. Suara hakim di kepalamu yang memvonis sebelum kamu mencoba: "pasti gagal", "kamu nggak pantas".';
  @override
  String bossPercent(int percent) => 'BOS · $percent%';
  @override
  String get minionsHeading => 'ANAK BUAH YANG DIA PIMPIN';
  @override
  String get minionsNote =>
      'Tiap anak buah yang jinak mengurangi kekuatan Si Hakim 5%. Jinakkan semuanya buat membuka pertarungan terakhir.';

  @override
  String monsterNumberTamed(int number) => 'MONSTER KE-$number JINAK';
  @override
  String friendNow(String monsterName) => '$monsterName sekarang temanmu';
  @override
  String get celebrationBody =>
      'Dia nggak hilang. Pola pikirnya emang nggak pernah benar-benar hilang. Tapi sekarang dia ikut kamu, bukan ngejar kamu.';
  @override
  String get bonusCoins => 'bonus koin';
  @override
  String get tamedLabel => 'jinak';
  @override
  String get shareAchievement => 'Bagikan pencapaian';
  @override
  String get shareNote => 'Yang dibagikan cuma kartunya, bukan isi jurnal atau datamu 🔒';
  @override
  String get cardShareFailed => 'Gagal membagikan pencapaian, coba lagi.';
  @override
  String shareCaption(String monsterName, int tamed) => '$monsterName sekarang temanku. $tamed dari 7 monster jinak, via Riung 💜';

  @override
  Map<String, SaboteurTexts> get saboteurTexts => const {
        'hakim': SaboteurTexts(
          apaKatanya: 'Kamu pasti gagal. Kayak biasanya.',
          faktanya: 'Coba deh, "selalu" sama "nggak pernah" itu jarang benar. Satu aja keberhasilan kecil udah cukup bikin vonis itu goyah, dan kamu punya lebih dari satu.',
          duniaNyata: 'Ini suara paling galak di kepalamu. Dia bisik-bisik tiap kamu mau coba sesuatu, bilang kamu bakal gagal duluan sebelum sempat mulai. Begitu dia ngomong, cemas ikut muncul, males gerak ikut muncul, rasa nggak cukup ikut muncul. Dia yang menyalakan semuanya.',
          techniques: [
            'Tulis 3 bukti kecil hari ini yang membantah vonisnya',
            'Ucapkan ke dirimu sendiri persis seperti kamu menghibur temanmu',
            'Begitu dengar suaranya, bilang keras-keras: "itu Si Hakim, bukan fakta"',
          ],
        ),
        'waswas': SaboteurTexts(
          apaKatanya: 'Gimana kalau besok semuanya berantakan?',
          faktanya: 'Pikiran itu bukan ramalan. Coba hitung deh, dari semua yang kamu takutin minggu lalu, berapa banyak yang beneran kejadian?',
          duniaNyata: 'Ini yang bikin kepalamu muter terus sama "gimana kalau". Gimana kalau ditanya dan nggak bisa jawab, gimana kalau hasilnya jelek, gimana kalau semua orang merhatiin. Dari semua kemungkinan yang ada, dia selalu milih yang paling parah buat kamu bayangin.',
          techniques: [
            'Tulis semua kekhawatiranmu, lalu jadwalkan 10 menit nanti buat mikirinnya',
            'Tulis di jurnal: apa buktinya ini bakal beneran terjadi?',
            'Sebutkan 3 benda di sekitarmu sekarang, pelan-pelan, sambil tarik napas',
          ],
        ),
        'sempurna': SaboteurTexts(
          apaKatanya: 'Harusnya bisa lebih baik dari ini.',
          faktanya: '"Cukup baik" itu bukan nyerah. Itu standar yang bisa kamu jaga terus, bukan cuma bagus sekali lalu kamu kelelahan sendiri.',
          duniaNyata: 'Dia yang bikin kamu takut mulai kalau belum yakin hasilnya sempurna. Selalu ada "harusnya" di kepalamu: harusnya lebih rapi, harusnya lebih cepat, harusnya nggak salah sama sekali. Standarnya nggak pernah cukup, jadi kamu nggak pernah ngerasa selesai.',
          techniques: [
            'Sebelum mulai, ucapkan "cukup baik buat hari ini" ganti "harus sempurna"',
            'Berhenti sebentar, akui progres kecil yang udah kamu buat, baru lanjut',
            'Sebelum mulai, tulis dulu kayak apa itu "cukup selesai" buat tugas ini',
          ],
        ),
        'cermin': SaboteurTexts(
          apaKatanya: 'Hidup orang lain kelihatannya lebih oke dari punyaku.',
          faktanya: 'Medsos itu etalase, bukan cermin. Orang cuma masang potongan terbaiknya di sana. Kamu lagi bandingin balik panggungmu sendiri sama panggung depan orang lain.',
          duniaNyata: 'Dia muncul begitu kamu buka medsos, bisikin kamu buat bandingin hidupmu sama highlight reel orang lain. Makin lama kamu scroll, makin kenceng suaranya, dan makin kecil rasanya pencapaianmu sendiri.',
          techniques: [
            'Tulis 3 hal dari dirimu sendiri yang kamu banggakan, tanpa nyebut orang lain',
            'Pasang timer 15 menit sebelum buka medsos, berhenti begitu bunyi',
            'Unfollow atau mute satu akun yang bikin kamu ngerasa kurang hari ini',
          ],
        ),
        'kabut': SaboteurTexts(
          apaKatanya: 'Nanti saja, masih ada waktu.',
          faktanya: 'Tugas yang ditunda nggak pernah jadi lebih ringan, cuma nunda rasa leganya aja. Coba mulai 5 menit dulu, biasanya itu udah cukup buat motong kabutnya.',
          duniaNyata: 'Dia yang bikin semuanya kerasa berat dan buram, sampai tugas kecil pun terasa nggak mungkin dimulai. Kamu mikir dan mikir soal itu, tapi nggak pernah benar-benar mulai. Makin lama dipikirin, makin tebal kabutnya.',
          techniques: [
            'Masuk Mode Fokus 25 menit, kerjain satu tugas kecil aja',
            'Pecah tugas besarnya jadi langkah-langkah yang muat 10 menit',
            'Mulai dari bagian yang paling gampang dulu, bukan yang paling penting',
          ],
        ),
        'mengelak': SaboteurTexts(
          apaKatanya: 'Hindari saja dulu, lebih aman.',
          faktanya: 'Menghindar emang bikin lega sesaat, tapi masalahnya tetap nunggu di sana, malah numpuk. Hadapin pelan-pelan, sedikit-sedikit, biasanya jauh lebih ringan daripada yang kamu bayangin.',
          duniaNyata: 'Dia yang selalu nawarin jalan keluar tiap ada hal yang bikin kamu nggak nyaman: ganti topik, tutup chat, cari alasan buat nunda. Rasanya aman sebentar, tapi makin sering kamu lari, makin gede juga rasa takutnya.',
          techniques: [
            'Pilih 1 hal kecil yang kamu hindari, hadapin cuma 10 menit hari ini',
            'Tulis, akibat terburuknya apa sih kalau kamu beneran hadapin ini?',
            'Cerita ke satu teman soal hal yang lagi kamu hindari',
          ],
        ),
        'meronta': SaboteurTexts(
          apaKatanya: 'Kenapa selalu aku yang kena?',
          faktanya: 'Kejadian buruk itu nggak selalu soal kamu. Banyak yang emang di luar kendalimu. Yang masih bisa kamu pegang cuma satu: gimana kamu meresponsnya, bukan kenapa itu kejadian.',
          duniaNyata: 'Dia yang bikin kamu ngerasa dunia lagi nargetin kamu doang. Setiap ada yang salah, dia langsung nunjuk "ini gara-gara kamu" atau "ini emang nasib kamu". Padahal banyak kejadian yang sama sekali bukan soal kamu.',
          techniques: [
            'Tulis 1 hal yang masih bisa kamu kendalikan hari ini, sekecil apa pun',
            'Pisahkan: ini "yang kejadian" atau "cerita yang aku bikin soal kenapa ke aku"?',
            'Jalan kaki 10 menit aja dulu, buat reset energi',
          ],
        ),
      };

  @override
  String saboteurDescription(String id, String fallback) => fallback;
}

class MonsterStringsEn extends MonsterStrings {
  const MonsterStringsEn();

  @override
  String get loadError => 'Could not load your monsters.';
  @override
  String get vaultTitle => 'Your monsters';
  @override
  String vaultSub(int tamed) => '$tamed of 7 already tamed';
  @override
  String get bossBadge => 'BOSS';
  @override
  String get hakimBlurb => 'The voice that says you will "surely fail". His six minions weaken when he weakens.';
  @override
  String progressToTamed(int percent) => '$percent% to tamed';
  @override
  String get minions => 'His minions';
  @override
  String get tamedBadge => 'TAMED';

  @override
  String get realWorld => 'IN THE REAL WORLD, HE IS…';
  @override
  String get whatItSays => 'WHAT IT SAYS';
  @override
  String get theFact => 'THE FACT';
  @override
  String get antidotes => 'ANTIDOTE TECHNIQUES';
  @override
  String get antidoteNote => 'The right technique = a bigger attack in the mini-game.';
  @override
  String get wild => 'Wild';
  @override
  String get tamed => 'Tamed';
  @override
  String tamedPercent(int percent) => '$percent% TAMED';
  @override
  String get attack => 'Attack';
  @override
  String get cbtPractice => 'CBT practice';

  @override
  String get stageMapTitle => 'Si Waswas training path';
  @override
  String get stageMapIntro => "It's not one attack and done — a bit of practice first, then face him.";
  @override
  String stageLevelLabel(int level) => 'Level $level';
  @override
  String get stageOwlIntro => "Hi, I'm your friend here. Let's walk the path slowly — no need to do it all at once.";
  @override
  String get stageNodeJournalTitle => 'Write down one worry';
  @override
  String get stageNodeJournalDone => 'Written today';
  @override
  String get stageNodeBreathTitle => 'Breathing practice';
  @override
  String get stageNodeBreathDone => 'Breathed today';
  @override
  String get stageNodeAfirmasiTitle => 'Talk to yourself';
  @override
  String get stageNodeAfirmasiDone => 'Talked to yourself today';
  @override
  String get stageNodeBossTitle => 'Face Si Waswas';
  @override
  String stageNodeBossSub(int percent) => '$percent% to tamed';
  @override
  String get stageNodeLabelDone => 'Done';

  @override
  String get hakimIntro =>
      'The boss of all monsters. The judge in your head who issues verdicts before you even try: "you will surely fail", "you do not deserve it".';
  @override
  String bossPercent(int percent) => 'BOSS · $percent%';
  @override
  String get minionsHeading => 'MINIONS HE LEADS';
  @override
  String get minionsNote =>
      "Each tamed minion reduces Si Hakim's strength by 5%. Tame them all to unlock the final battle.";

  @override
  String monsterNumberTamed(int number) => 'MONSTER #$number TAMED';
  @override
  String friendNow(String monsterName) => '$monsterName is now your friend';
  @override
  String get celebrationBody =>
      'It is not gone. That way of thinking never truly disappears. But now it walks with you, instead of chasing you.';
  @override
  String get bonusCoins => 'bonus coins';
  @override
  String get tamedLabel => 'tamed';
  @override
  String get shareAchievement => 'Share achievement';
  @override
  String get shareNote => 'Only the card is shared, not your journal or your data 🔒';
  @override
  String get cardShareFailed => 'Could not share the achievement, please try again.';
  @override
  String shareCaption(String monsterName, int tamed) => '$monsterName is now my friend. $tamed of 7 monsters tamed, via Riung 💜';

  @override
  Map<String, SaboteurTexts> get saboteurTexts => const {
        'hakim': SaboteurTexts(
          apaKatanya: 'You are going to fail. Like always.',
          faktanya: 'Come on, "always" and "never" are rarely true. Just one small success is enough to make that verdict wobble, and you have more than one.',
          duniaNyata: 'This is the harshest voice in your head. He whispers every time you want to try something, saying you will fail before you even get to start. The moment he speaks, anxiety shows up, the urge to not move shows up, the feeling of not being enough shows up. He is the one who lights it all up.',
          techniques: [
            'Write 3 small pieces of evidence from today that disprove his verdict',
            'Say it to yourself exactly the way you would comfort a friend',
            'The moment you hear his voice, say out loud: "that is Si Hakim, not a fact"',
          ],
        ),
        'waswas': SaboteurTexts(
          apaKatanya: 'What if everything falls apart tomorrow?',
          faktanya: 'A thought is not a prediction. Try counting: of everything you feared last week, how many actually happened?',
          duniaNyata: 'This is what keeps your head spinning with "what if". What if you get asked and cannot answer, what if the result is bad, what if everyone is watching. Out of all the possibilities, he always picks the worst one for you to imagine.',
          techniques: [
            'Write down all your worries, then schedule 10 minutes later to think about them',
            'Write in your journal: what is the evidence this will actually happen?',
            'Name 3 things around you right now, slowly, while taking a breath',
          ],
        ),
        'sempurna': SaboteurTexts(
          apaKatanya: 'It should be better than this.',
          faktanya: '"Good enough" is not giving up. It is a standard you can keep up, not just something great once before you burn yourself out.',
          duniaNyata: 'He is the one who makes you afraid to start unless you are sure the result will be perfect. There is always a "should" in your head: should be neater, should be faster, should not have any mistakes at all. The standard is never enough, so you never feel done.',
          techniques: [
            'Before starting, say "good enough for today" instead of "must be perfect"',
            'Pause for a moment, acknowledge the small progress you have made, then continue',
            'Before starting, write down what "done enough" looks like for this task',
          ],
        ),
        'cermin': SaboteurTexts(
          apaKatanya: 'Other people\'s lives look better than mine.',
          faktanya: 'Social media is a shop window, not a mirror. People only put their best pieces up there. You are comparing your own backstage with everyone else\'s front stage.',
          duniaNyata: 'He shows up the moment you open social media, whispering for you to compare your life with other people\'s highlight reels. The longer you scroll, the louder his voice gets, and the smaller your own achievements feel.',
          techniques: [
            'Write 3 things about yourself that you are proud of, without mentioning anyone else',
            'Set a 15-minute timer before opening social media, stop as soon as it rings',
            'Unfollow or mute one account that makes you feel not enough today',
          ],
        ),
        'kabut': SaboteurTexts(
          apaKatanya: 'Later, there is still time.',
          faktanya: 'A postponed task never gets lighter, it only postpones the relief. Try starting for 5 minutes, that is usually enough to cut through the fog.',
          duniaNyata: 'He is the one who makes everything feel heavy and blurry, until even a small task feels impossible to start. You think and think about it, but never really begin. The longer you think, the thicker the fog gets.',
          techniques: [
            'Enter a 25-minute Focus Mode, do just one small task',
            'Break the big task into steps that fit in 10 minutes',
            'Start with the easiest part first, not the most important one',
          ],
        ),
        'mengelak': SaboteurTexts(
          apaKatanya: 'Just avoid it for now, it is safer.',
          faktanya: 'Avoiding does feel like relief for a moment, but the problem keeps waiting there and even piles up. Face it slowly, little by little, it is usually much lighter than you imagine.',
          duniaNyata: 'He is the one who always offers a way out whenever something makes you uncomfortable: change the subject, close the chat, find an excuse to postpone. It feels safe for a while, but the more you run, the bigger the fear grows.',
          techniques: [
            'Pick 1 small thing you avoid, face it for just 10 minutes today',
            'Write down: what is the worst outcome if you really face this?',
            'Tell one friend about the thing you have been avoiding',
          ],
        ),
        'meronta': SaboteurTexts(
          apaKatanya: 'Why is it always me?',
          faktanya: 'Bad things are not always about you. Many are beyond your control. The one thing you can still hold on to: how you respond, not why it happened.',
          duniaNyata: 'He is the one who makes you feel the world is targeting only you. Whenever something goes wrong, he immediately points and says "this is because of you" or "this is just your fate". Yet many events are not about you at all.',
          techniques: [
            'Write 1 thing you can still control today, however small',
            'Separate: is this "what happened" or "the story I made up about why it happened to me"?',
            'Just walk for 10 minutes first, to reset your energy',
          ],
        ),
      };

  @override
  String saboteurDescription(String id, String fallback) => _descriptions[id] ?? fallback;

  static const Map<String, String> _descriptions = {
        'meronta': 'Exaggerates misfortune and makes you feel helpless. \'Why is it always me?\'',
        'waswas': 'Always imagines the worst-case scenario that may never happen.',
        'kabut': 'Blurs your goals until everything feels too heavy to start.',
        'cermin': 'Reflects a distorted version of you through comparison with other people.',
        'sempurna': 'Carries a \'red pen\' and is never satisfied with your effort.',
        'mengelak': 'Slippery, always takes you away from anything uncomfortable.',
        'hakim': 'The main saboteur, the voice that judges you and others, the one who wakes the other saboteurs.',
  };
}
