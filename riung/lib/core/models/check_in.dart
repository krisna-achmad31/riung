import 'model_utils.dart';

/// Mirror tabel lokal `checkin_history` — tersimpan sqflite (offline-first).
/// `energy`/`sleepQuality` dipertahankan untuk kompatibilitas skema meski
/// alur check-in final (`design/Checkin.dc.html`) tidak memakainya lagi —
/// yang dipakai flow nyata: `mood`, `factors`, `intention` (catatan opsional).
class CheckIn {
  const CheckIn({
    required this.date,
    required this.mood,
    this.energy = 0,
    this.sleepQuality = 0,
    this.factors = const [],
    this.intention = '',
  });

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      date: parseDate(map[fDate]) ?? DateTime.now(),
      mood: map[fMood] as String,
      energy: parseInt(map[fEnergy]),
      sleepQuality: parseInt(map[fSleepQuality]),
      factors: parseStringList(map[fFactors]),
      intention: map[fIntention] as String? ?? '',
    );
  }

  static const fDate = 'date';
  static const fMood = 'mood';
  static const fEnergy = 'energy';
  static const fSleepQuality = 'sleepQuality';
  static const fFactors = 'factors';
  static const fIntention = 'intention';

  final DateTime date;
  final String mood;
  final int energy;
  final int sleepQuality;
  final List<String> factors;
  final String intention;

  Map<String, dynamic> toMap() => {
        fDate: date.toIso8601String().split('T').first,
        fMood: mood,
        fEnergy: energy,
        fSleepQuality: sleepQuality,
        fFactors: factors,
        fIntention: intention,
      };

  CheckIn copyWith({
    DateTime? date,
    String? mood,
    int? energy,
    int? sleepQuality,
    List<String>? factors,
    String? intention,
  }) {
    return CheckIn(
      date: date ?? this.date,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      factors: factors ?? this.factors,
      intention: intention ?? this.intention,
    );
  }
}
