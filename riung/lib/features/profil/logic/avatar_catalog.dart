import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';

/// Avatar Riung (frame `Glass — Profil · Edit profil`): monster jinak di
/// atas lingkaran gradien lembut. Id `av1`…`av6` dipertahankan supaya
/// pilihan lama di profil tetap terbaca.
class AvatarOption {
  const AvatarOption(this.id, this.monsterId);
  final String id;
  final String monsterId;

  List<Color> get colors => [AppColors.monsterLembut[monsterId] ?? AppColors.langitLembut, AppColors.sekunderLembut];
}

abstract final class AvatarCatalog {
  static const List<AvatarOption> all = [
    AvatarOption('av1', 'kabut'),
    AvatarOption('av2', 'waswas'),
    AvatarOption('av3', 'cermin'),
    AvatarOption('av4', 'meronta'),
    AvatarOption('av5', 'sempurna'),
    AvatarOption('av6', 'mengelak'),
  ];

  static AvatarOption byId(String id) => all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
