import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/services/card_image_exporter.dart';

void main() {
  testWidgets('Story export keeps both edges of the card inside the canvas', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 360,
            height: 520,
            child: Row(
              textDirection: TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: ColoredBox(color: Colors.red)),
                Expanded(child: ColoredBox(color: Colors.blue)),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      final png = await CardImageExporter.capture(
        key,
        storyBackground: Colors.white,
      );
      final codec = await ui.instantiateImageCodec(png!);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        expect((image.width, image.height), (1080, 1920));
        final pixels = (await image.toByteData())!;
        int pixel(int x, int y) => pixels.getUint32((y * image.width + x) * 4);
        expect(pixel(50, 960), 0xffffffff);
        expect(pixel(1030, 960), 0xffffffff);
        expect(pixel(105, 960), 0xf44336ff);
        expect(pixel(975, 960), 0x2196f3ff);
        expect(pixel(540, 250), 0xffffffff);
        expect(pixel(540, 1670), 0xffffffff);
      } finally {
        image.dispose();
        codec.dispose();
      }
    });
  });
}
