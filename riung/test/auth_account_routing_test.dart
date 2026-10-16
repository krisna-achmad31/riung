import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/core/state/auth_notifier.dart';
import 'package:riung/main.dart';
import 'package:riung/core/models/user_profile.dart';
import 'package:riung/features/onboarding/widgets/question_step.dart';
import 'package:riung/features/onboarding/widgets/assessment_pending_card.dart';

class _Auth implements AuthService {
  _Auth(this.uid);
  String? uid;
  final changes = StreamController<String?>.broadcast(sync: true);
  @override
  String? get currentUid => uid;
  @override
  bool get isAnonymous => uid == 'guest';
  @override
  String? get currentEmail => null;
  @override
  Stream<String?> get uidChanges => changes.stream;
  @override
  Future<String> signInAnonymously() async {
    uid = 'guest';
    changes.add(uid);
    return uid!;
  }

  @override
  Future<String> signInWithGoogle() async {
    uid = 'account';
    changes.add(uid);
    return uid!;
  }

  @override
  Future<String> signInWithEmailPassword({
    required String email,
    required String password,
  }) => signInWithGoogle();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'signed-in account with no onboarding shows setup, not a sign-in prompt',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await LocalPrefsStore.init();
      final repository = LocalUserRepository(
        prefs: prefs,
        db: LocalDatabaseService(),
        crypto: JournalCryptoService(),
      );
      final service = _Auth('account');
      await repository.saveUserProfile(UserProfile.kosong('account'));
      await tester.pumpWidget(
        RiungApp(
          prefs: prefs,
          remoteConfig: RemoteConfigService(),
          authService: service,
          userRepository: repository,
          contentRepository: StubContentRepository(),
          walletFunctions: LocalWalletFunctionsService(
            prefs: prefs,
            userRepository: repository,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        find.text('Kamu sudah masuk. Yuk, lengkapi isian akunmu.'),
        findsOneWidget,
      );
      expect(find.text('Lanjut'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('welcome-next')));
      await tester.pumpAndSettle();
      expect(find.text('Kenali pola yang\nsering datang.'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('welcome-pages')),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Langkah kecil.\nPelan-pelan lebih tenang.'),
        findsOneWidget,
      );
      expect(find.text('Mulai kenalan (2 menit)'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Kenali pola yang\nsering datang.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('welcome-dot-0')));
      await tester.pumpAndSettle();
      expect(
        find.text('Ada monster di kepalamu.\nYuk, kenalan.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('welcome-dot-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('welcome-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('welcome-pages')), findsNothing);
      expect(
        tester.widget<QuestionStep>(find.byType(QuestionStep)).question.number,
        1,
      );
      await tester.tap(find.text('Kuliah'));
      await tester.pump();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<QuestionStep>(find.byType(QuestionStep)).question.number,
        2,
      );
      await tester.tap(find.byKey(const ValueKey('assessment-later')));
      await tester.pumpAndSettle();
      expect(find.byType(AssessmentPendingCard), findsOneWidget);
      final profile = await repository.getUserProfile('account');
      expect(profile.assessmentCompletedAt, isNull);
      expect(profile.assessmentScores, isEmpty);
      await tester.tap(find.byKey(const ValueKey('assessment-resume')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<QuestionStep>(find.byType(QuestionStep)).question.number,
        2,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<QuestionStep>(find.byType(QuestionStep))
            .controller
            .isSelected(1, 1),
        isTrue,
      );
      // Back on the first question returns home; later questions go back one.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AssessmentPendingCard), findsOneWidget);
      final app = tester.widget<RiungApp>(find.byType(RiungApp));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(AssessmentPendingCard), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome-pages')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await service.changes.close();
    },
  );
  for (final guestDone in [false, true]) {
    for (final accountDone in [false, true]) {
      for (final google in [false, true]) {
        test(
          'guest=$guestDone account=$accountDone google=$google loads account onboarding and survives restart',
          () async {
            SharedPreferences.setMockInitialValues({});
            ApiConfigStore.instance.raw = {'minAppVersion': '0.0.0'};
            final service = _Auth('guest');
            final mutations = <String>[];
            ApiState makeState() => ApiState(
              api: RiungApi(
                ApiClient(
                  baseUrl: 'https://example.test',
                  token: (_) async => 'token',
                  client: MockClient((request) async {
                    if (request.method != 'GET') mutations.add(request.method);
                    final done = service.uid == 'guest'
                        ? guestDone
                        : accountDone;
                    return http.Response(
                      jsonEncode({
                        'user': {
                          'onboardingDone': done,
                          'displayName': service.uid,
                        },
                      }),
                      200,
                    );
                  }),
                ),
              ),
              db: LocalDatabaseService(),
              currentUid: () => service.uid,
            );
            Future<AuthNotifier> makeAuth(ApiState state) async => AuthNotifier(
              service,
              apiState: state,
              userRepository: ApiUserRepository(
                state: state,
                prefs: await LocalPrefsStore.init(),
                db: LocalDatabaseService(),
                crypto: JournalCryptoService(),
              ),
            );
            final state = makeState();
            final auth = await makeAuth(state);
            expect(
              (await auth.ensureProfileLoaded()).onboardingDone,
              guestDone,
            );
            if (google) {
              await auth.masukGoogle();
            } else {
              await auth.masukEmailPassword(
                email: 'test@example.com',
                password: 'password',
              );
            }
            expect(auth.profile!.displayName, 'account');
            expect(auth.profile!.onboardingDone, accountDone);
            expect(
              mutations,
              isEmpty,
              reason:
                  'Signing in must never copy guest data to another account',
            );
            // Firebase can emit the current uid again during restoration/linking.
            service.changes.add('account');
            expect(auth.profile, isNotNull);
            auth.dispose();
            state.dispose();
            final restartedState = makeState();
            final restarted = await makeAuth(restartedState);
            expect(
              (await restarted.ensureProfileLoaded()).onboardingDone,
              accountDone,
            );
            expect(restarted.uid, 'account');
            restarted.dispose();
            restartedState.dispose();
            await service.changes.close();
          },
        );
      }
    }
  }

  test(
    'first install without a session creates a guest needing onboarding',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = _Auth(null);
      final repository = LocalUserRepository(
        prefs: await LocalPrefsStore.init(),
        db: LocalDatabaseService(),
        crypto: JournalCryptoService(),
      );
      final auth = AuthNotifier(service, userRepository: repository);
      expect((await auth.ensureProfileLoaded()).onboardingDone, isFalse);
      expect(auth.uid, 'guest');
      auth.dispose();
      await service.changes.close();
    },
  );
}
