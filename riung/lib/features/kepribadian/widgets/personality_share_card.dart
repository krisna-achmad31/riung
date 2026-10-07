import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/personality_result.dart';
import '../../../core/theme/theme.dart';
import '../logic/card_style.dart';
import '../logic/character_accessory.dart';
import '../logic/character_spec.dart';
import 'card_background_painter.dart';
import 'character_avatar.dart';

/// Kartu karakter siap bagikan (rasio 9:16 seperti story). Hanya memuat
/// hasil tes (nama, tagline, kekuatan) + merek Riung: TIDAK PERNAH isi
/// jurnal atau data pribadi. Dibungkus `RepaintBoundary` oleh layar hasil
/// untuk diekspor ke PNG lewat `CardImageExporter`.
class PersonalityShareCard extends StatelessWidget {
  const PersonalityShareCard({super.key, required this.result, required this.style, this.accessories = const []});

  final PersonalityResult result;
  final CardStyle style;
  final List<CharacterAccessory> accessories;

  static const double aspect = 9 / 16;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    final spec = CharacterSpec.fromResult(result);
    final ProfileText text;
    switch (result.test) {
      case PersonalityTest.jung:
        text = t.jungType(result.code);
      case PersonalityTest.temperament:
        text = t.temperament(result.code);
      case PersonalityTest.attachment:
        text = t.attachment(result.code);
    }
    final secondary = result.secondary == null ? null : t.temperament(result.secondary!).name;

    final dark = CardBackgroundPainter.isDark(style);
    final ink = dark ? AppNight.teks : AppColors.teksUtama;
    final soft = dark ? AppNight.teksSekunder : AppColors.teksSekunder;
    final accent = dark ? AppNight.aksen : AppColors.sekunder;

    return AspectRatio(
      aspectRatio: aspect,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.garis, width: 2),
          boxShadow: AppGlass.shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: CardBackgroundPainter(style, spec.base)),
              LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.07, vertical: w * 0.07),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.012),
                          decoration: BoxDecoration(color: dark ? AppNight.pil : AppColors.permukaan, borderRadius: BorderRadius.circular(999)),
                          child: Text(t.resultKicker, style: AppTextStyles.caption.copyWith(fontSize: w * 0.03, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: accent)),
                        ),
                        const Spacer(),
                        CharacterAvatar(spec: spec, size: w * 0.6, accessories: accessories),
                        SizedBox(height: w * 0.03),
                        if (result.test == PersonalityTest.jung)
                          Text(result.code, style: AppTextStyles.chipLabel.copyWith(fontSize: w * 0.045, letterSpacing: 2, color: accent)),
                        Text(
                          secondary == null ? text.name : '${text.name} + $secondary',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.display.copyWith(fontSize: w * (secondary == null ? 0.085 : 0.07), height: 1.15, color: ink),
                        ),
                        SizedBox(height: w * 0.025),
                        Text(
                          text.tagline,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(fontSize: w * 0.04, height: 1.4, fontWeight: FontWeight.w500, color: soft),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: w * 0.024, height: w * 0.024, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                            SizedBox(width: w * 0.02),
                            Text(
                              '${t.cardTagline(result.test)} · riung.app',
                              style: AppTextStyles.caption.copyWith(fontSize: w * 0.032, fontWeight: FontWeight.w700, color: soft),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
