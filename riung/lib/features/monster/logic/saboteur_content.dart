import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';

/// Satu teknik penangkal — badge `5×`/`3×`/`2×` menandai seberapa manjur
/// (dipakai juga sebagai pengganda kerusakan di mini-game, lihat
/// `design/Monster.dc.html` § Detail Si Waswas).
class SaboteurTechnique {
  const SaboteurTechnique({required this.icon, required this.label, required this.multiplier});

  final IconData icon;
  final String label;
  final int multiplier;
}

/// Konten naratif per monster — kutipan "apa katanya", reframe CBT
/// "faktanya", deskripsi distorsi, dan 3 teknik penangkal. Sumbernya
/// `docs/riung-cara-kerja-lengkap.md` §2 (kolom "Suaranya") +
/// `dummy-data-seed.json` (deskripsi/distorsi_cbt/cara_menjinakkan) — bukan
/// dari `ContentRepository` karena datanya jauh lebih kaya (kutipan,
/// reframe, 3 teknik berbobot) daripada yang tersedia di seed.
///
/// Gaya penulisan: ngobrol, bukan artikel. Tidak ada tanda pisah panjang
/// (— atau –) — semua ditulis sebagai kalimat yang mengalir. "Apa katanya"
/// = suara familiar di kepala, bukan kutipan textbook. "Faktanya" = teman
/// yang nudge pelan, bukan terapis ceramah. Teknik = actionable & konkret.
///
/// Teks per bahasa ada di `MonsterStrings.saboteurTexts`; file ini cuma
/// menyimpan konfigurasi (ikon & pengganda tiap teknik, urutan sama dengan
/// daftar teks) dan merakitnya lewat [saboteurContentFor].
class SaboteurContent {
  const SaboteurContent({
    required this.apaKatanya,
    required this.faktanya,
    required this.duniaNyata,
    required this.techniques,
  });

  final String apaKatanya;
  final String faktanya;
  final String duniaNyata;
  final List<SaboteurTechnique> techniques;
}

const Map<String, List<(IconData, int)>> _techniqueSpecs = {
  'hakim': [(Icons.menu_book_rounded, 5), (Icons.chat_bubble_outline, 3), (Icons.edit_outlined, 2)],
  'waswas': [(Icons.calendar_today_outlined, 5), (Icons.menu_book_rounded, 3), (Icons.visibility_outlined, 2)],
  'sempurna': [(Icons.autorenew, 5), (Icons.celebration_outlined, 3), (Icons.flag_outlined, 2)],
  'cermin': [(Icons.menu_book_rounded, 5), (Icons.timer_outlined, 3), (Icons.filter_alt_outlined, 2)],
  'kabut': [(Icons.center_focus_strong_outlined, 5), (Icons.checklist_outlined, 3), (Icons.first_page_outlined, 2)],
  'mengelak': [(Icons.flag_outlined, 5), (Icons.menu_book_rounded, 3), (Icons.chat_bubble_outline, 2)],
  'meronta': [(Icons.menu_book_rounded, 5), (Icons.call_split, 3), (Icons.directions_walk, 2)],
};

/// Rakit konten [id] dalam bahasa aktif; null kalau monster itu belum punya
/// konten naratif.
SaboteurContent? saboteurContentFor(String id, MonsterStrings t) {
  final texts = t.saboteurTexts[id];
  final specs = _techniqueSpecs[id];
  if (texts == null || specs == null) return null;
  return SaboteurContent(
    apaKatanya: texts.apaKatanya,
    faktanya: texts.faktanya,
    duniaNyata: texts.duniaNyata,
    techniques: [
      for (var i = 0; i < specs.length; i++)
        SaboteurTechnique(icon: specs[i].$1, label: texts.techniques[i], multiplier: specs[i].$2),
    ],
  );
}
