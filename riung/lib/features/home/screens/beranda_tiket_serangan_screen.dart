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
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl + MediaQuery.paddingOf(context).bottom),
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
          const SizedBox(height: AppSpacing.xl),
          _TiketSeranganCard(tickets: tickets),
          const SizedBox(height: AppSpacing.xl),
          _CheckInSelesaiCard(
            sudahCheckin: sudahCheckin,
            onTap: sudahCheckin ? onLihatRiwayat : onCheckIn,
          ),
          const SizedBox(height: AppSpacing.xl),
          const HomeQuickActionGrid(),
          const SizedBox(height: AppSpacing.xl),
          const KarakterHomeCard(),
          const SizedBox(height: AppSpacing.xl),
          const LaporanHomeCard(),
        ],
      ),
    );
  }
}

/// Kartu tiket serangan bos (frame `Kartu Tiket Serangan` di
/// `Glass — Beranda`): gradien ungu malam→primer, cahaya lavender, Si
/// Hakim liar 3D di kanan, tombol pil putih "Serang".
class _TiketSeranganCard extends StatelessWidget {
  const _TiketSeranganCard({required this.tickets});

  final int tickets;

  Future<void> _serang(BuildContext context) async {
    final saboteurs = await AppScope.of(context).contentRepository.getSaboteurs();
    if (!context.mounted) return;
    final hakim = saboteurs.firstWhere((s) => s.id == 'hakim', orElse: () => saboteurs.first);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MinigameIntroScreen(saboteur: hakim)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.home;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.tiketAwal, AppColors.primer]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppGlass.shadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -60,
            width: 240,
            height: 240,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.tiketCahaya, AppColors.tiketCahaya.withValues(alpha: 0)]),
              ),
            ),
          ),
          const Positioned(
            right: -10,
            top: 4,
            child: RiungMonster(monsterId: 'hakim', state: MonsterVisualState.liar, size: 160, applyBossScale: false),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 150, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.diAtasTinta.withValues(alpha: 0.18),
                    border: Border.all(color: AppColors.diAtasTinta.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${t.bossBadge} · ×$tickets',
                    style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.diAtasTinta),
                  ),
                ),
                const SizedBox(height: 8),
                Text(t.ticketTitle(tickets), style: AppTextStyles.title.copyWith(fontSize: 18, height: 1.2, color: AppColors.diAtasTinta)),
                const SizedBox(height: 6),
                Text(t.ticketBody, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.diAtasTinta.withValues(alpha: 0.8))),
                const SizedBox(height: 6),
                Text(
                  t.ticketBreakdown(tickets, EconomyTiket.gratisPerHari, tickets - EconomyTiket.gratisPerHari),
                  style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.diAtasTinta.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _serang(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(color: AppColors.diAtasTinta, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.attack, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksUtama)),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.teksUtama),
                      ],
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
    final t = context.s.home;
    return RiungGlassCard(
      onTap: onTap,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      color: AppColors.permukaan,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sudahCheckin ? t.checkinDone : t.checkinSoon, style: AppTextStyles.title.copyWith(fontSize: 18, color: AppColors.teksUtama)),
                const SizedBox(height: 4),
                Text(
                  sudahCheckin ? t.checkinDoneMood(EconomyEarn.checkinHarian) : t.checkinPromptSub(EconomyEarn.checkinHarian),
                  style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder),
                ),
              ],
            ),
          ),
          const RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 84),
        ],
      ),
    );
  }
}
