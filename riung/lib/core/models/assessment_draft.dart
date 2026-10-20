class AssessmentDraft {
  const AssessmentDraft({
    required this.step,
    required this.answers,
    required this.freeText,
    required this.name,
  });
  final int step;
  final Map<int, Set<int>> answers;
  final String freeText;
  final String name;

  Map<String, dynamic> toMap() => {
    'step': step,
    'answers': answers.map((key, value) => MapEntry('$key', value.toList())),
    'freeText': freeText,
    'name': name,
  };

  factory AssessmentDraft.fromMap(Map<String, dynamic> map) => AssessmentDraft(
    step: (map['step'] as num).toInt(),
    answers: (map['answers'] as Map).map(
      (key, value) => MapEntry(
        int.parse(key as String),
        (value as List).cast<int>().toSet(),
      ),
    ),
    freeText: map['freeText'] as String? ?? '',
    name: map['name'] as String? ?? '',
  );
}
