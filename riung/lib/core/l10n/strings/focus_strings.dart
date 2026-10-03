/// Teks pintu masuk tab Fokus.
abstract class FocusStrings {
  const FocusStrings();

  String get title;
  String get subtitle;
  String get worksOffline;
  String attackTickets(int tickets);
  String prepaidSessions(int sessions);
  String get notEnoughCoins;
  String startPrepaid(int minutes);
  String startFree(int minutes);
  String startPaid(int minutes, int coins);
  String get minutesUnit;
}

class FocusStringsId extends FocusStrings {
  const FocusStringsId();

  @override
  String get title => 'Mode Fokus';
  @override
  String get subtitle => 'Istirahatkan pikiran dari scroll. Pilih durasinya dulu.';
  @override
  String get worksOffline => 'Bisa dipakai offline';
  @override
  String attackTickets(int tickets) => '$tickets tiket serangan';
  @override
  String prepaidSessions(int sessions) => '$sessions sesi prabayar';
  @override
  String get notEnoughCoins => 'Koinmu belum cukup. Cara tercepat: check-in pagi, jurnal, atau selesaikan misi harian dulu.';
  @override
  String startPrepaid(int minutes) => 'Mulai fokus $minutes menit • pakai sesi prabayar';
  @override
  String startFree(int minutes) => 'Mulai fokus $minutes menit • gratis hari ini';
  @override
  String startPaid(int minutes, int coins) => 'Mulai fokus $minutes menit • $coins koin';
  @override
  String get minutesUnit => 'menit';
}

class FocusStringsEn extends FocusStrings {
  const FocusStringsEn();

  @override
  String get title => 'Focus Mode';
  @override
  String get subtitle => 'Rest your mind from scrolling. Choose a duration first.';
  @override
  String get worksOffline => 'Works offline';
  @override
  String attackTickets(int tickets) => tickets == 1 ? '1 attack ticket' : '$tickets attack tickets';
  @override
  String prepaidSessions(int sessions) => sessions == 1 ? '1 prepaid session' : '$sessions prepaid sessions';
  @override
  String get notEnoughCoins => 'Not enough coins yet. Fastest ways: morning check-in, journal, or finish your daily missions first.';
  @override
  String startPrepaid(int minutes) => 'Start focus $minutes min • use a prepaid session';
  @override
  String startFree(int minutes) => 'Start focus $minutes min • free today';
  @override
  String startPaid(int minutes, int coins) => 'Start focus $minutes min • $coins coins';
  @override
  String get minutesUnit => 'min';
}
