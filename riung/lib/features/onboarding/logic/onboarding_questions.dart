/// Satu opsi jawaban — `points` = sumbangan skor ke saboteur per
/// `docs/assessment-scoring-spec.md` (kosong = tidak menyumbang skor).
/// Label opsi ada di `OnboardingStrings.questions` (urutan indeks sama).
class QuestionOption {
  const QuestionOption({required this.emoji, this.points = const {}});

  final String emoji;
  final Map<String, int> points;
}

/// Satu pertanyaan asesmen (Q1–Q17). `isScored=false` untuk pertanyaan
/// konfigurasi (persona/tujuan/komitmen/jadwal) yang tidak menyumbang skor
/// saboteur — lihat spec §"Question roles". Teks pertanyaan (tag, judul,
/// sub, label opsi) ada di `OnboardingStrings.questions[number - 1]`.
class OnboardingQuestion {
  const OnboardingQuestion({
    required this.number,
    required this.isMulti,
    required this.options,
    this.isScored = true,
  });

  final int number;
  final bool isMulti;
  final List<QuestionOption> options;
  final bool isScored;
}

/// 17 pertanyaan asesmen onboarding — poin persis
/// `docs/assessment-scoring-spec.md`; copy persis `design/Onboarding.dc.html`
/// (array `QS`) ada di `OnboardingStrings`.
final List<OnboardingQuestion> onboardingQuestions = [
  const OnboardingQuestion(
    number: 1,
    isMulti: false,
    isScored: false,
    options: [
      QuestionOption(emoji: '🏫'),
      QuestionOption(emoji: '🎓'),
      QuestionOption(emoji: '💼'),
      QuestionOption(emoji: '🔀'),
    ],
  ),
  const OnboardingQuestion(
    number: 2,
    isMulti: false,
    isScored: false,
    options: [
      QuestionOption(emoji: '🌱'),
      QuestionOption(emoji: '🌿'),
      QuestionOption(emoji: '🌳'),
      QuestionOption(emoji: '🌲'),
    ],
  ),
  const OnboardingQuestion(
    number: 3,
    isMulti: true,
    options: [
      QuestionOption(emoji: '😰', points: {'waswas': 2}),
      QuestionOption(emoji: '📱', points: {'cermin': 2}),
      QuestionOption(emoji: '🌫️', points: {'kabut': 2}),
      QuestionOption(emoji: '🧠', points: {'hakim': 2}),
      QuestionOption(emoji: '😮‍💨', points: {'meronta': 2}),
      QuestionOption(emoji: '🛌', points: {'waswas': 1}),
    ],
  ),
  const OnboardingQuestion(
    number: 4,
    isMulti: false,
    options: [
      QuestionOption(emoji: '🙂', points: {'waswas': 0}),
      QuestionOption(emoji: '😕', points: {'waswas': 1}),
      QuestionOption(emoji: '😟', points: {'waswas': 2}),
      QuestionOption(emoji: '😖', points: {'waswas': 3}),
    ],
  ),
  const OnboardingQuestion(
    number: 5,
    isMulti: false,
    options: [
      QuestionOption(emoji: '✅'),
      QuestionOption(emoji: '📱', points: {'kabut': 2}),
      QuestionOption(emoji: '🌫️', points: {'kabut': 3}),
      QuestionOption(emoji: '😤', points: {'waswas': 1, 'kabut': 1}),
    ],
  ),
  const OnboardingQuestion(
    number: 6,
    isMulti: false,
    options: [
      QuestionOption(emoji: '😊'),
      QuestionOption(emoji: '😐', points: {'kabut': 1}),
      QuestionOption(emoji: '😞', points: {'cermin': 3}),
      QuestionOption(emoji: '😠', points: {'hakim': 2}),
    ],
  ),
  const OnboardingQuestion(
    number: 7,
    isMulti: true,
    options: [
      QuestionOption(emoji: '📚', points: {'waswas': 1}),
      QuestionOption(emoji: '💼', points: {'waswas': 1}),
      QuestionOption(emoji: '🚇', points: {'kabut': 1}),
      QuestionOption(emoji: '💬', points: {'cermin': 1, 'hakim': 1}),
      QuestionOption(emoji: '👥', points: {'cermin': 1}),
      QuestionOption(emoji: '💸', points: {'waswas': 1}),
      QuestionOption(emoji: '❤️', points: {'meronta': 1}),
      QuestionOption(emoji: '🔮', points: {'waswas': 1, 'kabut': 1}),
    ],
  ),
  const OnboardingQuestion(
    number: 8,
    isMulti: false,
    options: [
      QuestionOption(emoji: '😴'),
      QuestionOption(emoji: '🌗', points: {'waswas': 1}),
      QuestionOption(emoji: '🌙', points: {'waswas': 2}),
      QuestionOption(emoji: '🥱', points: {'kabut': 2}),
    ],
  ),
  const OnboardingQuestion(
    number: 9,
    isMulti: false,
    options: [
      QuestionOption(emoji: '🎉'),
      QuestionOption(emoji: '🤏', points: {'sempurna': 3}),
      QuestionOption(emoji: '👎', points: {'hakim': 3}),
      QuestionOption(emoji: '🤷'),
    ],
  ),
  const OnboardingQuestion(
    number: 10,
    isMulti: false,
    options: [
      QuestionOption(emoji: '🙂', points: {'mengelak': 0}),
      QuestionOption(emoji: '😬', points: {'mengelak': 1}),
      QuestionOption(emoji: '😖', points: {'mengelak': 2}),
      QuestionOption(
        emoji: '🙈',
        points: {'mengelak': 3, 'kabut': 1},
      ),
    ],
  ),
  const OnboardingQuestion(
    number: 11,
    isMulti: true,
    options: [
      QuestionOption(emoji: '📱', points: {'kabut': 2}),
      QuestionOption(emoji: '🎮', points: {'mengelak': 1, 'kabut': 1}),
      QuestionOption(emoji: '🍜', points: {'mengelak': 1}),
      QuestionOption(emoji: '😶', points: {'mengelak': 2}),
      QuestionOption(emoji: '🗣️'),
      QuestionOption(emoji: '🏃'),
      QuestionOption(emoji: '📓'),
      QuestionOption(emoji: '🧘'),
    ],
  ),
  const OnboardingQuestion(
    number: 12,
    isMulti: false,
    options: [
      QuestionOption(emoji: '💪'),
      QuestionOption(emoji: '😐'),
      QuestionOption(emoji: '😔', points: {'cermin': 3}),
      QuestionOption(emoji: '😞', points: {'cermin': 2, 'hakim': 1}),
    ],
  ),
  const OnboardingQuestion(
    number: 13,
    isMulti: false,
    options: [
      QuestionOption(emoji: '😮‍💨', points: {'meronta': 3}),
      QuestionOption(emoji: '🧠', points: {'hakim': 2}),
      QuestionOption(emoji: '🤷'),
      QuestionOption(emoji: '🚪', points: {'mengelak': 2}),
    ],
  ),
  const OnboardingQuestion(
    number: 14,
    isMulti: false,
    options: [
      QuestionOption(emoji: '🕊️'),
      QuestionOption(emoji: '🤔', points: {'hakim': 1}),
      QuestionOption(emoji: '⚖️', points: {'sempurna': 2, 'hakim': 1}),
      QuestionOption(
        emoji: '🔨',
        points: {'sempurna': 3, 'hakim': 2},
      ),
    ],
  ),
  const OnboardingQuestion(
    number: 15,
    isMulti: true,
    isScored: false,
    options: [
      QuestionOption(emoji: '😌'),
      QuestionOption(emoji: '🌙'),
      QuestionOption(emoji: '🎯'),
      QuestionOption(emoji: '💜'),
      QuestionOption(emoji: '🔥'),
    ],
  ),
  const OnboardingQuestion(
    number: 16,
    isMulti: false,
    isScored: false,
    options: [
      QuestionOption(emoji: '⏱️'),
      QuestionOption(emoji: '⏲️'),
      QuestionOption(emoji: '🕐'),
      QuestionOption(emoji: '🕑'),
    ],
  ),
  const OnboardingQuestion(
    number: 17,
    isMulti: false,
    isScored: false,
    options: [
      QuestionOption(emoji: '🌅'),
      QuestionOption(emoji: '☀️'),
      QuestionOption(emoji: '🌆'),
      QuestionOption(emoji: '🌙'),
    ],
  ),
];
