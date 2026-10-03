import 'model_utils.dart';

/// Status penjinakan satu saboteur untuk user tertentu.
enum MonsterState { wild, taming, tamed }

/// Mirror `/users/{uid}/monsters/{saboteurId}`.
class MonsterProgress {
  const MonsterProgress({
    required this.saboteurId,
    required this.state,
    required this.progress,
    this.tamedAt,
  });

  factory MonsterProgress.initial(String saboteurId) => MonsterProgress(
        saboteurId: saboteurId,
        state: MonsterState.wild,
        progress: 0,
      );

  factory MonsterProgress.fromMap(String saboteurId, Map<String, dynamic> map) {
    return MonsterProgress(
      saboteurId: saboteurId,
      state: enumFromName(MonsterState.values, map[fState] as String?, MonsterState.wild),
      progress: parseInt(map[fProgress]).clamp(0, 100),
      tamedAt: parseDate(map[fTamedAt]),
    );
  }

  static const fState = 'state';
  static const fProgress = 'progress';
  static const fTamedAt = 'tamedAt';

  final String saboteurId;
  final MonsterState state;
  final int progress;
  final DateTime? tamedAt;

  Map<String, dynamic> toMap() => {
        fState: state.name,
        fProgress: progress,
        if (tamedAt != null) fTamedAt: tamedAt!.toIso8601String(),
      };

  MonsterProgress copyWith({
    MonsterState? state,
    int? progress,
    DateTime? tamedAt,
  }) {
    return MonsterProgress(
      saboteurId: saboteurId,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      tamedAt: tamedAt ?? this.tamedAt,
    );
  }
}
