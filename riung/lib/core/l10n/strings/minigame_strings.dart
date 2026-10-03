/// Teks fitur Minigame: intro serangan, sesi napas, menang/kalah, batas harian.
abstract class MinigameStrings {
  const MinigameStrings();

  // ── Intro ──
  String introKicker(bool isReaction);
  String get introKickerBoss;
  String introTitle(String monsterName);
  String introBody(int seconds, bool isReaction);
  String get chipStrength;
  String get chipCoinsIfWin;
  String get chipOneTicket;
  String get chipPerAttack;
  String get startAttack;
  String introRules(int fromPractice, int maxPerDay);
  String get introEthic;
  String owlTip(String saboteurId);

  // ── Batas harian ──
  String get capTitle;
  String capBody(int maxPerDay);
  String get capHowTo;
  String get capWayCheckin;
  String get capWayMeditation;
  String get capWayJournal;
  String get capBack;

  // ── Sesi napas ──
  String get exitTitle;
  String get exitBody;
  String get points;
  String hpLabel(String monsterName, int hp);
  List<String> get verdictLabels;

  // —— Lepaskan Pikiran (Si Waswas) ——
  String get waswasReactionHint;
  List<String> get worryLabels;
  String get dragHint;
  String get tapToLaunch;
  String blockBroken(String label, int points);
  String get livesLabel;

  // ── Kalah ──
  String get loseTitle;
  String loseBody(int score, int hits, String monsterName, bool isReaction);
  String get chipStillHits;
  String get chipTicketsLeft;
  String get loseCbtNote;
  String get tryAgain;

  // ── Menang ──
  String get winKicker;
  String winTitle(String monsterName);
  String winBody(int score, int hits, bool isReaction);
  String get chipStrengthShort;
  String get chipCoins;
  String winProgress(String monsterName, int before, int after);
  String get attackAgain;
  String get enoughBack;
}

class MinigameStringsId extends MinigameStrings {
  const MinigameStringsId();

  @override
  String introKicker(bool isReaction) => isReaction ? 'LEPASKAN PIKIRAN · SERANGAN' : 'PECAHKAN BALOK · SERANGAN';
  @override
  String get introKickerBoss => 'PECAHKAN BALOK · SERANGAN BOS';
  @override
  String introTitle(String monsterName) => '$monsterName sedang lengah';
  @override
  String introBody(int seconds, bool isReaction) => isReaction
      ? 'Sentuh gelembung pikirannya sebelum sampai garis atas — bukan dihancurkan, cukup dilepaskan satu-satu. $seconds detik per serangan.'
      : 'Pantulkan bola, pecahkan balok "vonis"-nya. Tiap balok pecah = kritik yang kamu patahkan. $seconds detik per serangan.';
  @override
  String get chipStrength => 'kekuatannya';
  @override
  String get chipCoinsIfWin => 'koin bila menang';
  @override
  String get chipOneTicket => '1 tiket';
  @override
  String get chipPerAttack => 'per serangan';
  @override
  String get startAttack => 'Mulai serangan';
  @override
  String introRules(int fromPractice, int maxPerDay) =>
      'Hari ini: 1 gratis + hingga $fromPractice dari latihan · maks $maxPerDay serangan sehari';
  @override
  String get introEthic =>
      'Progres monstermu nggak bisa dibeli, cuma latihan yang bisa. Latihan yang baik itu sedikit tapi rutin.';
  @override
  String owlTip(String saboteurId) => switch (saboteurId) {
        'waswas' => 'Kalau muncul pikiran terburuk, coba tarik napas dulu — nggak usah ditahan, cukup dilepas satu-satu.',
        'hakim' => 'Balok-balok itu cuma kalimat, bukan fakta. Kamu boleh mematahkannya.',
        _ => 'Nggak perlu sempurna. Satu latihan kecil hari ini sudah cukup.',
      };

