import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../afirmasi/screens/afirmasi_kategori_screen.dart';
import '../../jurnal/screens/jurnal_home_screen.dart';
import '../../meditasi/screens/meditasi_list_screen.dart';
import '../../tidur/screens/tidur_list_screen.dart';

/// Tab "Jelajah" — pusat 4 latihan pilihan (Meditasi/Tidur/Jurnal/Afirmasi)
/// di balik satu TabBar, supaya semuanya bisa dicapai dari navigasi bawah
/// (M4: "navbar bottom harus terhubung penuh"). Layar M3 di bawahnya dipakai
/// sebagai isi tiap tab tanpa tombol kembali di header.
class JelajahScreen extends StatefulWidget {
  const JelajahScreen({super.key});

  @override
  State<JelajahScreen> createState() => _JelajahScreenState();
}

/// Indeks tab Tidur — tab ini memakai latar malam penuh.
const _tidurTab = 1;

class _JelajahScreenState extends State<JelajahScreen> with TickerProviderStateMixin {
  late final TabController _controller = TabController(length: 4, vsync: this)..addListener(_syncNight);

  /// Redup siang→malam terpisah dari geser halaman supaya perlahan.
  late final AnimationController _night = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  void _syncNight() {
    final target = _controller.index == _tidurTab ? 1.0 : 0.0;
    if (_night.value != target && _night.status != (target == 1 ? AnimationStatus.forward : AnimationStatus.reverse)) {
      _night.animateTo(target, curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _night.dispose();
    super.dispose();
  }

  /// 0 = siang, 1 = penuh di tab Tidur.
  double get _nightAmount => _night.value;

  @override
  Widget build(BuildContext context) {
    final t = context.s.home;
    final tabs = [t.tabMeditation, t.tabSleep, t.tabJournal, t.tabAffirmation];
    return Scaffold(
      body: AnimatedBuilder(
        animation: _night,
        // Latar meredup perlahan ke malam mengikuti posisi tab (geser/ketuk).
        builder: (context, child) => Stack(
          fit: StackFit.expand,
          children: [
            const RiungGlassBackdrop(child: SizedBox.expand()),
            Opacity(opacity: _nightAmount, child: const RiungGlassBackdrop(night: true, child: SizedBox.expand())),
            child!,
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_controller, _night]),
                  builder: (context, _) => RiungSegmentedTabs(
                    labels: tabs,
                    index: _controller.index,
                    onChanged: _controller.animateTo,
                    night: _nightAmount > 0.5,
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _controller,
                  children: const [
                    MeditasiListScreen(embedded: true),
                    TidurListScreen(embedded: true),
                    JurnalHomeScreen(embedded: true),
                    AfirmasiKategoriScreen(embedded: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
