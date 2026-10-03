import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../logic/character_accessory.dart';
import '../logic/character_art.dart';
import '../logic/character_spec.dart';

/// Karakter hasil tes. Bila [CharacterSpec.artKey] punya art 3D
/// ([CharacterArt]), karakter ditampilkan dari gambar dan aksesori ditempel
/// memakai geometri yang diukur dari gambar itu (aksesori ber-art 3D sebagai
/// gambar, sisanya digambar painter). Tanpa art, karakter digambar prosedural
/// dengan kanvas mengikuti [CharacterSpec].
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({super.key, required this.spec, this.size = 120, this.accessories = const []});

  final CharacterSpec spec;
  final double size;

  /// Aksesori yang dipakai (maks satu per slot), digambar di atas karakter.
  final List<CharacterAccessory> accessories;

  @override
  Widget build(BuildContext context) {
    final art = CharacterArt.of(spec.artKey);
    if (art == null) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _CharacterPainter(spec, accessories)),
      );
    }

    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final painted = accessories.where((a) => AccessoryArt.of(a) == null).toList();
    final imaged = accessories.where((a) => AccessoryArt.of(a) != null).toList();
    final back = imaged.where((a) => a.slot == AccessorySlot.back);
    final front = imaged.where((a) => a.slot != AccessorySlot.back);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _CharacterPainter(spec, painted, art: art, phase: _Phase.back))),
          for (final a in back) _AccessoryImage(art: art, accessory: a, size: size, dpr: dpr),
          Positioned.fill(child: _ArtImage(asset: art.asset, width: size, dpr: dpr)),
          for (final a in front) _AccessoryImage(art: art, accessory: a, size: size, dpr: dpr),
          Positioned.fill(child: CustomPaint(painter: _CharacterPainter(spec, painted, art: art, phase: _Phase.front))),
        ],
      ),
    );
  }
}

/// Aksesori ber-art 3D, ditempel ke titik acuan [AccessoryArt.anchor].
class _AccessoryImage extends StatelessWidget {
  const _AccessoryImage({required this.art, required this.accessory, required this.size, required this.dpr});

  final CharacterArt art;
  final CharacterAccessory accessory;
  final double size;
  final double dpr;

  @override
  Widget build(BuildContext context) {
    final rule = AccessoryArt.of(accessory)!;
    final unitX = rule.eyeScaled ? art.eyeDx : art.bodyWidth;
    final w = rule.width * unitX;
    final ax = art.eyeX + rule.offsetX * unitX;
    final base = switch (rule.anchor) {
      AccessoryAnchor.headTop || AccessoryAnchor.body => art.top,
      AccessoryAnchor.eyes => art.eyeY,
    };
    final ay = base + rule.offsetY * art.bodyHeight;
    final width = w * size;
    final height = width / rule.aspect;
    return Positioned(
      left: ax * size - rule.pivotX * width,
      top: ay * size - rule.pivotY * height,
      width: width,
      height: height,
      child: _ArtImage(asset: rule.asset(accessory), width: width, dpr: dpr),
    );
  }
}

class _ArtImage extends StatelessWidget {
  const _ArtImage({required this.asset, required this.width, required this.dpr});

  final String asset;
  final double width;
  final double dpr;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      // Minimal 3× supaya kartu bagikan yang diekspor tetap tajam.
      cacheWidth: (width * math.max(dpr, 3.0)).round().clamp(1, 1024),
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
  }
}

/// Lapisan painter: `all` = karakter prosedural lengkap; `back`/`front` =
/// hanya aksesori di belakang/depan art 3D.
enum _Phase { all, back, front }

class _CharacterPainter extends CustomPainter {
  _CharacterPainter(this.spec, this.accessories, {this.art, this.phase = _Phase.all});

  final CharacterSpec spec;
  final List<CharacterAccessory> accessories;
  final CharacterArt? art;
  final _Phase phase;

  bool _has(AccessorySlot slot) => accessories.any((a) => a.slot == slot);

  // Geometri karakter, diisi di awal [paint] supaya aksesori bisa dipasang.
  double _s = 0, _cx = 0, _bodyTop = 0, _bodyW = 0, _bodyH = 0, _eyeY = 0, _eyeDx = 0, _eyeR = 0;

