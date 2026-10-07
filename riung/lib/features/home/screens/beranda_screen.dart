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
import '../../monster/screens/vault_screen.dart';
import '../../profil/screens/kalender_latihan_screen.dart';
import '../../kepribadian/widgets/karakter_home_card.dart';
import '../../laporan/widgets/laporan_home_card.dart';
import '../widgets/home_quick_action_grid.dart';
import '../widgets/kenali_home_card.dart';
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
      body: SafeArea(
        bottom: false,
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
    final dominantProgress = scope.monsterProgress.progressOf(dominant.id) ?? MonsterProgress.initial(dominant.id);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl + MediaQuery.paddingOf(context).bottom),
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
          const SizedBox(height: AppSpacing.xl),
          _CheckInCard(
            sudahCheckin: scope.streak.sudahCheckinHariIni,
            onCheckIn: _mulaiCheckIn,
            onLihatRiwayat: _bukaRiwayat,
          ),
          const SizedBox(height: AppSpacing.xl),
          const HomeQuickActionGrid(),
          const SizedBox(height: AppSpacing.xl),
          _MonsterMissionCard(
            monsterId: dominant.id,
            monsterName: dominant.nama,
            progress: dominantProgress,
            done: _missionsDone,
            onComplete: _completeMission,
            onTapMonster: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VaultScreen())),
          ),
          const SizedBox(height: AppSpacing.xl),
          _HakimActiveCard(
            progress: hakimProgress,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HakimDetailScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const KarakterHomeCard(),
          const SizedBox(height: AppSpacing.xl),
          const KenaliHomeCard(),
          const LaporanHomeCard(),
          const SizedBox(height: AppSpacing.xl),
          _FocusModeEntryCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FocusModeEntryScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TahukahKamuCard(
            text: context.s.home.tipText,
            source: context.s.home.tipSource,
          ),
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

/// Kartu check-in (frame `Kartu Check-in`): kaca terang, judul besar,
/// tombol tinta, Si Kabut 3D besar di kanan.
class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.sudahCheckin,
    required this.onCheckIn,
    required this.onLihatRiwayat,
  });

  final bool sudahCheckin;
  final VoidCallback onCheckIn;
  final VoidCallback onLihatRiwayat;

  @override
  Widget build(BuildContext context) {
    final t = context.s.home;
    return GestureDetector(
      onTap: sudahCheckin ? onLihatRiwayat : onCheckIn,
      child: Container(
        constraints: const BoxConstraints(minHeight: 196),
        padding: const EdgeInsets.all(22),
        decoration: AppGlass.card(radius: 32, color: AppColors.permukaan),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              right: -26,
              top: -16,
              child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 170),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sudahCheckin ? t.checkinDone : t.checkinPrompt,
                    style: AppTextStyles.title.copyWith(fontSize: 22, height: 1.15, color: AppColors.teksUtama),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sudahCheckin ? t.checkinDoneSub(EconomyEarn.checkinHarian) : t.checkinPromptSub(EconomyEarn.checkinHarian),
                    style: AppTextStyles.caption.copyWith(fontSize: 13, color: AppColors.teksSekunder),
                  ),
                  if (!sudahCheckin) ...[
                    const SizedBox(height: 28),
                    _InkPill(label: t.checkinStart, onTap: onCheckIn),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pil tinta kecil 46dp (CTA di dalam kartu).
class _InkPill extends StatelessWidget {
  const _InkPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(color: AppColors.tinta, borderRadius: BorderRadius.circular(AppRadius.pill), boxShadow: AppGlass.inkShadow),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.buttonLabel.copyWith(fontSize: 15, color: AppColors.diAtasTinta)),
      ),
    );
  }
}

/// Bilah progres pil dengan isi gradien.
class _GradientBar extends StatelessWidget {
  const _GradientBar({required this.value, required this.colors});

  final double value;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(4)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        heightFactor: 1,
        widthFactor: value.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}

/// Kartu Si Hakim (bos) — kaca, art 3D, progres lavender.
class _HakimActiveCard extends StatelessWidget {
  const _HakimActiveCard({required this.progress, required this.onTap});

