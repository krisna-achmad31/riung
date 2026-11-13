import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Render widget (dibungkus `RepaintBoundary` ber-[GlobalKey]) jadi PNG, lalu
/// simpan ke galeri atau bagikan lewat share sheet native. Dipakai kartu
/// afirmasi & kartu pemain. Bingkai Story menampung kartu tanpa memotongnya.
abstract final class CardImageExporter {
  /// Kembalikan null kalau widget belum ter-render.
  static Future<Uint8List?> capture(
    GlobalKey boundaryKey, {
    double pixelRatio = 3,
    ui.Color? storyBackground,
  }) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final output = storyBackground == null
          ? image
          : await _frameStory(image, storyBackground);
      try {
        final bytes = await output.toByteData(format: ui.ImageByteFormat.png);
        return bytes?.buffer.asUint8List();
      } finally {
        if (!identical(output, image)) output.dispose();
      }
    } finally {
      image.dispose();
    }
  }

  static Future<ui.Image> _frameStory(
    ui.Image card,
    ui.Color background,
  ) async {
    const size = ui.Size(1080, 1920);
    const safeSize = ui.Size(888, 1280);
    final source = ui.Size(card.width.toDouble(), card.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, source, safeSize);
    final destination = Alignment.center.inscribe(
      fitted.destination,
      ui.Offset.zero & size,
    );
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..drawColor(background, ui.BlendMode.src)
      ..drawImageRect(
        card,
        ui.Offset.zero & source,
        destination,
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(size.width.toInt(), size.height.toInt());
    } finally {
      picture.dispose();
    }
  }

  static Future<void> saveToGallery(
    Uint8List png, {
    required String namePrefix,
  }) {
    return Gal.putImageBytes(
      png,
      name: '${namePrefix}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static Future<void> share(
    Uint8List png, {
    required String namePrefix,
    String? text,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${namePrefix}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(png);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text),
    );
  }
}
