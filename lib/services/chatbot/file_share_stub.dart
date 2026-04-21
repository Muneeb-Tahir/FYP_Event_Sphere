// lib/services/chatbot/file_share_stub.dart
// Stub for web platform (not used on web)

import 'dart:typed_data';

Future<bool> shareFileNative(Uint8List bytes, String filename) async {
  // No-op on web
  return false;
}

Future<bool> shareMultipleFilesNative(
  Uint8List file1Bytes, String file1Name,
  Uint8List? file2Bytes, String? file2Name,
) async {
  // No-op on web
  return false;
}
