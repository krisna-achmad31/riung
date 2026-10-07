import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riung/core/models/personality_result.dart';
import 'package:riung/core/services/services.dart';

/// Menjaga "Unduh semua dataku" tetap lengkap: setiap kunci penyimpanan
/// lokal harus tercatat sebagai diekspor atau sengaja dikecualikan. Kunci
/// baru tanpa keputusan → tes ini gagal dan mengingatkan.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Kunci yang isinya sudah ada di ekspor (lihat DataExportBuilder).
  const exported = {
    'riung_uid', // dipakai sebagai kunci pencarian, bukan data pribadi tambahan
    'riung_coins', 'riung_lifetime_earned', 'riung_lifetime_spent',
    'riung_streak_current', 'riung_streak_longest',
    'riung_monster_progress_json', 'riung_user_profile_json',
    'riung_favorite_affirmation_ids', 'riung_custom_affirmations_json',
    'riung_ticket_balance', 'riung_owned_cosmetics', 'riung_prepaid_focus_sessions',
    'riung_streak_shield_balance', 'riung_frozen_apps_json', 'riung_appbeku_lock_enabled',
    'riung_notif_settings_json', 'riung_biometric_unlock_enabled',
    'riung_betterme_completed', 'riung_betterme_reflections_json',
    'riung_language_code', 'riung_sleep_sync_enabled', 'riung_afirmasi_reminder_time', 'riung_sleep_reminder_json',
    'riung_personality_results_json', 'riung_personality_card_style', 'riung_personality_accessories_json',
    'riung_monster_cosmetics_json',
  };

  // Sengaja tidak diekspor: penghitung harian / status internal, bukan data pribadi.
  const excluded = {
    'riung_onboarding_done',
    'riung_last_checkin_date', // turunan dari riwayat check-in
    'riung_tickets_earned_today', 'riung_fights_today', 'riung_ticket_reset_date',
    'riung_appbeku_daily_json', 'riung_free_focus_date', 'riung_free_focus_used', 'riung_premium_daily_claim_date',
    'riung_purchased_coins_reserve', 'riung_missions_json', 'riung_waswas_stage_json',
  };

  test('semua kunci penyimpanan lokal diputuskan: diekspor atau dikecualikan', () {
    final source = File('lib/core/services/local_prefs_store.dart').readAsStringSync();
    final keys = RegExp(r"static const _k\w+ = '(riung_\w+)'").allMatches(source).map((m) => m.group(1)!).toSet();
    expect(keys, isNotEmpty);
    final undecided = keys.difference({...exported, ...excluded});
    expect(undecided, isEmpty, reason: 'Kunci baru belum masuk DataExportBuilder / daftar pengecualian: $undecided');
    final stale = {...exported, ...excluded}.difference(keys);
    expect(stale, isEmpty, reason: 'Daftar tes menyebut kunci yang sudah tidak ada: $stale');
  });

  test('bagian kepribadian memuat hasil, aksesori, dan gaya kartu per tes', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefsStore.init();
    await prefs.setPersonalityResult(PersonalityResult(
      test: PersonalityTest.jung,
      code: 'INFP',
      scores: const {'I': 70, 'E': 30},
      completedAt: DateTime(2026, 1, 2),
    ));
    await prefs.setPersonalityAccessories({'jung': {'head': 'beanie'}});
    await prefs.setPersonalityCardStyle(PersonalityTest.jung, 'aurora');

    final section = DataExportBuilder(userRepository: _NoRepo(), prefs: prefs).personalitySection();
    expect((section['jung'] as Map)['hasil'], isNotNull);
    expect(((section['jung'] as Map)['hasil'] as Map)['code'], 'INFP');
    expect((section['jung'] as Map)['aksesoriDipakai'], {'head': 'beanie'});
    expect((section['jung'] as Map)['gayaKartu'], 'aurora');
    expect((section['temperament'] as Map)['hasil'], isNull); // belum diisi
    expect(section.keys, PersonalityTest.values.map((t) => t.name));
  });
}

class _NoRepo implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
