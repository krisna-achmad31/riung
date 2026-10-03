import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/economy.dart';
import '../../models/coin_transaction.dart';
import '../../models/monster_progress.dart';
import '../../models/wallet.dart';
import '../wallet_functions_service.dart';

/// Implementasi [WalletFunctionsService] lewat Firestore transaction —
/// dipakai sejak M5.
///
/// PENTING (Spark plan, tanpa Cloud Functions): CLAUDE.md aturan #5 aslinya
/// mensyaratkan wallet "HANYA dimutasi Cloud Functions". Tanpa Cloud
/// Functions, tidak ada cara bagi backend memproses permintaan mutasi
/// secara mandiri — client tetap yang menghitung saldo baru. Sebagai
/// gantinya, `firestore.rules` memvalidasi setiap perubahan `wallet.coins`
/// harus berupa salah satu nilai earn/spend yang sah (lihat daftar di
/// `firestore.rules`), jadi client tidak bisa menulis saldo sembarangan.
/// Ini BUKAN jaminan keamanan setara Cloud Functions — client yang
/// di-root/dimodifikasi tetap bisa memutar ulang (replay) permintaan yang
/// "bentuknya sah". Setiap mutasi juga dicatat ke sub-koleksi
/// `coinRequests` sebagai jejak audit untuk migrasi ke Cloud Functions
/// (Blaze plan) nanti. Detail & rekomendasi upgrade ada di
/// `docs/setup-firebase.md`.
class FirestoreWalletFunctionsService implements WalletFunctionsService {
  FirestoreWalletFunctionsService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _firestore.collection('users').doc(uid);

  Wallet _walletFrom(Map<String, dynamic>? data) {
    final raw = (data?['wallet'] as Map?)?.cast<String, dynamic>();
    return raw == null ? Wallet.zero() : Wallet.fromMap(raw);
  }

  void _writeAudit(Transaction tx, DocumentReference<Map<String, dynamic>> userRef, {
    required String type,
    required int amount,
    required String reason,
    required int balanceAfter,
  }) {
    final auditRef = userRef.collection('coinRequests').doc();
    tx.set(auditRef, {
      'type': type,
      'amount': amount,
      'reason': reason,
      'balanceAfter': balanceAfter,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Wallet> earnCoins({required String uid, required int amount, required String reason}) async {
    final ref = _userDoc(uid);
    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = _walletFrom(snap.data());
      final updated = current.copyWith(
        coins: current.coins + amount,
        lifetimeEarned: current.lifetimeEarned + amount,
      );
      tx.set(ref, {'wallet': updated.toMap()}, SetOptions(merge: true));
      _writeAudit(tx, ref, type: 'earn', amount: amount, reason: reason, balanceAfter: updated.coins);
      return updated;
    });
  }

  @override
  Future<Wallet> spendCoins({required String uid, required int amount, required String reason}) async {
    final ref = _userDoc(uid);
    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = _walletFrom(snap.data());
      if (current.coins < amount) {
        throw InsufficientCoinsException(current.coins, amount);
      }
      final updated = current.copyWith(
        coins: current.coins - amount,
        lifetimeSpent: current.lifetimeSpent + amount,
      );
      tx.set(ref, {'wallet': updated.toMap()}, SetOptions(merge: true));
      _writeAudit(tx, ref, type: 'spend', amount: amount, reason: reason, balanceAfter: updated.coins);
      return updated;
    });
  }

  @override
  Future<Wallet> dailyCheckin({required String uid}) {
    return earnCoins(uid: uid, amount: EconomyEarn.checkinHarian, reason: 'daily_checkin');
  }

  @override
  Future<MonsterProgress> tameProgress({
    required String uid,
    required String saboteurId,
    required int delta,
  }) async {
    final ref = _userDoc(uid);
    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      final monstersRaw = (data?['monsters'] as Map?)?.cast<String, dynamic>() ?? const {};
      final currentRaw = (monstersRaw[saboteurId] as Map?)?.cast<String, dynamic>();
      final current = currentRaw != null
          ? MonsterProgress.fromMap(saboteurId, currentRaw)
          : MonsterProgress.initial(saboteurId);
      final nextProgress = (current.progress + delta).clamp(0, 100);
      final justTamed = nextProgress >= 100 && current.state != MonsterState.tamed;
      final updated = current.copyWith(
        progress: nextProgress,
        state: nextProgress >= 100
            ? MonsterState.tamed
            : (nextProgress > 0 ? MonsterState.taming : MonsterState.wild),
        tamedAt: justTamed ? DateTime.now() : current.tamedAt,
      );
      final updatedMonsters = {...monstersRaw, saboteurId: updated.toMap()};

      final payload = <String, dynamic>{'monsters': updatedMonsters};
      if (justTamed) {
        final currentWallet = _walletFrom(data);
        final updatedWallet = currentWallet.copyWith(
          coins: currentWallet.coins + EconomyEarn.monsterJinak,
          lifetimeEarned: currentWallet.lifetimeEarned + EconomyEarn.monsterJinak,
        );
        payload['wallet'] = updatedWallet.toMap();
        tx.set(ref, payload, SetOptions(merge: true));
        _writeAudit(
          tx,
          ref,
          type: 'earn',
          amount: EconomyEarn.monsterJinak,
          reason: 'monster_tamed:$saboteurId',
          balanceAfter: updatedWallet.coins,
        );
      } else {
        tx.set(ref, payload, SetOptions(merge: true));
      }
      return updated;
    });
  }

  @override
  Future<List<CoinTransaction>> getTransactions({required String uid, int limit = 50}) async {
    final snap = await _userDoc(uid)
        .collection('coinRequests')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return [for (final doc in snap.docs) CoinTransaction.fromMap(doc.id, doc.data())];
  }
}
