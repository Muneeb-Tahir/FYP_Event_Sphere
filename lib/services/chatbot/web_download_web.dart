// lib/services/chatbot/web_download_web.dart
// Web-specific implementation for file download

import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileWeb(Uint8List bytes, String filename) {
  // Detect MIME type based on file extension
  String mimeType = 'application/octet-stream';
  if (filename.toLowerCase().endsWith('.pdf')) {
    mimeType = 'application/pdf';
  } else if (filename.toLowerCase().endsWith('.zip')) {
    mimeType = 'application/zip';
  } else if (filename.toLowerCase().endsWith('.png')) {
    mimeType = 'image/png';
  } else if (filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')) {
    mimeType = 'image/jpeg';
  }

  // Create a Blob from the bytes with correct MIME type
  final blob = html.Blob([bytes], mimeType);

  // Create an object URL
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Create an anchor element and trigger download
  final anchor = html.AnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();

  // Cleanup
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
