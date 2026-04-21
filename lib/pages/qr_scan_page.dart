// lib/pages/qr_scan_page.dart
// Web-compatible QR scan page - uses manual entry on web, camera on mobile

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/qr_service.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _isProcessing = false;
  final TextEditingController _manualController = TextEditingController();
  final List<Map<String, dynamic>> _recentScans = [];

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  // ------------------------- PROCESS QR CODE -------------------------
  Future<void> _processCode(String code) async {
    if (code.trim().isEmpty) {
      _showSnackBar('Please enter a valid code', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await QrService.processScannedQr(code.trim());

      if (mounted) {
        setState(() {
          _recentScans.insert(0, result);
          if (_recentScans.length > 10) _recentScans.removeLast();
        });
        _showResultDialog(result);
      }
    } catch (e) {
      _showSnackBar('Error processing code: ${e.toString()}', isError: true);
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  // ------------------------- SHOW RESULT DIALOG -------------------------
  void _showResultDialog(Map<String, dynamic> result) {
    final isSuccess = result['success'] == true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isSuccess ? 'Success' : 'Error', style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result['message'] ?? result['error'] ?? 'Unknown result', style: const TextStyle(color: Colors.white)),
            if (result['markedAt'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Marked at: ${_formatTime(result['markedAt'])}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _manualController.clear();
            },
            child: const Text('Scan Another', style: TextStyle(color: Color(0xFFB8A9C9))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ------------------------- FORMAT TIME -------------------------
  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Scan Attendance', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF9D4EDD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9D4EDD).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF9D4EDD)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kIsWeb
                          ? 'Enter the attendee code manually to mark attendance.'
                          : 'Enter the attendee code or use the camera to scan QR codes.',
                      style: TextStyle(color: Color(0xFFB8A9C9)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Manual entry section
            const Text(
              'Enter Attendee Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'User ID or Event Code',
                hintStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF9D4EDD)),
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
                onPressed: _isProcessing
                    ? null
                    : () => _processCode(_manualController.text),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, color: Colors.white),
                label: Text(_isProcessing ? 'Processing...' : 'Mark Attendance', style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Quick codes section
            const SizedBox(height: 32),
            const Text(
              'Quick Test Codes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickCodeChip('U001'),
                _buildQuickCodeChip('U002'),
                _buildQuickCodeChip('U003'),
                _buildQuickCodeChip('EVENT-001'),
              ],
            ),

            // Recent scans
            if (_recentScans.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Recent Scans',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                      leading: Icon(
                        scan['success'] == true
                            ? Icons.check_circle
                            : Icons.error,
                        color: scan['success'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text(
                        scan['message'] ?? scan['error'] ?? 'Unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: scan['markedAt'] != null
                          ? Text(_formatTime(scan['markedAt']), style: const TextStyle(color: Color(0xFFB8A9C9)))
                          : null,
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // ------------------------- BUILD QUICK CODE CHIP -------------------------
  Widget _buildQuickCodeChip(String code) {
    return ActionChip(
      label: Text(code, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1E1B2E),
      side: const BorderSide(color: Color(0xFF3D3557)),
      onPressed: _isProcessing ? null : () => _processCode(code),
      avatar: const Icon(Icons.qr_code, size: 18, color: Color(0xFF9D4EDD)),
    );
  }
}
