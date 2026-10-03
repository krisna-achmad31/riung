import '../config/economy.dart';
import 'model_utils.dart';

/// Mirror `/users/{uid}` — sub-map `profile`, `premium`, `streak`, `assessment`.
/// Sub-map `wallet` PUNYA model sendiri ([Wallet]) karena hanya boleh ditulis
/// Cloud Functions; sub-map lain di sini boleh ditulis client (lewat service
/// typed, bukan map literal di layar).
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.avatarId,
    required this.locale,
    required this.persona,
    required this.createdAt,
    required this.onboardingDone,
    required this.premiumActive,
    this.premiumPlan,
    this.premiumRenewsAt,
    required this.streakCurrent,
    required this.streakLongest,
    this.lastCheckinDate,
    required this.dominantSaboteurs,
    required this.assessmentScores,
    this.assessmentCompletedAt,
  });

  factory UserProfile.kosong(String uid) {
    return UserProfile(
      uid: uid,
      displayName: '',
      avatarId: 'av1',
      locale: 'id',
      persona: null,
      createdAt: DateTime.now(),
      onboardingDone: false,
      premiumActive: false,
      streakCurrent: 0,
      streakLongest: 0,
      dominantSaboteurs: const [],
      assessmentScores: const {},
    );
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> doc) {
    final profile = (doc[kProfile] as Map?)?.cast<String, dynamic>() ?? const {};
    final premium = (doc[kPremium] as Map?)?.cast<String, dynamic>() ?? const {};
    final streak = (doc[kStreak] as Map?)?.cast<String, dynamic>() ?? const {};
    final assessment = (doc[kAssessment] as Map?)?.cast<String, dynamic>() ?? const {};

    return UserProfile(
      uid: uid,
      displayName: profile[fDisplayName] as String? ?? '',
      avatarId: profile[fAvatarId] as String? ?? 'av1',
      locale: profile[fLocale] as String? ?? 'id',
      persona: profile[fPersona] as String?,
      createdAt: parseDate(profile[fCreatedAt]) ?? DateTime.now(),
      onboardingDone: profile[fOnboardingDone] as bool? ?? false,
      premiumActive: premium[fPremiumActive] as bool? ?? false,
      premiumPlan: premium[fPremiumPlan] as String?,
      premiumRenewsAt: parseDate(premium[fPremiumRenewsAt]),
      streakCurrent: parseInt(streak[fStreakCurrent]),
      streakLongest: parseInt(streak[fStreakLongest]),
      lastCheckinDate: parseDate(streak[fLastCheckinDate]),
      dominantSaboteurs: parseStringList(assessment[fDominantSaboteurs]),
      assessmentScores: parseIntMap(assessment[fScores]),
      assessmentCompletedAt: parseDate(assessment[fCompletedAt]),
    );
  }

  // Nama sub-map top-level di dokumen /users/{uid}.
  static const kProfile = 'profile';
  static const kPremium = 'premium';
  static const kStreak = 'streak';
  static const kAssessment = 'assessment';

  // Field di dalam profile.
  static const fDisplayName = 'displayName';
  static const fAvatarId = 'avatarId';
  static const fLocale = 'locale';
  static const fPersona = 'persona';
  static const fCreatedAt = 'createdAt';
  static const fOnboardingDone = 'onboardingDone';

  // Field di dalam premium.
  static const fPremiumActive = 'active';
  static const fPremiumPlan = 'plan';
  static const fPremiumRenewsAt = 'renewsAt';

  // Field di dalam streak.
  static const fStreakCurrent = 'current';
  static const fStreakLongest = 'longest';
  static const fLastCheckinDate = 'lastCheckinDate';

  // Field di dalam assessment.
  static const fDominantSaboteurs = 'dominantSaboteurs';
  static const fScores = 'scores';
  static const fCompletedAt = 'completedAt';

  final String uid;
  final String displayName;
  final String avatarId;
  final String locale;
  final String? persona;
  final DateTime createdAt;
  final bool onboardingDone;

  final bool premiumActive;

  /// Premium yang benar-benar berlaku SEKARANG: flag aktif dan belum lewat
  /// tanggal perpanjangan (+ [EconomyPremium.graceHari]). Semua gerbang fitur
  /// memakai ini, bukan [premiumActive] mentah.
  bool get premiumNow => premiumStatus(DateTime.now()) == PremiumStatus.active || premiumStatus(DateTime.now()) == PremiumStatus.renewsSoon;

  bool get isAnnual => premiumPlan == 'premium_yearly';

  PremiumStatus premiumStatus(DateTime now) {
    if (!premiumActive) return PremiumStatus.none;
    final renews = premiumRenewsAt;
    if (renews == null) return PremiumStatus.active;
    if (now.isAfter(renews.add(const Duration(days: EconomyPremium.graceHari)))) return PremiumStatus.expired;
    if (now.isAfter(renews)) return PremiumStatus.renewsSoon; // dalam masa toleransi
    if (renews.difference(now).inDays < 3) return PremiumStatus.renewsSoon;
    return PremiumStatus.active;
  }
  final String? premiumPlan;
  final DateTime? premiumRenewsAt;

  final int streakCurrent;
  final int streakLongest;
  final DateTime? lastCheckinDate;

  final List<String> dominantSaboteurs;
  final Map<String, int> assessmentScores;
  final DateTime? assessmentCompletedAt;

  Map<String, dynamic> toMap() => {
        kProfile: {
          fDisplayName: displayName,
          fAvatarId: avatarId,
          fLocale: locale,
          fPersona: persona,
          fCreatedAt: createdAt.toIso8601String(),
          fOnboardingDone: onboardingDone,
        },
        kPremium: {
          fPremiumActive: premiumActive,
          fPremiumPlan: premiumPlan,
          fPremiumRenewsAt: premiumRenewsAt?.toIso8601String(),
        },
        kStreak: {
          fStreakCurrent: streakCurrent,
          fStreakLongest: streakLongest,
          fLastCheckinDate: lastCheckinDate?.toIso8601String(),
        },
        kAssessment: {
          fDominantSaboteurs: dominantSaboteurs,
          fScores: assessmentScores,
          fCompletedAt: assessmentCompletedAt?.toIso8601String(),
        },
      };

  UserProfile copyWith({
    String? displayName,
    String? avatarId,
    String? locale,
    String? persona,
    bool? onboardingDone,
    bool? premiumActive,
    String? premiumPlan,
    DateTime? premiumRenewsAt,
    int? streakCurrent,
    int? streakLongest,
    DateTime? lastCheckinDate,
    List<String>? dominantSaboteurs,
    Map<String, int>? assessmentScores,
    DateTime? assessmentCompletedAt,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      avatarId: avatarId ?? this.avatarId,
      locale: locale ?? this.locale,
      persona: persona ?? this.persona,
      createdAt: createdAt,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      premiumActive: premiumActive ?? this.premiumActive,
      premiumPlan: premiumPlan ?? this.premiumPlan,
      premiumRenewsAt: premiumRenewsAt ?? this.premiumRenewsAt,
      streakCurrent: streakCurrent ?? this.streakCurrent,
      streakLongest: streakLongest ?? this.streakLongest,
      lastCheckinDate: lastCheckinDate ?? this.lastCheckinDate,
      dominantSaboteurs: dominantSaboteurs ?? this.dominantSaboteurs,
      assessmentScores: assessmentScores ?? this.assessmentScores,
      assessmentCompletedAt: assessmentCompletedAt ?? this.assessmentCompletedAt,
    );
  }
}

/// Status langganan Premium untuk tampilan & gerbang fitur.
enum PremiumStatus { none, active, renewsSoon, expired }
