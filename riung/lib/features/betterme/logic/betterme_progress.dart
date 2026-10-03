import '../../../core/services/local_prefs_store.dart';
import '../data/betterme_content.dart';

/// Helper progres Better Me — baca/tulis langsung ke [LocalPrefsStore],
/// tidak perlu ChangeNotifier terpisah karena tiap layar sudah reload
/// state-nya lewat `initState` setiap kali dibuka lagi (alur linear,
/// beda dari Aplikasi Beku yang butuh reaktif lintas layar sekaligus).
class BetterMeProgress {
  const BetterMeProgress(this.prefs);

  final LocalPrefsStore prefs;

  bool isCompleted(String sessionId) => prefs.betterMeCompleted.contains(sessionId);

  int completedInLevel(int level) {
    final completed = prefs.betterMeCompleted;
    final target = betterMeLevels.firstWhere((l) => l.number == level);
    return target.sessions.where((s) => completed.contains(s.id)).length;
  }

  bool isLevelComplete(int level) {
    final target = betterMeLevels.firstWhere((l) => l.number == level);
    return completedInLevel(level) == target.sessions.length;
  }

  /// Level 1 selalu terbuka buat siapa pun. Level 2/3 butuh Riung Premium
  /// DAN level sebelumnya sudah selesai — lihat CLAUDE.md M6 Task 5.
  bool isLevelUnlocked(int level, {required bool premiumActive}) {
    if (level == 1) return true;
    if (!premiumActive) return false;
    return isLevelComplete(level - 1);
  }

  Future<void> markCompleted(String sessionId) async {
    final updated = {...prefs.betterMeCompleted, sessionId};
    await prefs.setBetterMeCompleted(updated);
  }

  String? reflectionFor(String sessionId) => prefs.betterMeReflectionsJson[sessionId] as String?;

  Future<void> saveReflection(String sessionId, String text) async {
    final updated = {...prefs.betterMeReflectionsJson, sessionId: text};
    await prefs.setBetterMeReflectionsJson(updated);
  }

  int get totalCompleted => prefs.betterMeCompleted.length;
}
