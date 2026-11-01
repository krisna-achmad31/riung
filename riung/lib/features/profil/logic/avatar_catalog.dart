/// Avatar Riung (frame `Glass — Buat Avatar (Wajah)`): enam potret 3D. Rambut,
/// kacamata, aksesoris, kulit, dan latar belum dipakai. Id `av1`…`av6`
/// dipertahankan supaya pilihan lama di profil tetap terbaca.
class AvatarOption {
  const AvatarOption(this.id);
  final String id;

  String get asset => 'assets/avatars/$id.webp';
}

abstract final class AvatarCatalog {
  static const List<AvatarOption> all = [
    AvatarOption('av1'),
    AvatarOption('av2'),
    AvatarOption('av3'),
    AvatarOption('av4'),
    AvatarOption('av5'),
    AvatarOption('av6'),
  ];

  static AvatarOption byId(String id) => all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
