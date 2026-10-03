import 'package:flutter/material.dart';

/// Satu opsi mood (langkah 1). Urutan persis `design/Checkin.dc.html`;
/// label per bahasa di `CheckinStrings.moodLabel(id)`.
class CheckInMoodOption {
  const CheckInMoodOption({required this.id, required this.emoji});

  final String id;
  final String emoji;
}

const List<CheckInMoodOption> checkInMoods = [
  CheckInMoodOption(id: 'berat', emoji: '😞'),
  CheckInMoodOption(id: 'agak_berat', emoji: '😟'),
  CheckInMoodOption(id: 'datar', emoji: '😐'),
  CheckInMoodOption(id: 'cukup_baik', emoji: '🙂'),
  CheckInMoodOption(id: 'senang', emoji: '😄'),
];

/// Satu opsi faktor (langkah 2, maks 3 dipilih). Label: `CheckinStrings.factorLabel(id)`.
class CheckInFactorOption {
  const CheckInFactorOption({required this.id, required this.icon});

  final String id;
  final IconData icon;
}

const List<CheckInFactorOption> checkInFactors = [
  CheckInFactorOption(id: 'kerjaan', icon: Icons.bar_chart),
  CheckInFactorOption(id: 'kuliah', icon: Icons.menu_book_rounded),
  CheckInFactorOption(id: 'takut_gagal', icon: Icons.pest_control),
  CheckInFactorOption(id: 'keluarga', icon: Icons.favorite),
  CheckInFactorOption(id: 'uang', icon: Icons.monetization_on),
  CheckInFactorOption(id: 'hubungan', icon: Icons.person),
  CheckInFactorOption(id: 'kurang_tidur', icon: Icons.nightlight_round),
  CheckInFactorOption(id: 'kesehatan', icon: Icons.shield),
  CheckInFactorOption(id: 'medsos', icon: Icons.visibility),
  CheckInFactorOption(id: 'lainnya', icon: Icons.add),
];
