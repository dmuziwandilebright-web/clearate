import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
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

    final bytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileNameBase.png');
    await file.writeAsBytes(bytes, flush: true);
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
    } on UnimplementedError {
      await Share.share(text ?? 'Clearate share image saved at ${file.path}');
    }
  }

  Future<void> shareText(String text) async {
    await Share.share(text);
  }
}