  final MonsterProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTamed = progress.state == MonsterState.tamed;
    final t = context.s.home;
    return RiungGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [AppColors.sekunderLembut, AppColors.sekunderLembut.withValues(alpha: 0)]),
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: RiungMonster(
              monsterId: 'hakim',
              state: isTamed ? MonsterVisualState.jinak : MonsterVisualState.liar,
              size: 92,
              applyBossScale: false,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(context.s.common.monsterName('hakim'), style: AppTextStyles.title.copyWith(fontSize: 18, color: AppColors.teksUtama))),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.sekunderLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(t.bossBadge, style: AppTextStyles.caption.copyWith(color: AppColors.sekunder, fontWeight: FontWeight.w700, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(isTamed ? t.hakimTamed : t.hakimWild, style: AppTextStyles.caption.copyWith(color: AppColors.teksSekunder, fontSize: 12)),
                const SizedBox(height: 10),
                _GradientBar(value: progress.progress / 100, colors: const [AppColors.kabutLavender, AppColors.sekunder]),
                const SizedBox(height: 6),
                Text(t.progressToTamed(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu monster yang sedang dijinakkan + misi harian (frame `Kartu Monster`).
class _MonsterMissionCard extends StatelessWidget {
  const _MonsterMissionCard({
    required this.monsterId,
    required this.monsterName,
    required this.progress,
    required this.done,
    required this.onComplete,
    required this.onTapMonster,
  });

  final String monsterId;
  final String monsterName;
  final MonsterProgress progress;
  final Set<int> done;
  final ValueChanged<int> onComplete;
  final VoidCallback onTapMonster;

  @override
  Widget build(BuildContext context) {
    final t = context.s.home;
    final missions = t.missions;
    final tamed = progress.state == MonsterState.tamed;
    return RiungGlassCard(
      padding: const EdgeInsets.all(20),
      radius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTapMonster,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.aksenHangatLembut, AppColors.aksenHangatLembut.withValues(alpha: 0)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: RiungMonster(
                    monsterId: monsterId,
                    state: tamed ? MonsterVisualState.jinak : MonsterVisualState.liar,
                    size: 104,
                    applyBossScale: false,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.s.kepribadian.homeMonsterLabel.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.teksRedup),
                      ),
                      const SizedBox(height: 4),
                      Text(monsterName, style: AppTextStyles.title.copyWith(fontSize: 22, color: AppColors.teksUtama)),
                      const SizedBox(height: 8),
                      _GradientBar(value: progress.progress / 100, colors: const [AppColors.emas, AppColors.aksenHangat]),
                      const SizedBox(height: 6),
                      Text(t.progressToTamed(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.garis, height: 1),
          ),
          Text(t.missionTitle(monsterName), style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
          const SizedBox(height: 6),
          for (var i = 0; i < missions.length; i++)
            _MissionRow(text: missions[i], done: done.contains(i), onTap: () => onComplete(i)),
          const SizedBox(height: 6),
          Text(t.missionNote, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksRedup)),
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
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: done ? AppColors.primer : AppColors.permukaan,
                  border: Border.all(color: done ? AppColors.primer : AppColors.teksRedup, width: 1.5),
                  shape: BoxShape.circle,
                ),
                child: done ? const Icon(Icons.check_rounded, size: 14, color: AppColors.diAtasTinta) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 13,
                    height: 1.3,
                    color: done ? AppColors.teksRedup : AppColors.teksUtama,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.aksenHangatLembut, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(
                  '+${EconomyEarn.misiHarian}',
                  style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.aksenHangatGelap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu Mode Fokus (frame `Kartu Fokus`): ikon fokus 3D + teks + chevron.
class _FocusModeEntryCard extends StatelessWidget {
  const _FocusModeEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      onTap: onTap,
      radius: 28,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const RiungIcon3D(RiungIcon.fokus, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.s.home.focusTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 16, color: AppColors.teksUtama)),
                const SizedBox(height: 2),
                Text(context.s.home.focusSub(EconomySpend.fokus25Menit), style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, color: AppColors.teksSekunder)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.teksRedup),
        ],
      ),
    );
  }
}
