/// Teks notifikasi lokal (dijadwalkan di luar `BuildContext`, jadi
/// dikirim sebagai objek strings ke `LocalNotificationService`).
abstract class NotifStrings {
  const NotifStrings();

  String get appBekuTitle;
  String get appBekuBody;
  String get checkinTitle;
  String checkinBody(int coins);
  String get missionTitle;
  String missionBody(int count, String monsterName);
  String get streakTitle;
  String streakBody(int streak);
  String get affirmationTitle;
  String get sleepTitle;

  /// [name] null → sapaan generik ("kamu" / "you").
  String sleepBody(String? name);
}

class NotifStringsId extends NotifStrings {
  const NotifStringsId();

  @override
  String get appBekuTitle => 'Batas scrollmu sudah tercapai';
  @override
  String get appBekuBody => 'mau jeda sebentar?';
  @override
  String get checkinTitle => 'Pagi!';
  @override
  String checkinBody(int coins) => 'Yuk check-in dulu — 1 menit dapat +$coins koin 🌅';
  @override
  String get missionTitle => 'Misi harian sudah siap';
  @override
  String missionBody(int count, String monsterName) => '$count misi harianmu sudah siap — lawan $monsterName hari ini';
  @override
  String get streakTitle => 'Jangan sampai putus';
  @override
  String streakBody(int streak) => 'Streakmu $streak hari — jangan sampai putus, check-in yuk!';
  @override
  String get affirmationTitle => 'Afirmasi hari ini';
  @override
  String get sleepTitle => 'Pengingat tidur';
  @override
  String sleepBody(String? name) => 'Waktunya mulai melambat, ${name ?? 'kamu'} 🌙';
}

class NotifStringsEn extends NotifStrings {
  const NotifStringsEn();

  @override
  String get appBekuTitle => 'You reached your scroll limit';
  @override
  String get appBekuBody => 'want to take a short break?';
  @override
  String get checkinTitle => 'Good morning!';
  @override
  String checkinBody(int coins) => 'Time to check in — 1 minute earns +$coins coins 🌅';
  @override
  String get missionTitle => 'Your daily missions are ready';
  @override
  String missionBody(int count, String monsterName) => 'Your $count daily missions are ready — take on $monsterName today';
  @override
  String get streakTitle => "Don't let it break";
  @override
  String streakBody(int streak) => "Your streak is $streak days — don't let it break, check in!";
  @override
  String get affirmationTitle => "Today's affirmation";
  @override
  String get sleepTitle => 'Sleep reminder';
  @override
  String sleepBody(String? name) => 'Time to start slowing down, ${name ?? 'you'} 🌙';
}
