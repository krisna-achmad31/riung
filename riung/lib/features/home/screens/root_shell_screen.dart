import 'package:flutter/material.dart';

import '../../../core/services/services.dart';
import '../../../core/state/state.dart';
import '../../../core/widgets/widgets.dart';
import '../../appbeku/screens/appbeku_interstitial_screen.dart';
import '../../appbeku/screens/appbeku_permission_screen.dart';
import '../../focus/screens/focus_mode_entry_screen.dart';
import '../../monster/screens/vault_screen.dart';
import '../../profil/screens/profil_screen.dart';
import 'beranda_screen.dart';
import 'jelajah_screen.dart';

/// Shell root aplikasi — satu-satunya pemilik navigasi bawah, membungkus
/// ke-5 tab (Beranda/Jelajah/Fokus/Monster/Profil) dalam satu
/// [IndexedStack] supaya state tiap tab (scroll position, dsb) tidak
/// hilang saat pindah tab. Ini gerbang M4: "navbar bottom harus terhubung
/// penuh" — sebelumnya tiap layar akar punya `RiungBottomNav` sendiri yang
/// tidak benar-benar menavigasi.
///
/// Sejak M6 juga gerbang Aplikasi Beku: tiap kali Riung kembali ke
/// foreground (bukan WorkManager background — lihat catatan
/// `AppBekuNotifier`), cek pemakaian aplikasi yang dibekukan & tampilkan
/// interstitial kalau ada yang baru melewati batas.
class RootShellScreen extends StatefulWidget {
  const RootShellScreen({super.key});

  @override
  State<RootShellScreen> createState() => _RootShellScreenState();
}

class _RootShellScreenState extends State<RootShellScreen> with WidgetsBindingObserver {
  RiungNavTab _tab = RiungNavTab.beranda;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cekBatasAppBeku());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cekBatasAppBeku();
  }

  bool _lockScreenOpen = false;
  bool _lockWarned = false;

  /// Beri tahu sekali per sesi kalau kunci dinyalakan tapi izinnya mati.
  Future<void> _ingatkanKunciMati() async {
    final scope = AppScope.of(context);
    await scope.appBeku.refreshUsageAccess();
    if (!mounted || _lockWarned || !scope.appBeku.lockNeedsAttention) return;
    _lockWarned = true;
    final t = scope.language.strings.appbeku;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(t.lockInactiveNotice),
        action: SnackBarAction(
          label: t.lockInactiveAction,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppBekuPermissionScreen())),
        ),
      ),
    );
  }

  Future<void> _cekBatasAppBeku() async {
    final appBeku = AppScope.of(context).appBeku;
    _ingatkanKunciMati();
    // Mode kunci: service native membuka Riung tepat saat aplikasi yang
    // melewati batas dibuka — langsung tampilkan layar jedanya.
    final locked = await appBeku.consumeLockedPackage();
    if (!mounted) return;
    if (locked != null && !_lockScreenOpen) {
      _lockScreenOpen = true;
      await appBeku.refreshUsageAccess();
      // Muat menit pemakaian terbaru supaya chip di layar jeda tidak menampilkan 0.
      await appBeku.checkUsageAndMaybeTrigger();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AppBekuInterstitialScreen(packageName: locked, fromLock: true)),
      );
      _lockScreenOpen = false;
      return;
    }
    final triggered = await appBeku.checkUsageAndMaybeTrigger();
    if (triggered == null || !mounted || _lockScreenOpen) return;
    // Fix 2: notifikasi lokal di samping interstitial yang sudah ada —
    // interstitial tetap langsung tampil (perilaku lama dipertahankan),
    // notifikasinya berguna kalau user menutup interstitial lalu
    // membuka lagi app dari notification tray.
    LocalNotificationService.instance.showAppBekuLimitReached(
      packageName: triggered,
      strings: AppScope.of(context).language.strings.notif,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AppBekuInterstitialScreen(packageName: triggered)),
    );
  }

  static const _order = [
    RiungNavTab.beranda,
    RiungNavTab.jelajah,
    RiungNavTab.fokus,
    RiungNavTab.monster,
    RiungNavTab.profil,
  ];

  static const _bodies = [
    BerandaScreen(),
    JelajahScreen(),
    FocusModeEntryScreen(),
    VaultScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _FadeIndexedStack(index: _order.indexOf(_tab), children: _bodies),
      bottomNavigationBar: RiungBottomNav(
        current: _tab,
        onTabSelected: (tab) => setState(() => _tab = tab),
      ),
    );
  }
}

/// [IndexedStack] yang memudarkan + menaikkan sedikit tab baru saat pindah
/// (220ms). State tiap tab tetap utuh; hanya tab aktif yang dianimasikan.
class _FadeIndexedStack extends StatefulWidget {
  const _FadeIndexedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(_curve),
        child: IndexedStack(index: widget.index, children: widget.children),
      ),
    );
  }
}
