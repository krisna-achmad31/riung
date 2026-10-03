import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../checkin/screens/checkin_mood_screen.dart';
import '../../checkin/screens/checkin_riwayat_screen.dart';
import '../../focus/screens/focus_mode_entry_screen.dart';
import '../../monster/screens/hakim_detail_screen.dart';
import '../../profil/screens/kalender_latihan_screen.dart';
import '../../kepribadian/widgets/karakter_home_card.dart';
import '../../laporan/widgets/laporan_home_card.dart';
import '../widgets/home_quick_action_grid.dart';
import '../widgets/home_top_bar.dart';
import 'beranda_tiket_serangan_screen.dart';
import 'koin_histori_screen.dart';

/// Dashboard utama. Implement persis `design/Home.dc.html` § Beranda.
/// Kartu hero berganti ke [BerandaTiketSeranganScreen]-style saat user
/// punya tiket serangan (>0) — bukan layar terpisah yang harus dinavigasi
/// manual, tapi state hidup dari [WalletNotifier.tickets].
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  List<Saboteur>? _saboteurs;
  Object? _loadError;
  Set<int> _missionsDone = {};

  @override
  void initState() {
    super.initState();
    _loadSaboteurs();
    _loadMissions();
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Misi yang sudah dicentang hanya berlaku untuk hari ini — tanggal
  /// tersimpan beda dari hari ini berarti daftar mulai kosong lagi.
  void _loadMissions() {
    final saved = AppScope.of(context).prefs.missionsJson;
    if (saved['date'] != _todayKey()) return;
    final done = (saved['done'] as List?)?.whereType<int>().toSet() ?? <int>{};
    _missionsDone = done;
  }

  /// Centang satu misi: hanya bisa SEKALI per misi per hari (tidak bisa
  /// dibatalkan lalu dicentang lagi), supaya koinnya tidak bisa diulang-ulang.
  Future<void> _completeMission(int index) async {
    if (_missionsDone.contains(index)) return;
    final scope = AppScope.of(context);
    final done = {..._missionsDone, index};
    setState(() => _missionsDone = done);
    await scope.prefs.setMissionsJson({'date': _todayKey(), 'done': done.toList()});
    await scope.wallet.earn(amount: EconomyEarn.misiHarian, reason: 'misi_harian:${_todayKey()}:$index');
  }

  Future<void> _loadSaboteurs() async {
    try {
      final list = await AppScope.of(context).contentRepository.getSaboteurs();
      if (!mounted) return;
      setState(() => _saboteurs = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

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

  void _bukaKalender() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KalenderLatihanScreen()),
    );
  }

  void _bukaHistoriKoin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KoinHistoriScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([scope.wallet, scope.streak, scope.auth, scope.monsterProgress]),
          builder: (context, _) => _buildBody(context, scope),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppScope scope) {
    if (_loadError != null) {
      return _BerandaError(onRetry: () {
        setState(() => _loadError = null);
        _loadSaboteurs();
      });
    }
    final profile = scope.auth.profile;
    final saboteurs = _saboteurs;
    if (profile == null || saboteurs == null || scope.wallet.loading) {
      return const _BerandaLoading();
    }

    if (scope.wallet.tickets > 0) {
      return BerandaTiketSeranganBody(
        userName: profile.displayName.isEmpty ? context.s.home.defaultUserName : profile.displayName,
        streak: scope.streak.current,
        coins: scope.wallet.coins,
        tickets: scope.wallet.tickets,
        sudahCheckin: scope.streak.sudahCheckinHariIni,
        onCheckIn: _mulaiCheckIn,
        onLihatRiwayat: _bukaRiwayat,
      );
    }

    final hakimProgress = scope.monsterProgress.progressOf('hakim') ?? MonsterProgress.initial('hakim');
    final dominantId = profile.dominantSaboteurs.isNotEmpty ? profile.dominantSaboteurs.first : 'waswas';
    final dominant = saboteurs.firstWhere(
      (s) => s.id == dominantId,
      orElse: () => saboteurs.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeTopBar(
            userName: profile.displayName.isEmpty ? context.s.home.defaultUserName : profile.displayName,
            streak: scope.streak.current,
            coins: scope.wallet.coins,
            onTapStreak: _bukaKalender,
            onTapCoins: _bukaHistoriKoin,
          ),
          const SizedBox(height: AppSpacing.lg),
          _CheckInCard(
            sudahCheckin: scope.streak.sudahCheckinHariIni,
            onCheckIn: _mulaiCheckIn,
            onLihatRiwayat: _bukaRiwayat,
          ),
          const SizedBox(height: AppSpacing.lg),
          const LaporanHomeCard(),
          const SizedBox(height: AppSpacing.lg),
          const KarakterHomeCard(),
          const SizedBox(height: AppSpacing.lg),
          _HakimActiveCard(
            progress: hakimProgress,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HakimDetailScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DailyMissionCard(
            monsterName: dominant.nama,
            done: _missionsDone,
            onComplete: _completeMission,
          ),
          const SizedBox(height: AppSpacing.lg),
          const HomeQuickActionGrid(),
          const SizedBox(height: AppSpacing.lg),
          _FocusModeEntryCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FocusModeEntryScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TahukahKamuCard(
            text: context.s.home.tipText,
            source: context.s.home.tipSource,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _BerandaLoading extends StatelessWidget {
  const _BerandaLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: AppColors.primer));
  }
}

class _BerandaError extends StatelessWidget {
  const _BerandaError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.teksRedup),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.s.home.loadError,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.md),
            RiungButton(label: context.s.common.cobaLagi, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({required this.sudahCheckin, required this.onCheckIn, required this.onLihatRiwayat});

  final bool sudahCheckin;
  final VoidCallback onCheckIn;
  final VoidCallback onLihatRiwayat;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sudahCheckin ? onLihatRiwayat : onCheckIn,
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                  sudahCheckin ? context.s.home.checkinDone : context.s.home.checkinPrompt,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  sudahCheckin
                      ? context.s.home.checkinDoneSub(EconomyEarn.checkinHarian)
                      : context.s.home.checkinPromptSub(EconomyEarn.checkinHarian),
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                ),
                if (!sudahCheckin) ...[
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: onCheckIn,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.primer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        context.s.home.checkinStart,
                        style: AppTextStyles.chipLabel.copyWith(color: AppColors.latar, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(
            width: 84,
            height: 88,
            child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 84),
          ),
        ],
      ),
      ),
    );
  }
}

