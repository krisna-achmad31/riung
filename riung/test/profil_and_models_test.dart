import 'package:flutter_test/flutter_test.dart';

import 'package:riung/core/models/coin_transaction.dart';
import 'package:riung/core/models/monster_progress.dart';
import 'package:riung/core/models/user_profile.dart';
import 'package:riung/core/models/wallet.dart';
import 'package:riung/features/profil/logic/avatar_catalog.dart';

void main() {
  group('AvatarCatalog', () {
    test('6 avatar terdaftar dengan monster yang valid', () {
      expect(AvatarCatalog.all.length, 6);
      const expectedMonsters = ['kabut', 'waswas', 'cermin', 'meronta', 'sempurna', 'mengelak'];
      for (var i = 0; i < 6; i++) {
        final av = AvatarCatalog.all[i];
        expect(av.id, 'av${i + 1}');
        expect(av.monsterId, expectedMonsters[i]);
        expect(av.colors.length, 2);
      }
    });

    test('byId menemukan avatar atau fallback ke av1', () {
      final av3 = AvatarCatalog.byId('av3');
      expect(av3.id, 'av3');
      expect(av3.monsterId, 'cermin');

      final fallback = AvatarCatalog.byId('unknown_id');
      expect(fallback.id, 'av1');
    });
  });

  group('UserProfile Model', () {
    test('kosong() membuat profil awal yang valid', () {
      final p = UserProfile.kosong('u_test');
      expect(p.uid, 'u_test');
      expect(p.displayName, isEmpty);
      expect(p.avatarId, 'av1');
      expect(p.locale, 'id');
      expect(p.onboardingDone, isFalse);
      expect(p.premiumActive, isFalse);
      expect(p.streakCurrent, 0);
      expect(p.dominantSaboteurs, isEmpty);
      expect(p.assessmentScores, isEmpty);
    });

    test('fromMap dan toMap bolak-balik dengan field terisi', () {
      final now = DateTime(2026, 10, 12, 10, 0);
      final renews = now.add(const Duration(days: 30));
      final p = UserProfile(
        uid: 'u_user_99',
        displayName: 'Budi Santoso',
        avatarId: 'av2',
        locale: 'id',
        persona: 'pekerja',
        createdAt: now,
        onboardingDone: true,
        premiumActive: true,
        premiumPlan: 'premium_monthly',
        premiumRenewsAt: renews,
        streakCurrent: 5,
        streakLongest: 10,
        lastCheckinDate: now,
        dominantSaboteurs: const ['waswas', 'hakim'],
        assessmentScores: const {'waswas': 75, 'hakim': 60},
        assessmentCompletedAt: now,
      );

      final map = p.toMap();
      final restored = UserProfile.fromMap('u_user_99', map);

      expect(restored.uid, 'u_user_99');
      expect(restored.displayName, 'Budi Santoso');
      expect(restored.avatarId, 'av2');
      expect(restored.locale, 'id');
      expect(restored.persona, 'pekerja');
      expect(restored.onboardingDone, isTrue);
      expect(restored.premiumActive, isTrue);
      expect(restored.premiumPlan, 'premium_monthly');
      expect(restored.streakCurrent, 5);
      expect(restored.streakLongest, 10);
      expect(restored.dominantSaboteurs, ['waswas', 'hakim']);
      expect(restored.assessmentScores['waswas'], 75);
    });

    test('Status dan masa berlaku Premium (premiumStatus & premiumNow)', () {
      final now = DateTime(2026, 10, 12);

      // Non-premium
      final freeUser = UserProfile.kosong('u_free');
      expect(freeUser.premiumNow, isFalse);
      expect(freeUser.premiumStatus(now), PremiumStatus.none);

      // Premium aktif jauh di masa depan
      final activeUser = freeUser.copyWith(
        premiumActive: true,
        premiumPlan: 'premium_yearly',
        premiumRenewsAt: now.add(const Duration(days: 200)),
      );
      expect(activeUser.premiumNow, isTrue);
      expect(activeUser.isAnnual, isTrue);
      expect(activeUser.premiumStatus(now), PremiumStatus.active);

      // Premium kedaluwarsa setelah grace period (graceHari = 3)
      final expiredUser = activeUser.copyWith(
        premiumRenewsAt: now.subtract(const Duration(days: 4)),
      );
      expect(expiredUser.premiumStatus(now), PremiumStatus.expired);
      expect(expiredUser.premiumNow, isFalse);
    });
  });

  group('Wallet & CoinTransaction Models', () {
    test('Wallet zero, fromMap, toMap, copyWith', () {
      final zero = Wallet.zero();
      expect(zero.coins, 0);
      expect(zero.lifetimeEarned, 0);
      expect(zero.lifetimeSpent, 0);

      final w = const Wallet(coins: 150, lifetimeEarned: 300, lifetimeSpent: 150);
      final map = w.toMap();
      expect(map[Wallet.fCoins], 150);
      expect(map[Wallet.fLifetimeEarned], 300);
      expect(map[Wallet.fLifetimeSpent], 150);

      final parsed = Wallet.fromMap(map);
      expect(parsed.coins, w.coins);
      expect(parsed.lifetimeEarned, w.lifetimeEarned);
      expect(parsed.lifetimeSpent, w.lifetimeSpent);

      final modified = w.copyWith(coins: 200);
      expect(modified.coins, 200);
      expect(modified.lifetimeEarned, 300);
    });

    test('CoinTransaction fromMap dan helper isEarn', () {
      final now = DateTime(2026, 10, 12, 12, 0);
      final tx = CoinTransaction.fromMap('tx_1', {
        CoinTransaction.fType: 'earn',
        CoinTransaction.fAmount: 5,
        CoinTransaction.fReason: 'checkin',
        CoinTransaction.fBalanceAfter: 15,
        CoinTransaction.fCreatedAt: now.toIso8601String(),
      });

      expect(tx.id, 'tx_1');
      expect(tx.type, 'earn');
      expect(tx.amount, 5);
      expect(tx.reason, 'checkin');
      expect(tx.balanceAfter, 15);
      expect(tx.isEarn, isTrue);

      final spendTx = CoinTransaction.fromMap('tx_2', {
        CoinTransaction.fType: 'spend',
        CoinTransaction.fAmount: 25,
      });
      expect(spendTx.isEarn, isFalse);
    });
  });

  group('MonsterProgress Model', () {
    test('initial, fromMap, toMap, clamp progress 0..100', () {
      final initial = MonsterProgress.initial('waswas');
      expect(initial.saboteurId, 'waswas');
      expect(initial.state, MonsterState.wild);
      expect(initial.progress, 0);
      expect(initial.tamedAt, isNull);

      final progressOver = MonsterProgress.fromMap('waswas', {
        MonsterProgress.fState: 'tamed',
        MonsterProgress.fProgress: 150, // harus dijepit ke 100
        MonsterProgress.fTamedAt: DateTime(2026, 10, 12).toIso8601String(),
      });
      expect(progressOver.progress, 100);
      expect(progressOver.state, MonsterState.tamed);
      expect(progressOver.tamedAt, isNotNull);

      final map = progressOver.toMap();
      expect(map[MonsterProgress.fState], 'tamed');
      expect(map[MonsterProgress.fProgress], 100);
    });
  });
}
