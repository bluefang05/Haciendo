import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as img;

import '../models/app_settings.dart';

class ProcessedImagePaths {
  const ProcessedImagePaths({
    required this.displayPath,
    required this.thumbnailPath,
  });

  final String displayPath;
  final String thumbnailPath;
}

class ImageProcessingService {
  const ImageProcessingService();

  Future<ProcessedImagePaths> process({
    required String originalPath,
    required String displayPath,
    required String thumbnailPath,
    required StoragePreference preference,
  }) async {
    return Isolate.run(() {
      final sourceBytes = File(originalPath).readAsBytesSync();
      final rawDecoded = img.decodeImage(sourceBytes);
      if (rawDecoded == null) {
        File(originalPath).copySync(displayPath);
        File(originalPath).copySync(thumbnailPath);
        return ProcessedImagePaths(
          displayPath: displayPath,
          thumbnailPath: thumbnailPath,
        );
      }
      final decoded = img.bakeOrientation(rawDecoded);

      final displayMax = switch (preference) {
        StoragePreference.original => 0,
        StoragePreference.highQuality => 2400,
        StoragePreference.saveSpace => 1600,
      };
      final quality = switch (preference) {
        StoragePreference.original => 95,
        StoragePreference.highQuality => 88,
        StoragePreference.saveSpace => 76,
      };

      final resized = displayMax > 0 &&
              (decoded.width > displayMax || decoded.height > displayMax)
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? displayMax : null,
              height: decoded.height > decoded.width ? displayMax : null,
              interpolation: img.Interpolation.average,
            )
          : decoded;
      File(displayPath).writeAsBytesSync(
        img.encodeJpg(resized, quality: quality),
      );

      final thumbnail = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? 480 : null,
        height: decoded.height > decoded.width ? 480 : null,
        interpolation: img.Interpolation.average,
      );
      File(thumbnailPath).writeAsBytesSync(img.encodeJpg(thumbnail, quality: 75));

      return ProcessedImagePaths(
        displayPath: displayPath,
        thumbnailPath: thumbnailPath,
      );
    });
  }
}
