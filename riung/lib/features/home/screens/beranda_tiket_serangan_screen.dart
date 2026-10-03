import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../checkin/screens/checkin_mood_screen.dart';
import '../../checkin/screens/checkin_riwayat_screen.dart';
import '../../minigame/screens/minigame_intro_screen.dart';
import '../../profil/screens/kalender_latihan_screen.dart';
import '../../kepribadian/widgets/karakter_home_card.dart';
import '../../laporan/widgets/laporan_home_card.dart';
import '../widgets/home_quick_action_grid.dart';
import '../widgets/home_top_bar.dart';
import 'koin_histori_screen.dart';

/// Varian Beranda saat user punya tiket serangan (>0) — menggantikan kartu
/// check-in dengan ajakan menyerang Si Hakim. Implement persis
/// `design/Home.dc.html` § Beranda — dengan tiket serangan.
///
/// Sebagai layar berdiri sendiri (dipakai kalau dibuka langsung, mis. dari
/// notifikasi); di alur normal, [BerandaScreen] menampilkan konten yang
/// sama ([BerandaTiketSeranganBody]) begitu [WalletNotifier.tickets] > 0.
class BerandaTiketSeranganScreen extends StatefulWidget {
  const BerandaTiketSeranganScreen({super.key});

  @override
  State<BerandaTiketSeranganScreen> createState() => _BerandaTiketSeranganScreenState();
}

class _BerandaTiketSeranganScreenState extends State<BerandaTiketSeranganScreen> {
  void _mulaiCheckIn() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckInMoodScreen()),
    );
  }

  void _bukaRiwayat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckInRiwayatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([scope.wallet, scope.streak, scope.auth]),
          builder: (context, _) {
            final profile = scope.auth.profile;
            if (profile == null || scope.wallet.loading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primer));
            }
            return BerandaTiketSeranganBody(
              userName: profile.displayName.isEmpty ? context.s.home.defaultUserName : profile.displayName,
              streak: scope.streak.current,
              coins: scope.wallet.coins,
              tickets: scope.wallet.tickets,
              sudahCheckin: scope.streak.sudahCheckinHariIni,
              onCheckIn: _mulaiCheckIn,
              onLihatRiwayat: _bukaRiwayat,
            );
          },
        ),
      ),
      bottomNavigationBar: RiungBottomNav(
        current: RiungNavTab.beranda,
        // Layar ini berdiri sendiri (di luar RootShellScreen), jadi tab lain
        // tidak punya isi di sini — ketuk tab mana pun kembali ke shell root.
        onTabSelected: (_) => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    );
  }
}

/// Konten (tanpa Scaffold/bottom nav) — dipakai baik oleh
/// [BerandaTiketSeranganScreen] maupun [BerandaScreen].
class BerandaTiketSeranganBody extends StatelessWidget {
  const BerandaTiketSeranganBody({
    super.key,
    required this.userName,
    required this.streak,
    required this.coins,
    required this.tickets,
    required this.sudahCheckin,
    required this.onCheckIn,
    required this.onLihatRiwayat,
  });

  final String userName;
  final int streak;
  final int coins;
  final int tickets;
  final bool sudahCheckin;
  final VoidCallback onCheckIn;
  final VoidCallback onLihatRiwayat;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeTopBar(
            userName: userName,
            streak: streak,
            coins: coins,
            onTapStreak: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KalenderLatihanScreen()),
            ),
            onTapCoins: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KoinHistoriScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _TiketSeranganCard(tickets: tickets),
          const SizedBox(height: AppSpacing.lg),
          _CheckInSelesaiCard(
            sudahCheckin: sudahCheckin,
            onTap: sudahCheckin ? onLihatRiwayat : onCheckIn,
          ),
          const SizedBox(height: AppSpacing.lg),
          const LaporanHomeCard(),
          const SizedBox(height: AppSpacing.lg),
          const KarakterHomeCard(),
          const SizedBox(height: AppSpacing.lg),
          const HomeQuickActionGrid(),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _TiketSeranganCard extends StatelessWidget {
  const _TiketSeranganCard({required this.tickets});

  final int tickets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.monsterHakim.withValues(alpha: 0.2), AppColors.kartu.withValues(alpha: 0.9)],
        ),
        border: Border.all(color: AppColors.monsterHakim, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 74,
            height: 78,
            child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.liar, size: 74, applyBossScale: false),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.s.home.ticketTitle(tickets), style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.s.home.ticketBody,
                  style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.latar.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number, size: 14, color: AppColors.sekunder),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          context.s.home.ticketBreakdown(tickets, EconomyTiket.gratisPerHari, tickets - EconomyTiket.gratisPerHari),
                          style: AppTextStyles.caption.copyWith(color: AppColors.sekunder, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () async {
                      final saboteurs = await AppScope.of(context).contentRepository.getSaboteurs();
                      if (!context.mounted) return;
                      final hakim = saboteurs.firstWhere((s) => s.id == 'hakim', orElse: () => saboteurs.first);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MinigameIntroScreen(saboteur: hakim)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.monsterHakim,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 14, color: AppColors.teksUtama),
                          const SizedBox(width: 6),
                          Text(context.s.home.attack, style: AppTextStyles.caption.copyWith(color: AppColors.teksUtama, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInSelesaiCard extends StatelessWidget {
  const _CheckInSelesaiCard({required this.sudahCheckin, required this.onTap});

  final bool sudahCheckin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.kartu, AppColors.primerGelap.withValues(alpha: 0.55)],
          ),
          border: Border.all(color: AppColors.garis),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sudahCheckin ? context.s.home.checkinDone : context.s.home.checkinSoon,
                    style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    sudahCheckin
                        ? context.s.home.checkinDoneMood(EconomyEarn.checkinHarian)
                        : context.s.home.checkinPromptSub(EconomyEarn.checkinHarian),
                    style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 64,
              height: 67,
              child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 64),
            ),
          ],
        ),
      ),
    );
  }
}