  @override
  void paint(Canvas canvas, Size size) {
    final art = this.art;
    if (art != null) {
      _paintArtAccessories(canvas, size.width, art);
      return;
    }
    _paintProcedural(canvas, size);
  }

  /// Mode art 3D: geometri dari [CharacterArt], hanya aksesori yang digambar.
  void _paintArtAccessories(Canvas canvas, double s, CharacterArt art) {
    _s = s;
    _cx = art.eyeX * s;
    _bodyTop = art.top * s;
    _bodyW = art.bodyWidth * s * 0.86;
    _bodyH = art.bodyHeight * s;
    _eyeY = art.eyeY * s;
    _eyeDx = art.eyeDx * s;
    _eyeR = art.eyeDx * s * 0.42;
    if (phase == _Phase.back) {
      _paintBackAccessory(canvas);
    } else {
      _paintFrontAccessories(canvas);
    }
  }

  void _paintProcedural(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;
    final bodyW = s * (spec.wide ? 0.74 : 0.6);
    final bodyH = s * (spec.wide ? 0.62 : 0.72);
    final bodyTop = s * (spec.wide ? 0.26 : 0.18);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - bodyW / 2, bodyTop, bodyW, bodyH),
      Radius.circular(math.min(bodyW, bodyH) * 0.46),
    );

    // Bayangan di lantai.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bodyTop + bodyH + s * 0.02), width: bodyW * 0.86, height: s * 0.07),
      Paint()..color = AppColors.latar.withValues(alpha: 0.5),
    );

    _s = s;
    _cx = cx;
    _bodyTop = bodyTop;
    _bodyW = bodyW;
    _bodyH = bodyH;
    _eyeR = s * (spec.wide ? 0.072 : 0.062);

    _paintBehind(canvas, s, cx, bodyTop, bodyW, bodyH);
    _paintBackAccessory(canvas);

    // Badan + kilau.
    canvas.drawRRect(body, Paint()..color = spec.base);
    if (spec.extra == CharacterExtra.split) {
      canvas.save();
      canvas.clipRRect(body);
      canvas.drawRect(Rect.fromLTWH(cx, bodyTop, bodyW / 2, bodyH), Paint()..color = spec.accent.withValues(alpha: 0.85));
      canvas.restore();
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bodyTop + bodyH * 0.72), width: bodyW * 0.62, height: bodyH * 0.36),
      Paint()..color = AppColors.teksUtama.withValues(alpha: 0.16),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - bodyW * 0.22, bodyTop + bodyH * 0.16), width: bodyW * 0.22, height: bodyH * 0.1),
      Paint()..color = AppColors.teksUtama.withValues(alpha: 0.22),
    );

    final eyeY = bodyTop + bodyH * 0.38;
    final eyeDx = bodyW * 0.2;
    _eyeY = eyeY;
    _eyeDx = eyeDx;
    _paintFace(canvas, s, cx, eyeY, eyeDx, bodyH);
    if (!_has(AccessorySlot.head)) _paintTop(canvas, s, cx, bodyTop, bodyW);
    _paintExtra(canvas, s, cx, bodyTop, bodyW, bodyH);
    _paintFrontAccessories(canvas);
  }

  void _paintBehind(Canvas canvas, double s, double cx, double bodyTop, double bodyW, double bodyH) {
    if (spec.extra == CharacterExtra.shell) {
      // Cangkang di belakang badan: karakter yang menjaga jarak.
      final shell = Rect.fromCenter(center: Offset(cx, bodyTop + bodyH * 0.62), width: bodyW * 1.25, height: bodyH * 0.95);
      canvas.drawArc(shell, math.pi, math.pi, true, Paint()..color = spec.accent.withValues(alpha: 0.55));
      canvas.drawArc(shell.deflate(s * 0.03), math.pi, math.pi, false, Paint()
        ..color = AppColors.latar.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012);
    }
  }

  void _paintFace(Canvas canvas, double s, double cx, double eyeY, double eyeDx, double bodyH) {
    final white = Paint()..color = AppColors.teksUtama;
    final dark = Paint()..color = AppColors.latar;
    final eyeR = s * (spec.wide ? 0.072 : 0.062);
    for (final dx in [-eyeDx, eyeDx]) {
      canvas.drawCircle(Offset(cx + dx, eyeY), eyeR, white);
      canvas.drawCircle(Offset(cx + dx + (spec.wide ? 0 : -eyeR * 0.15), eyeY + eyeR * (spec.wide ? 0.05 : 0.2)), eyeR * 0.52, dark);
      canvas.drawCircle(Offset(cx + dx + eyeR * 0.2, eyeY - eyeR * 0.15), eyeR * 0.16, white);
    }

    // Mulut: lebar untuk ekstrovert, kecil untuk introvert.
    final mouthY = eyeY + bodyH * 0.2;
    final mouthW = s * (spec.wide ? 0.2 : 0.11);
    final mouth = Path()
      ..moveTo(cx - mouthW / 2, mouthY)
      ..quadraticBezierTo(cx, mouthY + s * (spec.wide ? 0.09 : 0.05), cx + mouthW / 2, mouthY);
    canvas.drawPath(
      mouth,
      Paint()
        ..color = AppColors.latar
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016
        ..strokeCap = StrokeCap.round,
    );

    switch (spec.face) {
      case CharacterFace.glasses:
        if (_has(AccessorySlot.face)) break;
        final frame = Paint()
          ..color = AppColors.latar
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.014;
        for (final dx in [-eyeDx, eyeDx]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + dx, eyeY), width: eyeR * 2.7, height: eyeR * 2.3), Radius.circular(eyeR * 0.6)),
            frame,
          );
        }
        canvas.drawLine(Offset(cx - eyeDx + eyeR * 1.35, eyeY), Offset(cx + eyeDx - eyeR * 1.35, eyeY), frame);
      case CharacterFace.hearts:
        for (final dx in [-eyeDx * 1.35, eyeDx * 1.35]) {
          _heart(canvas, Offset(cx + dx, eyeY + eyeR * 1.9), s * 0.032, AppColors.error.withValues(alpha: 0.75));
        }
      case CharacterFace.blush:
        for (final dx in [-eyeDx * 1.3, eyeDx * 1.3]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + dx, eyeY + eyeR * 1.9), width: s * 0.07, height: s * 0.04),
            Paint()..color = AppColors.error.withValues(alpha: 0.35),
          );
        }
      case CharacterFace.plain:
        break;
    }
  }

  void _paintTop(Canvas canvas, double s, double cx, double bodyTop, double bodyW) {
    switch (spec.top) {
      case CharacterTop.sprout:
        final stemBase = Offset(cx, bodyTop + s * 0.01);
        canvas.drawLine(
          stemBase,
          Offset(cx, bodyTop - s * 0.07),
          Paint()
            ..color = spec.accent
            ..strokeWidth = s * 0.02
            ..strokeCap = StrokeCap.round,
        );
        final leaf = Paint()..color = spec.accent;
        canvas.save();
        canvas.translate(cx, bodyTop - s * 0.07);
        canvas.rotate(-0.6);
        canvas.drawOval(Rect.fromLTWH(-s * 0.075, -s * 0.03, s * 0.075, s * 0.04), leaf);
        canvas.rotate(1.2);
        canvas.drawOval(Rect.fromLTWH(0, -s * 0.03, s * 0.075, s * 0.04), leaf);
        canvas.restore();
      case CharacterTop.star:
        _star(canvas, Offset(cx + bodyW * 0.28, bodyTop - s * 0.05), s * 0.06, spec.accent);
      case CharacterTop.none:
        break;
    }
  }

  void _paintExtra(Canvas canvas, double s, double cx, double bodyTop, double bodyW, double bodyH) {
    switch (spec.extra) {
      case CharacterExtra.bowtie:
        if (_has(AccessorySlot.neck)) break;
        final y = bodyTop + bodyH * 0.9;
        final paint = Paint()..color = spec.accent;
        final left = Path()
          ..moveTo(cx, y)
          ..lineTo(cx - s * 0.09, y - s * 0.045)
          ..lineTo(cx - s * 0.09, y + s * 0.045)
          ..close();
        final right = Path()
          ..moveTo(cx, y)
          ..lineTo(cx + s * 0.09, y - s * 0.045)
          ..lineTo(cx + s * 0.09, y + s * 0.045)
          ..close();
        canvas.drawPath(left, paint);
        canvas.drawPath(right, paint);
        canvas.drawCircle(Offset(cx, y), s * 0.02, Paint()..color = AppColors.latar.withValues(alpha: 0.4));
      case CharacterExtra.tuft:
        if (_has(AccessorySlot.head)) break;
        final stroke = Paint()
          ..color = spec.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02
          ..strokeCap = StrokeCap.round;
        for (var i = -1; i <= 1; i++) {
          final x = cx - bodyW * 0.28 + i * s * 0.03;
          final p = Path()
            ..moveTo(x, bodyTop + s * 0.015)
            ..quadraticBezierTo(x - s * 0.03, bodyTop - s * 0.05, x + s * 0.02 * (i + 2), bodyTop - s * 0.07);
          canvas.drawPath(p, stroke);
        }
      case CharacterExtra.crown:
        if (_has(AccessorySlot.head)) break;
        final y = bodyTop - s * 0.01;
        final crown = Path()
          ..moveTo(cx - s * 0.1, y)
          ..lineTo(cx - s * 0.11, y - s * 0.08)
          ..lineTo(cx - s * 0.05, y - s * 0.04)
          ..lineTo(cx, y - s * 0.1)
          ..lineTo(cx + s * 0.05, y - s * 0.04)
          ..lineTo(cx + s * 0.11, y - s * 0.08)
          ..lineTo(cx + s * 0.1, y)
          ..close();
        canvas.drawPath(crown, Paint()..color = spec.accent);
      case CharacterExtra.sparks:
        for (final p in [
          Offset(cx - bodyW * 0.62, bodyTop + bodyH * 0.1),
          Offset(cx + bodyW * 0.6, bodyTop + bodyH * 0.22),
          Offset(cx - bodyW * 0.5, bodyTop + bodyH * 0.62),
        ]) {
          _star(canvas, p, s * 0.035, spec.accent);
        }
      case CharacterExtra.tremble:
        final line = Paint()
          ..color = spec.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.014
          ..strokeCap = StrokeCap.round;
        for (final side in [-1.0, 1.0]) {
          for (var i = 0; i < 2; i++) {
            final x = cx + side * (bodyW * 0.58 + i * s * 0.035);
            final y = bodyTop + bodyH * 0.45;
            final p = Path()
              ..moveTo(x, y - s * 0.05)
              ..quadraticBezierTo(x + side * s * 0.02, y, x, y + s * 0.05);
            canvas.drawPath(p, line);
          }
        }
      case CharacterExtra.shell:
      case CharacterExtra.split:
      case CharacterExtra.none:
        break;
    }
  }

  // ── Aksesori (printilan) ──
  CharacterAccessory? _in(AccessorySlot slot) {
    for (final a in accessories) {
      if (a.slot == slot) return a;
    }
    return null;
  }

  void _paintBackAccessory(Canvas canvas) {
    final a = _in(AccessorySlot.back);
    if (a == null) return;
    final s = _s, cx = _cx, top = _bodyTop, w = _bodyW, h = _bodyH;
    switch (a) {
      case CharacterAccessory.cape:
        final path = Path()
          ..moveTo(cx - w * 0.36, top + h * 0.5)
          ..lineTo(cx - w * 0.62, top + h * 1.02)
          ..quadraticBezierTo(cx, top + h * 1.12, cx + w * 0.62, top + h * 1.02)
          ..lineTo(cx + w * 0.36, top + h * 0.5)
          ..close();
        canvas.drawPath(path, Paint()..color = AppColors.error.withValues(alpha: 0.9));
      case CharacterAccessory.wings:
        for (final side in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(cx + side * w * 0.5, top + h * 0.5);
          canvas.rotate(side * 0.5);
          canvas.drawOval(Rect.fromCenter(center: Offset(side * s * 0.09, 0), width: s * 0.2, height: s * 0.34), Paint()..color = AppColors.teksUtama.withValues(alpha: 0.9));
          canvas.drawOval(Rect.fromCenter(center: Offset(side * s * 0.09, 0), width: s * 0.12, height: s * 0.24), Paint()..color = AppColors.teksSekunder.withValues(alpha: 0.5));
          canvas.restore();
        }
      case CharacterAccessory.backpack:
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(cx + w * 0.3, top + h * 0.42, s * 0.16, s * 0.24), Radius.circular(s * 0.04));
        canvas.drawRRect(r, Paint()..color = AppColors.aksenHangat);
        canvas.drawRRect(r.deflate(s * 0.03), Paint()..color = AppColors.latar.withValues(alpha: 0.25));
      case CharacterAccessory.jungLantern:
        // Lentera batin: menggantung di sisi kanan.
        final c = Offset(cx + w * 0.6, top + h * 0.45);
        canvas.drawLine(Offset(c.dx, c.dy - s * 0.12), Offset(c.dx, c.dy - s * 0.05), Paint()
          ..color = AppColors.teksSekunder
          ..strokeWidth = s * 0.012);
        canvas.drawCircle(c, s * 0.11, Paint()..color = AppColors.peringatan.withValues(alpha: 0.22));
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: s * 0.08, height: s * 0.11), Radius.circular(s * 0.025)),
          Paint()..color = AppColors.peringatan,
        );
        canvas.drawRect(Rect.fromCenter(center: Offset(c.dx, c.dy - s * 0.06), width: s * 0.09, height: s * 0.014), Paint()..color = AppColors.latar);
      case CharacterAccessory.tempWave:
        // Ombak di belakang badan (air).
        for (var i = 0; i < 3; i++) {
          final y = top + h * (0.78 + i * 0.09);
          final wave = Path()..moveTo(cx - w * 0.7, y);
          for (var k = 0; k < 4; k++) {
            wave.quadraticBezierTo(cx - w * 0.7 + (k + 0.5) * w * 0.35, y - s * 0.05, cx - w * 0.7 + (k + 1) * w * 0.35, y);
          }
          canvas.drawPath(wave, Paint()
            ..color = (i.isEven ? AppColors.sekunder : AppColors.primer).withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.028
            ..strokeCap = StrokeCap.round);
        }
      case CharacterAccessory.attCompanion:
        // Teman kecil di samping kiri: makhluk mungil yang setia menemani.
        final c = Offset(cx - w * 0.62, top + h * 0.82);
        canvas.drawCircle(c, s * 0.075, Paint()..color = AppColors.monsterCermin);
        canvas.drawCircle(c + Offset(-s * 0.025, -s * 0.01), s * 0.014, Paint()..color = AppColors.teksUtama);
        canvas.drawCircle(c + Offset(s * 0.025, -s * 0.01), s * 0.014, Paint()..color = AppColors.teksUtama);
        canvas.drawArc(Rect.fromCenter(center: c + Offset(0, s * 0.012), width: s * 0.04, height: s * 0.03), 0.2, math.pi - 0.4, false, Paint()
          ..color = AppColors.latar
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.008);
      default:
        break;
    }
  }

  void _paintFrontAccessories(Canvas canvas) {
    for (final a in accessories) {
      switch (a.slot) {
        case AccessorySlot.head:
          _paintHead(canvas, a);
        case AccessorySlot.face:
          _paintFaceItem(canvas, a);
        case AccessorySlot.neck:
          _paintNeck(canvas, a);
        case AccessorySlot.back:
          break;
      }
    }
  }

  void _paintHead(Canvas canvas, CharacterAccessory a) {
    final s = _s, cx = _cx, top = _bodyTop, w = _bodyW;
    switch (a) {
      case CharacterAccessory.beanie:
        final dome = Rect.fromCenter(center: Offset(cx, top + s * 0.03), width: w * 0.86, height: s * 0.26);
        canvas.drawArc(dome, math.pi, math.pi, true, Paint()..color = AppColors.primer);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, top + s * 0.03), width: w * 0.88, height: s * 0.05), Radius.circular(s * 0.025)),
          Paint()..color = AppColors.teksUtama.withValues(alpha: 0.85),
        );
        canvas.drawCircle(Offset(cx, top - s * 0.11), s * 0.035, Paint()..color = AppColors.teksUtama);
      case CharacterAccessory.ribbon:
        final c = Offset(cx - w * 0.26, top + s * 0.01);
        final paint = Paint()..color = AppColors.error;
        canvas.drawPath(Path()..moveTo(c.dx, c.dy)..lineTo(c.dx - s * 0.08, c.dy - s * 0.05)..lineTo(c.dx - s * 0.08, c.dy + s * 0.05)..close(), paint);
        canvas.drawPath(Path()..moveTo(c.dx, c.dy)..lineTo(c.dx + s * 0.08, c.dy - s * 0.05)..lineTo(c.dx + s * 0.08, c.dy + s * 0.05)..close(), paint);
        canvas.drawCircle(c, s * 0.022, Paint()..color = AppColors.latar.withValues(alpha: 0.35));
      case CharacterAccessory.flower:
        final c = Offset(cx + w * 0.26, top + s * 0.02);
        for (var i = 0; i < 5; i++) {
          final ang = i * 2 * math.pi / 5;
          canvas.drawCircle(c + Offset(math.cos(ang), math.sin(ang)) * s * 0.035, s * 0.028, Paint()..color = AppColors.monsterCermin);
        }
        canvas.drawCircle(c, s * 0.026, Paint()..color = AppColors.peringatan);
      case CharacterAccessory.witchHat:
        final brim = Rect.fromCenter(center: Offset(cx, top + s * 0.02), width: w * 1.0, height: s * 0.06);
        canvas.drawPath(
          Path()..moveTo(cx - w * 0.28, top + s * 0.01)..lineTo(cx + s * 0.02, top - s * 0.24)..lineTo(cx + w * 0.28, top + s * 0.01)..close(),
          Paint()..color = AppColors.monsterHakim,
        );
        canvas.drawOval(brim, Paint()..color = AppColors.monsterHakim);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, top - s * 0.02), width: w * 0.5, height: s * 0.035), Paint()..color = AppColors.peringatan);
      case CharacterAccessory.headphones:
        final band = Paint()
          ..color = AppColors.latar
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.03
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCenter(center: Offset(cx, _eyeY), width: w * 1.04, height: w * 1.1), math.pi * 1.08, math.pi * 0.84, false, band);
        for (final side in [-1.0, 1.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + side * w * 0.52, _eyeY + s * 0.02), width: s * 0.07, height: s * 0.14), Radius.circular(s * 0.03)),
            Paint()..color = AppColors.sekunder,
          );
        }
      case CharacterAccessory.halo:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, top - s * 0.07), width: w * 0.6, height: s * 0.07),
          Paint()
            ..color = AppColors.peringatan
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.022,
        );
      case CharacterAccessory.jungCrown:
        // Mahkota rune: lingkaran tipis dengan tiga berlian melayang.
        canvas.drawArc(Rect.fromCenter(center: Offset(cx, top - s * 0.02), width: w * 0.8, height: s * 0.1), math.pi, math.pi, false, Paint()
          ..color = AppColors.monsterCermin
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.016);
        for (final dx in [-w * 0.26, 0.0, w * 0.26]) {
          final c = Offset(cx + dx, top - s * (dx == 0 ? 0.11 : 0.085));
          canvas.drawPath(
            Path()..moveTo(c.dx, c.dy - s * 0.035)..lineTo(c.dx + s * 0.025, c.dy)..lineTo(c.dx, c.dy + s * 0.035)..lineTo(c.dx - s * 0.025, c.dy)..close(),
            Paint()..color = AppColors.peringatan,
          );
        }
      case CharacterAccessory.tempFlame:
        final base = Offset(cx, top + s * 0.005);
        final flame = Path()
          ..moveTo(base.dx - s * 0.05, base.dy)
          ..quadraticBezierTo(base.dx - s * 0.07, base.dy - s * 0.09, base.dx, base.dy - s * 0.17)
          ..quadraticBezierTo(base.dx + s * 0.07, base.dy - s * 0.09, base.dx + s * 0.05, base.dy)
          ..close();
        canvas.drawPath(flame, Paint()..color = AppColors.aksenHangat);
        canvas.drawPath(
          Path()
            ..moveTo(base.dx - s * 0.025, base.dy)
            ..quadraticBezierTo(base.dx - s * 0.03, base.dy - s * 0.05, base.dx, base.dy - s * 0.09)
            ..quadraticBezierTo(base.dx + s * 0.03, base.dy - s * 0.05, base.dx + s * 0.025, base.dy)
            ..close(),
          Paint()..color = AppColors.peringatan,
        );
      case CharacterAccessory.attNightCap:
        // Topi tidur: kerucut melengkung dengan bintang dan pompom.
        canvas.drawPath(
          Path()
            ..moveTo(cx - w * 0.36, top + s * 0.02)
            ..quadraticBezierTo(cx - w * 0.1, top - s * 0.2, cx + w * 0.42, top - s * 0.11)
            ..quadraticBezierTo(cx + w * 0.2, top - s * 0.02, cx + w * 0.36, top + s * 0.02)
            ..close(),
          Paint()..color = AppColors.monsterMeronta,
        );
        canvas.drawCircle(Offset(cx + w * 0.42, top - s * 0.11), s * 0.032, Paint()..color = AppColors.teksUtama);
        _star(canvas, Offset(cx - w * 0.02, top - s * 0.07), s * 0.022, AppColors.peringatan);
      default:
        break;
    }
  }

  void _paintFaceItem(Canvas canvas, CharacterAccessory a) {
    final s = _s, cx = _cx, eyeY = _eyeY, dx = _eyeDx, r = _eyeR;
    switch (a) {
      case CharacterAccessory.roundGlasses:
        final frame = Paint()
          ..color = AppColors.aksenHangat
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.018;
        for (final side in [-1.0, 1.0]) {
          canvas.drawCircle(Offset(cx + side * dx, eyeY), r * 1.55, frame);
        }
        canvas.drawLine(Offset(cx - dx + r * 1.55, eyeY), Offset(cx + dx - r * 1.55, eyeY), frame);
      case CharacterAccessory.sunglasses:
        final lens = Paint()..color = AppColors.latar;
        for (final side in [-1.0, 1.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + side * dx, eyeY), width: r * 3.0, height: r * 2.2), Radius.circular(r * 0.7)),
            lens,
          );
        }
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, eyeY), width: dx * 2 - r * 3.0, height: s * 0.014), lens);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx - dx - r * 0.5, eyeY - r * 0.4), width: r * 0.8, height: r * 0.4), Paint()..color = AppColors.teksUtama.withValues(alpha: 0.35));
      case CharacterAccessory.starStickers:
        for (final side in [-1.0, 1.0]) {
          _star(canvas, Offset(cx + side * dx * 1.5, eyeY + r * 2.0), s * 0.03, AppColors.peringatan);
        }
      case CharacterAccessory.jungMask:
        // Topeng persona: pita domino di atas kedua mata.
        final band = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, eyeY), width: dx * 2 + r * 4.4, height: r * 3.0), Radius.circular(r * 1.4));
        canvas.drawRRect(band, Paint()..color = AppColors.latar.withValues(alpha: 0.9));
        for (final side in [-1.0, 1.0]) {
          canvas.drawCircle(Offset(cx + side * dx, eyeY), r * 1.15, Paint()..color = AppColors.teksUtama);
          canvas.drawCircle(Offset(cx + side * dx, eyeY + r * 0.1), r * 0.6, Paint()..color = AppColors.latar);
        }
      case CharacterAccessory.tempMonocle:
        final ring = Paint()
          ..color = AppColors.peringatan
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.016;
        canvas.drawCircle(Offset(cx + dx, eyeY), r * 1.6, ring);
        canvas.drawLine(Offset(cx + dx + r * 1.1, eyeY + r * 1.2), Offset(cx + dx + r * 1.6, eyeY + r * 4.5), ring);
      case CharacterAccessory.attHeartCharm:
        for (final p in [Offset(cx - dx * 1.9, eyeY - r * 1.6), Offset(cx + dx * 1.9, eyeY - r * 2.2), Offset(cx + dx * 2.2, eyeY + r * 0.6)]) {
          _heart(canvas, p, s * 0.022, AppColors.error.withValues(alpha: 0.85));
        }
      default:
        break;
    }
  }

  void _paintNeck(Canvas canvas, CharacterAccessory a) {
    final s = _s, cx = _cx, top = _bodyTop, w = _bodyW, h = _bodyH;
    final y = top + h * 0.7;
    switch (a) {
      case CharacterAccessory.scarf:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, y), width: w * 0.92, height: s * 0.075), Radius.circular(s * 0.035)),
          Paint()..color = AppColors.error,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(cx + w * 0.16, y, s * 0.07, s * 0.15), Radius.circular(s * 0.025)),
          Paint()..color = AppColors.error.withValues(alpha: 0.9),
        );
        canvas.drawRect(Rect.fromLTWH(cx + w * 0.16, y + s * 0.09, s * 0.07, s * 0.015), Paint()..color = AppColors.teksUtama.withValues(alpha: 0.7));
      case CharacterAccessory.necklace:
        final bead = Paint()..color = AppColors.peringatan;
        for (var i = -4; i <= 4; i++) {
          final t = i / 4;
          canvas.drawCircle(Offset(cx + t * w * 0.34, y - s * 0.02 + (1 - t * t) * s * 0.06), s * 0.014, bead);
        }
        _star(canvas, Offset(cx, y + s * 0.06), s * 0.03, AppColors.peringatan);
      case CharacterAccessory.jungCompass:
        final string = Paint()
          ..color = AppColors.teksSekunder
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012;
        canvas.drawArc(Rect.fromCenter(center: Offset(cx, y - s * 0.08), width: w * 0.62, height: s * 0.2), 0.15, math.pi - 0.3, false, string);
        final c = Offset(cx, y + s * 0.06);
        canvas.drawCircle(c, s * 0.045, Paint()..color = AppColors.peringatan);
        canvas.drawCircle(c, s * 0.034, Paint()..color = AppColors.latar);
        canvas.drawPath(Path()..moveTo(c.dx, c.dy - s * 0.03)..lineTo(c.dx + s * 0.012, c.dy)..lineTo(c.dx - s * 0.012, c.dy)..close(), Paint()..color = AppColors.error);
      case CharacterAccessory.tempLeaf:
        for (var i = -2; i <= 2; i++) {
          canvas.save();
          canvas.translate(cx + i * w * 0.17, y - (i.abs() == 2 ? s * 0.0 : s * 0.02));
          canvas.rotate(i * 0.35);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.09, height: s * 0.05), Paint()..color = (i.isEven ? AppColors.sukses : AppColors.sekunder));
          canvas.restore();
        }
      case CharacterAccessory.attBlanket:
        // Selimut rasa aman: pita lebar bercorak zig-zag dengan rumbai.
        final blanket = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, y), width: w * 1.0, height: s * 0.13), Radius.circular(s * 0.03));
        canvas.drawRRect(blanket, Paint()..color = AppColors.aksenHangat);
        final zig = Path()..moveTo(cx - w * 0.44, y);
        for (var k = 0; k < 8; k++) {
          zig.lineTo(cx - w * 0.44 + (k + 0.5) * w * 0.11, y + (k.isEven ? -s * 0.03 : s * 0.03));
        }
        canvas.drawPath(zig, Paint()
          ..color = AppColors.latar.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012);
        for (var k = 0; k < 6; k++) {
          canvas.drawLine(Offset(cx - w * 0.4 + k * w * 0.16, y + s * 0.065), Offset(cx - w * 0.4 + k * w * 0.16, y + s * 0.095), Paint()
            ..color = AppColors.aksenHangat
            ..strokeWidth = s * 0.01
            ..strokeCap = StrokeCap.round);
        }
      default:
        break;
    }
  }

  void _heart(Canvas canvas, Offset c, double r, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy + r)
      ..cubicTo(c.dx - r * 2, c.dy - r * 0.2, c.dx - r * 0.8, c.dy - r * 1.4, c.dx, c.dy - r * 0.4)
      ..cubicTo(c.dx + r * 0.8, c.dy - r * 1.4, c.dx + r * 2, c.dy - r * 0.2, c.dx, c.dy + r);
    canvas.drawPath(path, Paint()..color = color);
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(c.dx + radius * math.cos(angle), c.dy + radius * math.sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) => true;
}
