import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
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
      backgroundColor: AppColors.latar,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.garis))),
              child: TabBar(
                controller: _controller,
                isScrollable: false,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                indicatorColor: AppColors.primer,
                indicatorWeight: 3,
                labelColor: AppColors.teksUtama,
                unselectedLabelColor: AppColors.teksRedup,
                labelStyle: AppTextStyles.chipLabel.copyWith(fontSize: 13),
                tabs: [for (final label in tabs) Tab(text: label)],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: const [
                  MeditasiListScreen(),
                  TidurListScreen(),
                  JurnalHomeScreen(),
                  AfirmasiKategoriScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