class _HakimActiveCard extends StatelessWidget {
  const _HakimActiveCard({required this.progress, required this.onTap});

  final MonsterProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTamed = progress.state == MonsterState.tamed;
    final t = context.s.home;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            height: 78,
            child: RiungMonster(
              monsterId: 'hakim',
              state: isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar,
              size: 74,
              applyBossScale: false,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(context.s.common.monsterName('hakim'), style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.monsterHakim),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        t.bossBadge,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.monsterHakim,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isTamed ? t.hakimTamed : t.hakimWild,
                  style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: progress.progress / 100,
                    minHeight: 7,
                    backgroundColor: AppColors.latar,
                    valueColor: const AlwaysStoppedAnimation(AppColors.monsterHakim),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(t.progressToTamed(progress.progress), style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.teksRedup),
        ],
      ),
      ),
    );
  }
}

class _DailyMissionCard extends StatelessWidget {
  const _DailyMissionCard({required this.monsterName, required this.done, required this.onComplete});

  final String monsterName;
  final Set<int> done;
  final ValueChanged<int> onComplete;

  @override
  Widget build(BuildContext context) {
    final t = context.s.home;
    final missions = t.missions;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.missionTitle(monsterName),
                  style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.monsterWaswas.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${done.length}/${missions.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.monsterWaswas,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < missions.length; i++)
            _MissionRow(text: missions[i], done: done.contains(i), onTap: () => onComplete(i)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.missionNote,
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.text, required this.done, required this.onTap});

  final String text;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: done,
      label: text,
      child: GestureDetector(
        onTap: done ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: done ? AppColors.sukses : Colors.transparent,
                  border: Border.all(color: done ? AppColors.sukses : AppColors.teksRedup, width: 1.5),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: done ? const Icon(Icons.check, size: 14, color: AppColors.latar) : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.caption.copyWith(
                    color: done ? AppColors.teksRedup : AppColors.teksSekunder,
                    fontSize: 12,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Icon(Icons.monetization_on, size: 12, color: done ? AppColors.teksRedup : AppColors.aksenHangat),
              const SizedBox(width: 3),
              Text(
                '+${EconomyEarn.misiHarian}',
                style: AppTextStyles.caption.copyWith(
                  color: done ? AppColors.teksRedup : AppColors.aksenHangat,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusModeEntryCard extends StatelessWidget {
  const _FocusModeEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.sekunder.withValues(alpha: 0.14), AppColors.primer.withValues(alpha: 0.1)],
          ),
          border: Border.all(color: AppColors.sekunder.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.sekunder.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.center_focus_strong, size: 23, color: AppColors.sekunder),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.s.home.focusTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama)),
                  Text(
                    context.s.home.focusSub(EconomySpend.fokus25Menit),
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.sekunder),
          ],
        ),
      ),
    );
  }
}
