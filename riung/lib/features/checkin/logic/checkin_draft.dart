/// Data yang terkumpul selama wizard check-in 3 langkah — dilempar dari
/// layar ke layar (bukan notifier global, hidup hanya selama sesi wizard).
class CheckInDraft {
  CheckInDraft();

  String? moodId;
  final List<String> factorIds = [];
  String note = '';
}
