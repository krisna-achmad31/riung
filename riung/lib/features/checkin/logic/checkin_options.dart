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
  CheckInFactorOption(id: 'kerjaan', icon: Icons.work_outline_rounded),
  CheckInFactorOption(id: 'kuliah', icon: Icons.school_outlined),
  CheckInFactorOption(id: 'takut_gagal', icon: Icons.terrain_outlined),
  CheckInFactorOption(id: 'keluarga', icon: Icons.home_outlined),
  CheckInFactorOption(id: 'uang', icon: Icons.account_balance_wallet_outlined),
  CheckInFactorOption(id: 'hubungan', icon: Icons.favorite_border_rounded),
  CheckInFactorOption(id: 'kurang_tidur', icon: Icons.bedtime_outlined),
  CheckInFactorOption(id: 'kesehatan', icon: Icons.health_and_safety_outlined),
  CheckInFactorOption(id: 'medsos', icon: Icons.phone_iphone_rounded),
  CheckInFactorOption(id: 'lainnya', icon: Icons.add_rounded),
];
