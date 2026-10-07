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
/// apa adanya sebagai isi tiap tab.
class JelajahScreen extends StatefulWidget {
  const JelajahScreen({super.key});

  @override
  State<JelajahScreen> createState() => _JelajahScreenState();
}

/// Indeks tab Tidur — tab ini memakai latar malam penuh.
const _tidurTab = 1;

class _JelajahScreenState extends State<JelajahScreen> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.home;
    final tabs = [t.tabMeditation, t.tabSleep, t.tabJournal, t.tabAffirmation];
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => RiungGlassBackdrop(night: _controller.index == _tidurTab, child: child!),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) =>
                      RiungSegmentedTabs(labels: tabs, index: _controller.index, onChanged: _controller.animateTo, night: _controller.index == _tidurTab),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _controller,
                  children: const [MeditasiListScreen(), TidurListScreen(), JurnalHomeScreen(), AfirmasiKategoriScreen()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
