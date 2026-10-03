import 'package:flutter/painting.dart';

import 'model_utils.dart';

/// Mirror `/content/saboteurs/{saboteurId}` — konten psikoedukasi 7 monster,
/// dibaca publik (read-only). Si Hakim = boss, selalu tampil sebagai bos
/// terlepas dari peringkat skor asesmennya.
class Saboteur {
  const Saboteur({
    required this.id,
    required this.nama,
    required this.distorsiCbt,
    required this.warna,
    required this.deskripsi,
    required this.tanda,
    required this.caraMenjinakkan,
    required this.faktaRiset,
    required this.isBoss,
  });

  factory Saboteur.fromMap(Map<String, dynamic> map) {
    return Saboteur(
      id: map[fId] as String,
      nama: map[fNama] as String,
      distorsiCbt: map[fDistorsiCbt] as String,
      warna: parseHexColor(map[fWarna] as String? ?? '#7C8CFF'),
      deskripsi: map[fDeskripsi] as String,
      tanda: parseStringList(map[fTanda]),
      caraMenjinakkan: map[fCaraMenjinakkan] as String,
      faktaRiset: map[fFaktaRiset] as String,
      isBoss: map[fIsBoss] as bool? ?? false,
    );
  }

  static const fId = 'id';
  static const fNama = 'nama';
  static const fDistorsiCbt = 'distorsi_cbt';
  static const fWarna = 'warna';
  static const fDeskripsi = 'deskripsi';
  static const fTanda = 'tanda';
  static const fCaraMenjinakkan = 'cara_menjinakkan';
  static const fFaktaRiset = 'fakta_riset';
  static const fIsBoss = 'boss';

  final String id;
  final String nama;
  final String distorsiCbt;
  final Color warna;
  final String deskripsi;
  final List<String> tanda;
  final String caraMenjinakkan;
  final String faktaRiset;
  final bool isBoss;

  Map<String, dynamic> toMap() => {
        fId: id,
        fNama: nama,
        fDistorsiCbt: distorsiCbt,
        fWarna: colorToHex(warna),
        fDeskripsi: deskripsi,
        fTanda: tanda,
        fCaraMenjinakkan: caraMenjinakkan,
        fFaktaRiset: faktaRiset,
        fIsBoss: isBoss,
      };
}
