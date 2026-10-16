import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riung/core/models/assessment_draft.dart';
import 'package:riung/core/services/assessment_draft_store.dart';
import 'package:riung/features/onboarding/logic/onboarding_controller.dart';
import 'package:riung/features/onboarding/logic/onboarding_questions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'draft survives controller restart and is isolated by account',
    () async {
      final store = AssessmentDraftStore();
      final controller = OnboardingController(resumeAssessment: true);
      controller.toggleAnswer(onboardingQuestions.first, 1);
      controller.next();
      controller.setFreeText('private reflection');
      controller.setNama('Rani');
      await store.save('guest', controller.draft);
      expect(await store.read('other-account'), isNull);
      final resumed = OnboardingController(draft: await store.read('guest'));
      expect(resumed.currentStep.dataIndex, 1);
      expect(resumed.isSelected(1, 1), isTrue);
      expect(resumed.freeText, 'private reflection');
      expect(resumed.nama, 'Rani');
      expect(resumed.result, isNull);
      await store.clear('guest');
      expect(await store.read('guest'), isNull);
      controller.dispose();
      resumed.dispose();
    },
  );
  test('invalid or incomplete draft cannot skip unanswered questions', () {
    final controller = OnboardingController(
      draft: const AssessmentDraft(
        step: 500,
        answers: {
          1: {999},
        },
        freeText: '',
        name: '',
      ),
    );
    expect(controller.stepIndex, 1);
    expect(controller.answersFor(1), isEmpty);
    controller.dispose();
  });
  test('corrupt draft does not block starting a fresh assessment', () async {
    FlutterSecureStorage.setMockInitialValues({
      'assessment_draft_v1_user': '{broken',
    });
    expect(await AssessmentDraftStore().read('user'), isNull);
  });
}
