import 'package:flutter/painting.dart';

/// Konversi tipe bersama untuk semua model — satu tempat untuk
/// Timestamp/ISO-string → DateTime, num → int, dan hex → Color,
/// supaya tiap model tidak menduplikasi logika parsing.
DateTime? parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  // Dukung objek mirip Firestore Timestamp ({seconds, nanoseconds}) tanpa
  // bergantung pada package cloud_firestore (belum disambungkan sampai M5).
  if (value is Map) {
    final seconds = value['seconds'] ?? value['_seconds'];
    if (seconds is int) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    }
  }
  return null;
}

int parseInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<String> parseStringList(Object? value) {
  if (value is List) return value.map((e) => e.toString()).toList();
  return const [];
}

Map<String, int> parseIntMap(Object? value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), parseInt(v)));
  }
  return const {};
}

Color parseHexColor(String hex, {Color fallback = const Color(0xFF7C8CFF)}) {
  final cleaned = hex.replaceFirst('#', '');
  final full = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  final value = int.tryParse(full, radix: 16);
  return value == null ? fallback : Color(value);
}

String colorToHex(Color color) {
  final channels = <int>[
    (color.a * 255).round(),
    (color.r * 255).round(),
    (color.g * 255).round(),
    (color.b * 255).round(),
  ];
  final argb = channels.fold<int>(0, (acc, c) => (acc << 8) | (c & 0xFF));
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// Enum dari nama String dengan fallback aman untuk data lama/tidak dikenal.
T enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
