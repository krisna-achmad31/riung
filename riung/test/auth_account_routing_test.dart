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
import 'package:riung/features/launch/screens/masuk_screen.dart';
import 'package:riung/features/jurnal/screens/jurnal_backup_screen.dart';
import 'package:riung/core/services/jurnal_pin_service.dart';

class _GuestJournalRepository extends LocalUserRepository {
  _GuestJournalRepository({
    required super.prefs,
    required super.db,
    required super.crypto,
  });

  @override
  Future<int> journalEntryCount(String uid) async => uid == 'guest' ? 2 : 0;
}

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
  testWidgets('backup labels stay visible and password requires four types', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> pumpDialog() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    SharedPreferences.setMockInitialValues({});
    await JurnalPinService().setPin('guest', '123456');
    final prefs = await LocalPrefsStore.init();
    final repository = _GuestJournalRepository(
      prefs: prefs,
      db: LocalDatabaseService(),
      crypto: JournalCryptoService(),
    );
    final service = _Auth('guest');
    addTearDown(service.changes.close);
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
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<void>(builder: (_) => const JurnalBackupScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat cadangan'));
    await pumpDialog();
    for (final digit in '123456'.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await pumpDialog();
    expect(find.text('Kata sandi cadangan'), findsOneWidget);
    expect(find.text('Ulangi kata sandi'), findsOneWidget);
    final fields = find.byType(TextField);
    final decorations = tester.widgetList<TextField>(fields).map((field) => field.decoration);
    expect(decorations.map((decoration) => decoration?.enabledBorder),
        everyElement(isA<OutlineInputBorder>()));
    expect(tester.getBottomLeft(find.text('Kata sandi cadangan')).dy,
        lessThan(tester.getTopLeft(fields.first).dy));
    expect(tester.getBottomLeft(find.text('Ulangi kata sandi')).dy,
        lessThan(tester.getTopLeft(fields.last).dy));
    await tester.tap(find.byTooltip('Tampilkan kata sandi').first);
    await tester.pump();
    expect(tester.widget<TextField>(fields.first).obscureText, isFalse);
    expect(tester.widget<TextField>(fields.last).obscureText, isTrue);
    await tester.tap(find.byTooltip('Sembunyikan kata sandi'));
    await tester.pump();
    expect(tester.widget<TextField>(fields.first).obscureText, isTrue);

    await tester.enterText(fields.first, 'Aa1!');
    await tester.enterText(fields.last, 'Aa1!');
    await tester.tap(find.text('Lanjut'));
    await pumpDialog();
    expect(find.text('Gunakan minimal 6 karakter.'), findsOneWidget);

    await tester.enterText(fields.first, 'Abc123');
    await tester.enterText(fields.last, 'Abc123');
    await tester.tap(find.text('Lanjut'));
    await pumpDialog();
    expect(find.text('Sertakan huruf kecil, huruf besar, angka, dan simbol.'), findsOneWidget);

    await tester.enterText(fields.first, 'Aa1!bc');
    await tester.tap(find.text('Lanjut'));
    await pumpDialog();
    expect(find.text('Kata sandinya berbeda.'), findsOneWidget);
    expect(find.text('Gunakan minimal 6 karakter.'), findsNothing);
  });
  testWidgets('guest can cancel or explicitly continue signing in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefsStore.init();
    final repository = _GuestJournalRepository(
      prefs: prefs,
      db: LocalDatabaseService(),
      crypto: JournalCryptoService(),
    );
    final service = _Auth('guest');
    addTearDown(service.changes.close);
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
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<void>(builder: (_) => const MasukScreen()));
    await tester.pumpAndSettle();

    final google = find.text('Lanjutkan dengan Google');
    await tester.scrollUntilVisible(
      google,
      120,
      scrollable: find.descendant(
        of: find.byType(MasukScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.tap(google);
    await tester.pumpAndSettle();
    expect(find.textContaining('Ada 2 entri jurnal tamu'), findsOneWidget);
    expect(find.text('Cadangkan dulu'), findsOneWidget);
    expect(service.uid, 'guest');

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(service.uid, 'guest');
    expect(find.byType(MasukScreen), findsOneWidget);

    await tester.tap(google);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut masuk'));
    await tester.pumpAndSettle();
    expect(service.uid, 'account');
  });
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
