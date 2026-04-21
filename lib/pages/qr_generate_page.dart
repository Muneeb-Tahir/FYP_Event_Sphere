// lib/pages/qr_generate_page.dart

import 'dart:io';
import 'dart:ui' as ui;
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

      // Generate QR data
      final qrData = QrService.generateQrData(
        eventId: widget.eventId,
        userId: user.id,
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
      _qrData = QrService.generateQrData(
        eventId: widget.eventId,
        userId: user.id,
      );
    });

    _showSnackBar('QR code regenerated');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------- DOWNLOAD QR -------------------------
  Future<void> _downloadQr() async {
    try {
      final image = await _captureQrImage();
      if (image == null) {
        _showSnackBar('Failed to capture QR code', isError: true);
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'qr_${widget.eventId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(image);

      _showSnackBar('QR code saved to: $fileName');
    } catch (e) {
      _showSnackBar('Download failed: $e', isError: true);
    }
  }

  // ------------------------- SHARE QR -------------------------
  Future<void> _shareQr() async {
    try {
      final image = await _captureQrImage();
      if (image == null) {
        _showSnackBar('Failed to capture QR code', isError: true);
        return;
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/event_qr.png');
      await file.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My QR code for ${_event?.title ?? "event"}',
      );
    } catch (e) {
      _showSnackBar('Share failed: $e', isError: true);
    }
  }

  // ------------------------- CAPTURE QR IMAGE -------------------------
  Future<List<int>?> _captureQrImage() async {
    try {
      // Generate QR image directly from data
      final qrPainter = QrPainter(
        data: _qrData ?? widget.eventId,
        version: QrVersions.auto,
        gapless: true,
      );

      final image = await qrPainter.toImage(300);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
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

          // QR Code
          Container(
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
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Show this at the event entrance',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF9D4EDD)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _shareQr,
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text('Share', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

