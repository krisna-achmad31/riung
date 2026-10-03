import 'package:flutter/widgets.dart';

import '../services/billing_service.dart';
import '../services/content_repository.dart';
import '../services/firebase/analytics_service.dart';
import '../services/firebase/remote_config_service.dart';
import '../services/jurnal_pin_service.dart';
import '../services/local_prefs_store.dart';
import '../services/user_repository.dart';
import 'appbeku_notifier.dart';
import 'auth_notifier.dart';
import 'language_notifier.dart';
import 'monster_progress_notifier.dart';
import 'session_notifier.dart';
import 'streak_notifier.dart';
import 'wallet_notifier.dart';

/// InheritedWidget sederhana yang membagikan ke-7 notifier global lintas
/// layar (CLAUDE.md §State management — [AppBekuNotifier] ditambah di M6,
/// lihat justifikasi di file itu), plus service stateless yang dipakai
/// lebih dari satu fitur ([ContentRepository], [UserRepository],
/// [JurnalPinService]). AppScope sendiri tidak pernah rebuild anak-anaknya
/// — widget yang butuh bereaksi terhadap perubahan memakai
/// `ListenableBuilder(listenable: AppScope.of(context).wallet, ...)`
/// sedekat mungkin ke bagian yang berubah.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.auth,
    required this.wallet,
    required this.streak,
    required this.monsterProgress,
    required this.session,
    required this.appBeku,
    required this.language,
    required this.contentRepository,
    required this.userRepository,
    required this.pinService,
    required this.prefs,
    required this.remoteConfig,
    required this.billing,
    required this.analytics,
    required super.child,
  });

  final AuthNotifier auth;
  final WalletNotifier wallet;
  final StreakNotifier streak;
  final MonsterProgressNotifier monsterProgress;
  final SessionNotifier session;
  final AppBekuNotifier appBeku;
  final LanguageNotifier language;
  final ContentRepository contentRepository;
  final UserRepository userRepository;
  final JurnalPinService pinService;
  final LocalPrefsStore prefs;
  final RemoteConfigService remoteConfig;
  final BillingService billing;
  final AnalyticsService analytics;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
