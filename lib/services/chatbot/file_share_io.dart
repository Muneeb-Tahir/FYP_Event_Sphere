// lib/services/chatbot/file_share_io.dart
// IO-specific implementation for file sharing (mobile/desktop)

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../logging_service.dart';

Future<bool> shareFileNative(Uint8List bytes, String filename) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');

    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Event Sphere - $filename',
      subject: 'Event Sphere Export',
    );

    return true;
  } catch (e) {
    LoggingService.error('Error sharing file', e);
    return false;
  }
}

/// Share multiple files together in a single share dialog
Future<bool> shareMultipleFilesNative(
  Uint8List file1Bytes, String file1Name,
  Uint8List? file2Bytes, String? file2Name,
) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final List<XFile> files = [];

    // Write first file
    final file1 = File('${tempDir.path}/$file1Name');
    await file1.writeAsBytes(file1Bytes);
    files.add(XFile(file1.path));

    // Write second file if provided
    if (file2Bytes != null && file2Name != null) {
      final file2 = File('${tempDir.path}/$file2Name');
      await file2.writeAsBytes(file2Bytes);
      files.add(XFile(file2.path));
    }

    await Share.shareXFiles(
      files,
      text: files.length > 1
          ? 'Event Sphere - ${files.length} files'
          : 'Event Sphere - $file1Name',
      subject: 'Event Sphere Export',
    );

    return true;
  } catch (e) {
    LoggingService.error('Error sharing multiple files', e);
    return false;
  }
}
