// lib/pages/qr_scan_page.dart
// QR Scanner with camera support on mobile + manual entry fallback

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_service.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _isProcessing = false;
  bool _showManualEntry = kIsWeb; // Start with camera on mobile, manual on web
  final TextEditingController _manualController = TextEditingController();
  final List<Map<String, dynamic>> _recentScans = [];
  MobileScannerController? _cameraController;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ------------------------- PROCESS QR CODE -------------------------
  Future<void> _processCode(String code) async {
    if (code.trim().isEmpty) {
      _showSnackBar('Please enter a valid code', isError: true);
      return;
    }
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Pause camera while processing
    _cameraController?.stop();

    try {
      final result = await QrService.markAttendance(code.trim());
      if (mounted) {
        setState(() {
          _recentScans.insert(0, {...result, 'scannedAt': DateTime.now()});
          if (_recentScans.length > 10) _recentScans.removeLast();
        });
        _showResultDialog(result);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
      // Resume camera after error
      _cameraController?.start();
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  // ------------------------- RESULT DIALOG -------------------------
  void _showResultDialog(Map<String, dynamic> result) {
    final isSuccess = result['success'] == true;
    final userName = result['userName'] as String? ?? '';
    final eventTitle = result['eventTitle'] as String? ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isSuccess ? 'Check-in Success' : 'Check-in Failed',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result['message'] ?? 'Unknown result',
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (userName.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(Icons.person, 'Attendee', userName),
            ],
            if (eventTitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.event, 'Event', eventTitle),
            ],
            if (result['checkedInAt'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, 'Time', _formatDateTime(DateTime.now())),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _manualController.clear();
              _cameraController?.start(); // Resume camera
            },
            child: const Text('Scan Another', style: TextStyle(color: Color(0xFFB8A9C9))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9D4EDD),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFB8A9C9)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 13)),
        Expanded(
          child: Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')} • ${time.day}/${time.month}/${time.year}';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ------------------------- BUILD -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Scan Attendance', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: Icon(
                _showManualEntry ? Icons.camera_alt : Icons.keyboard,
                color: Colors.white,
              ),
              tooltip: _showManualEntry ? 'Use Camera' : 'Manual Entry',
              onPressed: () => setState(() => _showManualEntry = !_showManualEntry),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode toggle (mobile only)
            if (!kIsWeb) ...[
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showManualEntry = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showManualEntry
                              ? const Color(0xFF9D4EDD).withOpacity(0.2)
                              : const Color(0xFF1E1B2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_showManualEntry
                                ? const Color(0xFF9D4EDD)
                                : const Color(0xFF3D3557),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                color: !_showManualEntry ? const Color(0xFF9D4EDD) : const Color(0xFFB8A9C9),
                                size: 20),
                            const SizedBox(width: 8),
                            Text('Camera',
                                style: TextStyle(
                                  color: !_showManualEntry ? const Color(0xFF9D4EDD) : const Color(0xFFB8A9C9),
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showManualEntry = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showManualEntry
                              ? const Color(0xFF9D4EDD).withOpacity(0.2)
                              : const Color(0xFF1E1B2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _showManualEntry
                                ? const Color(0xFF9D4EDD)
                                : const Color(0xFF3D3557),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.keyboard,
                                color: _showManualEntry ? const Color(0xFF9D4EDD) : const Color(0xFFB8A9C9),
                                size: 20),
                            const SizedBox(width: 8),
                            Text('Manual',
                                style: TextStyle(
                                  color: _showManualEntry ? const Color(0xFF9D4EDD) : const Color(0xFFB8A9C9),
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Camera scanner (mobile only, when not in manual mode)
            if (!kIsWeb && !_showManualEntry) ...[
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF9D4EDD).withOpacity(0.5), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _cameraController!,
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null && !_isProcessing) {
                              _processCode(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                      ),
                      // Scan overlay
                      Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF9D4EDD), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      // Processing overlay
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Color(0xFF9D4EDD)),
                                SizedBox(height: 16),
                                Text('Validating...', style: TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Point camera at attendee\'s QR code',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Manual entry section
            if (_showManualEntry) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF9D4EDD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF9D4EDD).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF9D4EDD)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        kIsWeb
                            ? 'Paste the attendee\'s QR code data below to mark attendance.'
                            : 'Paste the QR code data to mark attendance manually.',
                        style: const TextStyle(color: Color(0xFFB8A9C9)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _manualController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 4,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: 'Paste the base64-encoded QR code data here...',
                  hintStyle: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 13),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.qr_code_2, color: Color(0xFF9D4EDD)),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3D3557)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3D3557)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9D4EDD)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1B2E),
                ),
                onSubmitted: _isProcessing ? null : (value) => _processCode(value),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _processCode(_manualController.text),
                  icon: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle, color: Colors.white),
                  label: Text(
                    _isProcessing ? 'Validating...' : 'Verify & Mark Attendance',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            // Security badge
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3D3557)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto-validates: Registration • Duplicate check-in • QR expiry • HMAC signature',
                      style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            // Recent scans
            if (_recentScans.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Scans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D4EDD).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_recentScans.where((s) => s['success'] == true).length} checked in',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9D4EDD)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._recentScans.take(5).map((scan) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (scan['success'] == true ? Colors.green : Colors.red).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      scan['success'] == true ? Icons.check_circle : Icons.error,
                      color: scan['success'] == true ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    scan['userName']?.toString().isNotEmpty == true
                        ? scan['userName'].toString()
                        : (scan['message'] ?? 'Unknown'),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    scan['message'] ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 12),
                  ),
                  trailing: scan['scannedAt'] != null
                      ? Text(
                          '${(scan['scannedAt'] as DateTime).hour}:${(scan['scannedAt'] as DateTime).minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 11),
                        )
                      : null,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