  @override
  String get capTitle => 'Tiket harianmu habis';
  @override
  String capBody(int maxPerDay) =>
      'Latihan lagi besok ya. Maks $maxPerDay serangan sehari itu sengaja, supaya ini tetap latihan napas, bukan grinding.';
  @override
  String get capHowTo => 'Cara dapat tiket lagi besok:';
  @override
  String get capWayCheckin => 'Check-in pagi';
  @override
  String get capWayMeditation => 'Meditasi';
  @override
  String get capWayJournal => 'Tulis satu entri jurnal';
  @override
  String get capBack => 'Kembali ke Vault';

  @override
  String get exitTitle => 'Keluar dari serangan?';
  @override
  String get exitBody => 'Tiket yang sudah dipakai tidak kembali, tapi kamu nggak dihukum apa pun. Coba lagi kapan saja.';
  @override
  String get points => 'pts';
  @override
  String hpLabel(String monsterName, int hp) => 'HP $monsterName · $hp%';
  @override
  List<String> get verdictLabels => const ['PASTI GAGAL', 'NGGAK PANTAS', 'TELAT MULAI', 'KURANG PINTAR', 'BUKAN BAKATMU'];

  @override
  String get waswasReactionHint => 'Sentuh gelembungnya sebelum sampai garis atas — bukan dihancurkan, cukup dilepaskan.';
  @override
  List<String> get worryLabels => const ['Pasti gagal', 'Semua bakal berantakan', 'Mereka pasti nge-judge', 'Nanti kejadian terburuk', 'Aku nggak siap', 'Semua bakal salah'];
  @override
  String get dragHint => 'Geser buat gerakkan papan';
  @override
  String get tapToLaunch => 'Ketuk layar buat meluncurkan bola';
  @override
  String blockBroken(String label, int points) => 'Balok "$label" pecah! +$points pts';
  @override
  String get livesLabel => 'nyawa';

  @override
  String get loseTitle => 'Kali ini dia masih bertahan';
  @override
  String loseBody(int score, int hits, String monsterName, bool isReaction) => isReaction
      ? '$score poin, $hits gelembung pikiran dilepaskan. Lumayan buat percobaan berikutnya. Poinmu tetap dihitung, dan $monsterName tetap kena '
      : '$score poin, $hits balok pecah. Lumayan buat percobaan berikutnya. Poinmu tetap dihitung, dan $monsterName tetap kena ';
  @override
  String get chipStillHits => 'tetap kena';
  @override
  String get chipTicketsLeft => 'tiket tersisa';
  @override
  String get loseCbtNote =>
      'Ini juga latihan CBT: gagal sekali bukan berarti "pasti gagal". Persis pikiran yang lagi kamu lawan.';
  @override
  String get tryAgain => 'Coba lagi (1 tiket)';

  @override
  String get winKicker => 'SERANGAN BERHASIL';
  @override
  String winTitle(String monsterName) => '$monsterName melemah!';
  @override
  String winBody(int score, int hits, bool isReaction) => isReaction
      ? '$score poin, $hits gelembung pikiran berhasil dilepaskan. Makin sering dilatih, makin gampang dilepaskan.'
      : '$score poin, $hits balok "vonis" pecah. Suaranya makin kecil tiap kali kamu melawannya.';
  @override
  String get chipStrengthShort => 'kekuatan';
  @override
  String get chipCoins => 'koin';
  @override
  String winProgress(String monsterName, int before, int after) => '$monsterName: $before% → $after% menuju jinak';
  @override
  String get attackAgain => 'Serang lagi (1 tiket)';
  @override
  String get enoughBack => 'Cukup dulu, kembali';
}

class MinigameStringsEn extends MinigameStrings {
  const MinigameStringsEn();

