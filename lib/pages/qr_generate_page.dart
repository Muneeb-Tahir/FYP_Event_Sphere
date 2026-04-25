// lib/pages/qr_generate_page.dart
// Secure QR Code generation page with download & share support

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/qr_service.dart';
import '../services/event_service.dart';
import '../providers/auth_provider.dart';
import '../models/event.dart';

class QrGeneratePage extends ConsumerStatefulWidget {
  final String eventId;

  const QrGeneratePage({super.key, required this.eventId});

  @override
  ConsumerState<QrGeneratePage> createState() => _QrGeneratePageState();
}

class _QrGeneratePageState extends ConsumerState<QrGeneratePage> {
  String? _qrData;
  Event? _event;
  bool _isLoading = true;
  String? _error;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeQr();
  }

  // ------------------------- INITIALIZE QR -------------------------
  Future<void> _initializeQr() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Verify user is logged in
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('Please login to generate QR code');
      }

      // Load event details
      final event = await EventService.getEvent(widget.eventId);
      if (event == null) {
        throw Exception('Event not found');
      }

      // Generate secure QR data (JSON + base64 + HMAC)
      final qrData = QrService.generateQrCode(
        eventId: widget.eventId,
        userId: user.id,
        userName: user.name,
        eventTitle: event.title,
      );

      if (mounted) {
        setState(() {
          _event = event;
          _qrData = qrData;
          _isLoading = false;
        });
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  // ------------------------- REGENERATE QR -------------------------
  Future<void> _regenerateQr() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showSnackBar('Please login first', isError: true);
      return;
    }

    setState(() {
      _qrData = QrService.generateQrCode(
        eventId: widget.eventId,
        userId: user.id,
        userName: user.name,
        eventTitle: _event?.title ?? '',
      );
    });

    _showSnackBar('QR code regenerated with fresh timestamp');
  }

  // ------------------------- HANDLE ERROR -------------------------
  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _isLoading = false;
      });
    }
  }

  // ------------------------- SHOW SNACKBAR -------------------------
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------- CAPTURE QR AS IMAGE BYTES -------------------------
  Future<Uint8List?> _captureQrImage() async {
    try {
      // Use QrPainter to render QR to image bytes
      final qrPainter = QrPainter(
        data: _qrData ?? widget.eventId,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );

      final image = await qrPainter.toImage(600); // High resolution
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR image: $e');
      return null;
    }
  }

  // ------------------------- DOWNLOAD QR -------------------------
  Future<void> _downloadQr() async {
    try {
      final imageBytes = await _captureQrImage();
      if (imageBytes == null) {
        _showSnackBar('Failed to generate QR image', isError: true);
        return;
      }

      if (kIsWeb) {
        // Web: Use share/download via share_plus or trigger download
        _showSnackBar('On web, use the Share button to save the QR code');
        return;
      }

      // Mobile: Save to documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'EventSphere_QR_${_event?.title ?? widget.eventId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\-.]'), '_');
      final file = File('${directory.path}/$sanitizedName');
      await file.writeAsBytes(imageBytes);

      _showSnackBar('QR code saved: $sanitizedName');
    } catch (e) {
      _showSnackBar('Download failed: ${e.toString()}', isError: true);
    }
  }

  // ------------------------- SHARE QR -------------------------
  Future<void> _shareQr() async {
    try {
      final imageBytes = await _captureQrImage();
      if (imageBytes == null) {
        _showSnackBar('Failed to generate QR image', isError: true);
        return;
      }

      if (kIsWeb) {
        // Web: Share as XFile from bytes
        await Share.shareXFiles(
          [XFile.fromData(imageBytes, mimeType: 'image/png', name: 'event_qr.png')],
          text: 'My QR code for ${_event?.title ?? "event"}',
        );
      } else {
        // Mobile: Save to temp then share
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/event_qr.png');
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'My QR code for ${_event?.title ?? "event"}',
        );
      }
    } catch (e) {
      _showSnackBar('Share failed: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Event QR Code', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _regenerateQr,
            tooltip: 'Regenerate QR',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeQr,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Event info card
          if (_event != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _event!.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFFB8A9C9)),
                      const SizedBox(width: 4),
                      Text(
                        '${_event!.date.day}/${_event!.date.month}/${_event!.date.year}',
                        style: const TextStyle(color: Color(0xFFB8A9C9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFFB8A9C9)),
                      const SizedBox(width: 4),
                      Text(_event!.venue, style: const TextStyle(color: Color(0xFFB8A9C9))),
                    ],
                  ),
                ],
              ),
            ),

          // Security badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, size: 14, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  'HMAC Signed • Expires in 24h',
                  style: TextStyle(fontSize: 11, color: Colors.green),
                ),
              ],
            ),
          ),

          // QR Code
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9D4EDD).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: _qrData ?? widget.eventId,
                    version: QrVersions.auto,
                    size: 220.0,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H, // High error correction
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _event?.title ?? 'Event',
                    style: const TextStyle(
                      color: Color(0xFF1E1B2E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Show this at the event entrance',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadQr,
                  icon: const Icon(Icons.download, color: Color(0xFF9D4EDD)),
                  label: const Text('Download', style: TextStyle(color: Color(0xFF9D4EDD))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF9D4EDD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _shareQr,
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text('Share', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Regenerate button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _regenerateQr,
              icon: const Icon(Icons.refresh, color: Color(0xFFB8A9C9), size: 18),
              label: const Text('Regenerate QR Code', style: TextStyle(color: Color(0xFFB8A9C9))),
            ),
          ),
        ],
      ),
    );
  }
}
