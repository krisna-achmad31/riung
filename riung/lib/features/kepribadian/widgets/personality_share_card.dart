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

    return AspectRatio(
      aspectRatio: aspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: CardBackgroundPainter(style, spec.base)),
            LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.08, vertical: w * 0.09),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Riung', style: AppTextStyles.display.copyWith(fontSize: w * 0.075)),
                          const Spacer(),
                          Text(t.testName(result.test), style: AppTextStyles.caption.copyWith(fontSize: w * 0.034, color: AppColors.teksSekunder)),
                        ],
                      ),
                      const Spacer(),
                      CharacterAvatar(spec: spec, size: w * 0.7, accessories: accessories),
                      SizedBox(height: w * 0.04),
                      Text(
                        t.resultKicker,
                        style: AppTextStyles.caption.copyWith(fontSize: w * 0.03, letterSpacing: 2, fontWeight: FontWeight.w700, color: spec.base),
                      ),
                      SizedBox(height: w * 0.02),
                      if (result.test == PersonalityTest.jung)
                        Text(result.code, style: AppTextStyles.display.copyWith(fontSize: w * 0.15, letterSpacing: 4, color: spec.base)),
                      Text(
                        secondary == null ? text.name : '${text.name} + $secondary',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display.copyWith(fontSize: w * (result.test == PersonalityTest.jung ? 0.07 : (secondary == null ? 0.1 : 0.075)), height: 1.15),
                      ),
                      SizedBox(height: w * 0.03),
                      Text(
                        text.tagline,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(fontSize: w * 0.04, height: 1.45, color: AppColors.teksSekunder),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.025),
                        decoration: BoxDecoration(
                          color: AppColors.latar.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.garis),
                        ),
                        child: Text(
                          '${t.cardTagline(result.test)} · riung.app',
                          style: AppTextStyles.caption.copyWith(fontSize: w * 0.032, fontWeight: FontWeight.w700, color: AppColors.teksSekunder),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