  @override
  String introKicker(bool isReaction) => isReaction ? 'LET GO OF THOUGHTS · ATTACK' : 'BLOCK BREAKER · ATTACK';
  @override
  String get introKickerBoss => 'BLOCK BREAKER · BOSS ATTACK';
  @override
  String introTitle(String monsterName) => '$monsterName has let their guard down';
  @override
  String introBody(int seconds, bool isReaction) => isReaction
      ? 'Tap each worry bubble before it reaches the top line — not to crush it, just to let it go, one at a time. $seconds seconds per attack.'
      : 'Bounce the ball and break its "verdict" blocks. Every block that breaks is a criticism you have broken. $seconds seconds per attack.';
  @override
  String get chipStrength => 'its strength';
  @override
  String get chipCoinsIfWin => 'coins if you win';
  @override
  String get chipOneTicket => '1 ticket';
  @override
  String get chipPerAttack => 'per attack';
  @override
  String get startAttack => 'Start attack';
  @override
  String introRules(int fromPractice, int maxPerDay) =>
      'Today: 1 free + up to $fromPractice from practice · max $maxPerDay attacks a day';
  @override
  String get introEthic =>
      "Your monster progress can't be bought, only practice can. Good practice is small but regular.";
  @override
  String owlTip(String saboteurId) => switch (saboteurId) {
        'waswas' => 'When a worst-case thought shows up, try a slow breath first — no need to hold it in, just let it pass one at a time.',
        'hakim' => "Those blocks are just sentences, not facts. You're allowed to break them.",
        _ => "You don't need to be perfect. One small practice today is enough.",
      };

  @override
  String get capTitle => 'Your daily tickets are used up';
  @override
  String capBody(int maxPerDay) =>
      'Practice again tomorrow. The max of $maxPerDay attacks a day is intentional, so this stays a breathing exercise, not grinding.';
  @override
  String get capHowTo => 'Ways to get tickets again tomorrow:';
  @override
  String get capWayCheckin => 'Morning check-in';
  @override
  String get capWayMeditation => 'Meditation';
  @override
  String get capWayJournal => 'Write one journal entry';
  @override
  String get capBack => 'Back to the Vault';

  @override
  String get exitTitle => 'Leave the attack?';
  @override
  String get exitBody =>
      'The ticket you already used is not returned, but you are not penalized in any way. Try again anytime.';
  @override
  String get points => 'pts';
  @override
  String hpLabel(String monsterName, int hp) => 'HP $monsterName · $hp%';
  @override
  List<String> get verdictLabels => const ['WILL FAIL', 'NOT WORTHY', 'TOO LATE', 'NOT SMART', 'NOT YOUR TALENT'];

  @override
  String get waswasReactionHint => 'Tap each bubble before it reaches the top line — not to crush it, just to let it go.';
  @override
  List<String> get worryLabels => const ['I will fail', 'Everything will fall apart', "They'll judge me", 'The worst will happen', "I'm not ready", 'Everything will go wrong'];
  @override
  String get dragHint => 'Drag to move the paddle';
  @override
  String get tapToLaunch => 'Tap to launch the ball';
  @override
  String blockBroken(String label, int points) => 'The "$label" block breaks! +$points pts';
  @override
  String get livesLabel => 'lives';

  @override
  String get loseTitle => 'It held on this time';
  @override
  String loseBody(int score, int hits, String monsterName, bool isReaction) => isReaction
      ? '$score points, $hits worry bubbles let go. Not bad for the next try. Your points still count, and $monsterName still takes '
      : '$score points, $hits blocks broken. Not bad for the next try. Your points still count, and $monsterName still takes ';
  @override
  String get chipStillHits => 'still lands';
  @override
  String get chipTicketsLeft => 'tickets left';
  @override
  String get loseCbtNote =>
      'This is CBT practice too: failing once does not mean "doomed to fail". Exactly the kind of thought you are fighting.';
  @override
  String get tryAgain => 'Try again (1 ticket)';

  @override
  String get winKicker => 'ATTACK SUCCESSFUL';
  @override
  String winTitle(String monsterName) => '$monsterName is weakening!';
  @override
  String winBody(int score, int hits, bool isReaction) => isReaction
      ? '$score points, $hits worry bubbles let go. The more you practice, the easier it gets to release them.'
      : '$score points, $hits "verdict" blocks broken. Its voice gets smaller every time you fight it.';
  @override
  String get chipStrengthShort => 'strength';
  @override
  String get chipCoins => 'coins';
  @override
  String winProgress(String monsterName, int before, int after) => '$monsterName: $before% → $after% to tamed';
  @override
  String get attackAgain => 'Attack again (1 ticket)';
  @override
  String get enoughBack => 'Enough for now, go back';
}
