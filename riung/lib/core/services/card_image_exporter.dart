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
/// afirmasi & kartu pemain — hasil simpan/bagikan selalu persis yang
/// terlihat di layar (bukan gambar yang di-generate terpisah).
abstract final class CardImageExporter {
  /// Kembalikan null kalau widget belum ter-render.
  static Future<Uint8List?> capture(GlobalKey boundaryKey, {double pixelRatio = 3}) async {
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static Future<void> saveToGallery(Uint8List png, {required String namePrefix}) {
    return Gal.putImageBytes(png, name: '${namePrefix}_${DateTime.now().millisecondsSinceEpoch}');
  }

  static Future<void> share(Uint8List png, {required String namePrefix, String? text}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${namePrefix}_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(png);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: text));
  }
}
