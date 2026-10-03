import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';

/// Avatar Riung = pilihan gradien lingkaran + inisial nama (bukan
/// karakter monster — monster mewakili saboteur, bukan identitas user).
/// Desain (`design/Profil.dc.html`) cuma menampilkan satu gradien tetap
/// di header; di sini gradiennya jadi bisa dipilih, tapi bentuknya
/// (lingkaran + inisial) tetap sama seperti desain — bukan sistem
/// avatar baru yang menyimpang.
class AvatarOption {
  const AvatarOption(this.id, this.colors);
  final String id;
  final List<Color> colors;
}

abstract final class AvatarCatalog {
  static const List<AvatarOption> all = [
    AvatarOption('av1', [AppColors.primer, AppColors.sekunder]),
    AvatarOption('av2', [AppColors.sekunder, AppColors.sukses]),
    AvatarOption('av3', [AppColors.aksenHangat, AppColors.error]),
    AvatarOption('av4', [AppColors.monsterCermin, AppColors.primer]),
    AvatarOption('av5', [AppColors.monsterWaswas, AppColors.aksenHangat]),
    AvatarOption('av6', [AppColors.monsterMengelak, AppColors.sekunder]),
  ];

  static AvatarOption byId(String id) => all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
