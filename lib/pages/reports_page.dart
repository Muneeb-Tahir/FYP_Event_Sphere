// lib/pages/reports_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/report_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<EventReport> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  // ------------------------- LOAD REPORTS -------------------------
  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ReportService.getEventReports(),
        ReportService.getDashboardStats(),
      ]);

      if (mounted) {
        setState(() {
          _reports = results[0] as List<EventReport>;
          // DashboardStats available as results[1] if needed
          _isLoading = false;
        });
      }
    } catch (e) {
      _handleError('Failed to load reports: ${e.toString()}');
    }
  }

  // ------------------------- REFRESH REPORTS -------------------------
  Future<void> _refreshReports() async {
    await _loadReports();
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

  // ------------------------- EXPORT REPORT -------------------------
  Future<void> _exportReport() async {
    if (_reports.isEmpty) {
      _showSnackBar('No reports to export', isError: true);
      return;
    }

    try {
      // Generate CSV content
      final buffer = StringBuffer();
      buffer.writeln('Event Title,Date,Registrations,Attended,Rate');

      for (final r in _reports) {
        buffer.writeln('"${r.eventTitle}",${_formatDate(r.eventDate)},${r.totalRegistrations},${r.totalAttendees},${r.attendanceRate.toStringAsFixed(1)}%');
      }

      // Add totals
      final totals = _calculateTotals();
      buffer.writeln('');
      buffer.writeln('TOTAL,,${totals['total']},${totals['attended']},${(totals['rate'] as double).toStringAsFixed(1)}%');

      // Save to temp file
      final directory = await getTemporaryDirectory();
      final fileName = 'event_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Event Attendance Report',
      );

      _showSnackBar('Report exported successfully!');
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
    }
  }

  // ------------------------- CALCULATE TOTALS -------------------------
  Map<String, dynamic> _calculateTotals() {
    if (_reports.isEmpty) {
      return {'total': 0, 'attended': 0, 'rate': 0.0};
    }

    int totalReg = 0;
    int totalAtt = 0;
    for (final r in _reports) {
      totalReg += r.totalRegistrations;
      totalAtt += r.totalAttendees;
    }

    return {
      'total': totalReg,
      'attended': totalAtt,
      'rate': totalReg > 0 ? (totalAtt / totalReg) * 100 : 0.0,
    };
  }

  // ------------------------- FORMAT DATE -------------------------
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text('Event Reports', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _refreshReports,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReports,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final totals = _calculateTotals();

    return RefreshIndicator(
      onRefresh: _refreshReports,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800])),
            const SizedBox(height: 20),

            // Stats Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatCard('Total Registrations', '${totals['total']}', Colors.blue),
                _buildStatCard('Attended', '${totals['attended']}', Colors.green),
                _buildStatCard('Attendance Rate', '${(totals['rate'] as double).toStringAsFixed(1)}%', Colors.orange),
                _buildStatCard('No-Shows', '${totals['total'] - totals['attended']}', Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            Text('Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total participants for all events: ${totals['total']}',
                    style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text('Successfully attended: ${totals['attended']}',
                    style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text('Attendance rate: ${(totals['rate'] as double).toStringAsFixed(1)}%',
                    style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Event Reports List
            if (_reports.isNotEmpty) ...[
              Text('Event Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
              const SizedBox(height: 12),
              ...(_reports.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.eventTitle, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMiniStat('Registered', '${r.totalRegistrations}'),
                        const SizedBox(width: 16),
                        _buildMiniStat('Attended', '${r.totalAttendees}'),
                        const SizedBox(width: 16),
                        _buildMiniStat('Rate', '${r.attendanceRate.toStringAsFixed(1)}%'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Date: ${_formatDate(r.eventDate)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, MaterialColor color) {
    return Container(
      decoration: BoxDecoration(
        color: color[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[700]!, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color[700])),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: color[700]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
      ],
    );
  }
}