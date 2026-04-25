// lib/utils/image_compressor.dart
// Image compression utility for reducing upload sizes

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../services/logging_service.dart';

class ImageCompressor {
  // Maximum dimensions for different use cases
  static const int thumbnailMaxSize = 200;
  static const int mediumMaxSize = 800;
  static const int largeMaxSize = 1200;

  // Quality settings (0-100)
  static const int thumbnailQuality = 70;
  static const int mediumQuality = 80;
  static const int largeQuality = 85;

  // Maximum file size in bytes (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// Compress an image for upload
  /// Returns compressed bytes or null if compression fails
  static Future<Uint8List?> compressForUpload(
    Uint8List imageBytes, {
    int maxWidth = 1200,
    int quality = 85,
  }) async {
    try {
      // Run compression in isolate for better performance
      return await compute(_compressImage, _CompressParams(
        bytes: imageBytes,
        maxWidth: maxWidth,
        quality: quality,
      ));
    } catch (e) {
      LoggingService.error('Image compression failed', e);
      return null;
    }
  }

  /// Create a thumbnail from image bytes
  static Future<Uint8List?> createThumbnail(Uint8List imageBytes) async {
    return compressForUpload(
      imageBytes,
      maxWidth: thumbnailMaxSize,
      quality: thumbnailQuality,
    );
  }

  /// Compress for medium display (event cards, galleries)
  static Future<Uint8List?> compressForMedium(Uint8List imageBytes) async {
    return compressForUpload(
      imageBytes,
      maxWidth: mediumMaxSize,
      quality: mediumQuality,
    );
  }

  /// Compress for large display (full screen view)
  static Future<Uint8List?> compressForLarge(Uint8List imageBytes) async {
    return compressForUpload(
      imageBytes,
      maxWidth: largeMaxSize,
      quality: largeQuality,
    );
  }

  /// Check if image needs compression
  static bool needsCompression(Uint8List imageBytes) {
    // Compress if larger than 500KB
    return imageBytes.length > 500 * 1024;
  }

  /// Validate image size before upload
  static String? validateImageSize(Uint8List imageBytes) {
    if (imageBytes.length > maxFileSizeBytes) {
      final sizeMB = (imageBytes.length / (1024 * 1024)).toStringAsFixed(1);
      return 'Image size ($sizeMB MB) exceeds maximum allowed (5 MB)';
    }
    return null;
  }

  /// Get estimated compressed size (rough estimate)
  static int estimateCompressedSize(int originalSize) {
    // Typical JPEG compression reduces size by 60-80%
    return (originalSize * 0.3).round();
  }
}

/// Parameters for compute isolate
class _CompressParams {
  final Uint8List bytes;
  final int maxWidth;
  final int quality;

  _CompressParams({
    required this.bytes,
    required this.maxWidth,
    required this.quality,
  });
}

/// Compression function that runs in isolate
Uint8List? _compressImage(_CompressParams params) {
  try {
    // Decode image
    final image = img.decodeImage(params.bytes);
    if (image == null) return null;

    // Calculate new dimensions while maintaining aspect ratio
    int newWidth = image.width;
    int newHeight = image.height;

    if (image.width > params.maxWidth) {
      newWidth = params.maxWidth;
      newHeight = (image.height * params.maxWidth / image.width).round();
    }

    // Resize if needed
    img.Image resized;
    if (newWidth != image.width) {
      resized = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    } else {
      resized = image;
    }

    // Encode as JPEG with specified quality
    final compressed = img.encodeJpg(resized, quality: params.quality);
    return Uint8List.fromList(compressed);
  } catch (e) {
    debugPrint('Compression error: $e'); // Cannot use LoggingService in isolate
    return null;
  }
}
