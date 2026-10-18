// Renders the OneBus logo into every platform icon.
// Run with: flutter test tool/generate_icons_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebus/widgets/onebus_logo.dart';

Future<void> _render(
  String path,
  int px, {
  bool square = false,
  double contentScale = 1,
}) async {
  final recorder = ui.PictureRecorder();
  OneBusLogoPainter(
    square: square,
    contentScale: contentScale,
  ).paint(Canvas(recorder), Size.square(px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('generate icons', () async {
    await _render('web/favicon.png', 64);
    await _render('web/icons/Icon-192.png', 192);
    await _render('web/icons/Icon-512.png', 512);
    await _render(
      'web/icons/Icon-maskable-192.png',
      192,
      square: true,
      contentScale: 0.78,
    );
    await _render(
      'web/icons/Icon-maskable-512.png',
      512,
      square: true,
      contentScale: 0.78,
    );

    const android = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final e in android.entries) {
      await _render(
        'android/app/src/main/res/mipmap-${e.key}/ic_launcher.png',
        e.value,
      );
    }

    final ios = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    for (final f in ios.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.png'),
    )) {
      final m = RegExp(r'(\d+(?:\.\d+)?)x\1@(\d)x').firstMatch(f.path)!;
      final px = (double.parse(m[1]!) * int.parse(m[2]!)).round();
      await _render(f.path, px, square: true);
    }
  });
}
