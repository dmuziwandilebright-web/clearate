import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<File> capturePngFromBoundary({
    required RenderRepaintBoundary boundary,
    required String fileNameBase,
  }) async {
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Could not capture share image.');
    }

    ui.Image? watermark;
    try {
      final bytes = await rootBundle.load(
        'clearate_brand_assets/clearate_logo/screen.png',
      );
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      watermark = frame.image;
    } catch (_) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileNameBase.png');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      return file;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = ui.FilterQuality.high;

    canvas.drawImage(image, Offset.zero, paint);

    if (watermark != null) {
      final margin = 24.0;
      final targetWidth = image.width * 0.28;
      final aspect = watermark.width / watermark.height;
      final targetHeight = targetWidth / aspect;
      final dx = image.width - targetWidth - margin;
      final dy = image.height - targetHeight - margin;

      canvas.drawImageRect(
        watermark,
        Rect.fromLTWH(
          0,
          0,
          watermark.width.toDouble(),
          watermark.height.toDouble(),
        ),
        Rect.fromLTWH(dx, dy, targetWidth, targetHeight),
        paint,
      );
    }

    final picture = recorder.endRecording();
    if (picture == null) {
      throw StateError('Could not record picture.');
    }
    final composed = await picture.toImage(image.width, image.height);
    final composedBytes = await composed.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (composedBytes == null) {
      throw StateError('Could not produce share image.');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileNameBase.png');
    await file.writeAsBytes(composedBytes.buffer.asUint8List(), flush: true);
    return file;
  }

  Future<void> sharePngFromBoundary({
    required RenderRepaintBoundary boundary,
    required String fileNameBase,
    String? text,
  }) async {
    final file = await capturePngFromBoundary(
      boundary: boundary,
      fileNameBase: fileNameBase,
    );

    try {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: text,
      );
    } catch (_) {
      await Share.share(text ?? 'Clearate share image saved at ${file.path}');
    }
  }

  Future<void> shareText(String text) async {
    try {
      await Share.share(text);
    } catch (_) {}
  }
}
