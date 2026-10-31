/// Aplikasi terpasang di perangkat, untuk pemilih Aplikasi Beku.
class InstalledApp {
  const InstalledApp({required this.packageName, required this.name, this.protectedReason});

  factory InstalledApp.fromMap(Map<String, dynamic> map) {
    return InstalledApp(
      packageName: map[fPackage] as String,
      name: map[fName] as String,
      protectedReason: map[fProtected] as String?,
    );
  }

  static const fPackage = 'package';
  static const fName = 'name';
  static const fProtected = 'protected';

  final String packageName;
  final String name;

  /// Alasan aplikasi tidak bisa dibekukan; null = boleh dibekukan.
  final String? protectedReason;

  bool get isProtected => protectedReason != null;

  Map<String, dynamic> toMap() => {fPackage: packageName, fName: name, fProtected: protectedReason};

  InstalledApp copyWith({String? name, String? protectedReason}) {
    return InstalledApp(
      packageName: packageName,
      name: name ?? this.name,
      protectedReason: protectedReason ?? this.protectedReason,
    );
  }
}
