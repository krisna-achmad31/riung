import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Kartu afirmasi Riung Glass (frame `Kartu depan` di `Glass — Afirmasi`
/// dan `Kartu` di `Glass — Afirmasi · Bagikan`): kaca terang bergradien
/// persik, tag pil, monster jinak 3D, kalimat besar, lalu [footer].
class AfirmasiGlassCard extends StatelessWidget {
  const AfirmasiGlassCard({
    super.key,
    required this.tag,
    required this.monsterId,
    required this.text,
    this.footer,
    this.monsterSize = 140,
    this.tagOnWhite = false,
    this.tone = AfirmasiTone.persik,
  });

  final String tag;
  final String monsterId;
  final String text;
  final Widget? footer;
  final double monsterSize;

  /// Tag berlatar putih (kartu bagikan) atau persik lembut (kartu harian).
  final bool tagOnWhite;

  /// Warna kartu; di tumpukan kartu harian bergiliran supaya kartu yang
  /// terlihat di belakang tetap berwarna sama saat naik ke depan.
  final AfirmasiTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.garis, tone.base, tone.end],
          stops: const [0, 0.65, 1],
        ),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
        boxShadow: AppGlass.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tagOnWhite ? AppColors.permukaan : tone.tag,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              tag,
              style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.3, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: tone.tagText),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: monsterSize,
            height: monsterSize,
            child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: monsterSize, applyBossScale: false),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.15, color: AppColors.teksUtama),
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Nada warna kartu afirmasi: [base] = warna utama gradien (juga warna
/// kartu polos di belakang tumpukan).
enum AfirmasiTone {
  persik(AppColors.aksenHangatLembut, AppColors.kabutLavender, AppColors.aksenHangatLembut, AppColors.aksenHangatGelap),
  lavender(AppColors.kabutLavender, AppColors.sekunderPucat, AppColors.sekunderPucat, AppColors.sekunderGelap),
  sage(AppColors.kabutSage, AppColors.primerLembut, AppColors.primerLembut, AppColors.primerGelap);

  const AfirmasiTone(this.base, this.end, this.tag, this.tagText);

  final Color base;
  final Color end;
  final Color tag;
  final Color tagText;

  /// Giliran warna kartu ke-[index] dari [count] kartu. Tumpukan berputar
  /// (kartu terakhir → kartu pertama), jadi kartu terakhir dipilih beda
  /// dari tetangganya di kedua sisi.
  static AfirmasiTone forCard(int index, int count) {
    final tone = values[index % values.length];
    if (count < 3 || index != count - 1 || tone != values.first) return tone;
    final sebelum = values[(index - 1) % values.length];
    return values.firstWhere((v) => v != values.first && v != sebelum);
  }
}
