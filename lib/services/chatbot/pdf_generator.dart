// lib/services/chatbot/pdf_generator.dart
// PDF Generation for Event Sphere Chatbot

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../resource_service.dart';
import '../logging_service.dart';

// Conditional imports for platform-specific functionality
import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart';
import 'file_share_stub.dart' if (dart.library.io) 'file_share_io.dart';

/// Generates and shares PDFs for events
class ChatPdfGenerator {

  /// Generate and share event list PDF
  static Future<bool> generateAndShareEventListPdf({
    required List<Event> events,
    required String title,
    String? subtitle,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(title, subtitle),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            ..._buildEventList(events, showStatus: true),
          ],
        ),
      );

      final bytes = await pdf.save();
      return await _shareFile(bytes, '${_sanitizeFilename(title)}.pdf');
    } catch (e) {
      return false;
    }
  }

  /// Generate and share user registrations PDF
  static Future<bool> generateAndShareRegistrationsPdf({
    required List<Event> events,
    required String userName,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(
            'My Registrations',
            'Generated for $userName',
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            ..._buildEventList(events, showStatus: true),
          ],
        ),
      );

      final bytes = await pdf.save();
      return await _shareFile(bytes, 'my_registrations.pdf');
    } catch (e) {
      return false;
    }
  }

  /// Generate weekly digest PDF
  static Future<bool> generateWeeklyDigestPdf({
    required List<Event> events,
    required String weekRange,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(
            'Weekly Digest',
            weekRange,
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            pw.Text(
              '${events.length} event(s) scheduled this week',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 16),
            ..._buildEventList(events, showStatus: true),
          ],
        ),
      );

      final bytes = await pdf.save();
      return await _shareFile(bytes, 'weekly_digest.pdf');
    } catch (e) {
      return false;
    }
  }

  /// Generate and share detailed event PDF (for past events)
  static Future<bool> generateEventDetailPdf({
    required Event event,
  }) async {
    try {
      final pdf = pw.Document();
      final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(event.date);
      final timeStr = DateFormat('h:mm a').format(event.date);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(
            event.title,
            event.isDeleted ? 'Archived Event' : 'Event Details',
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            // Event Status Badge
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: event.isDeleted ? PdfColors.orange100 : PdfColors.green100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                event.isDeleted ? '[ARCHIVED] Event' : '[ACTIVE] Event',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: event.isDeleted ? PdfColors.orange800 : PdfColors.green800,
                ),
              ),
            ),
            pw.SizedBox(height: 24),

            // Event Details Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _buildTableRow('Date', dateStr),
                _buildTableRow('Time', timeStr),
                _buildTableRow('Venue', event.venue),
                _buildTableRow('Category', event.category),
                _buildTableRow('Capacity', '${event.currentAttendees}/${event.maxAttendees ?? "Unlimited"} registered'),
                _buildTableRow('Status', event.isFull ? 'SOLD OUT' : 'Available'),
              ],
            ),
            pw.SizedBox(height: 24),

            // Description Section
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Description',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    event.description.isNotEmpty ? event.description : 'No description provided.',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      return await _shareFile(bytes, '${_sanitizeFilename(event.title)}_details.pdf');
    } catch (e) {
      return false;
    }
  }

  /// Generate and share event resources PDF
  static Future<bool> generateEventResourcesPdf({
    required Event event,
    required List<EventResource> resources,
  }) async {
    try {
      final pdf = pw.Document();

      // Pre-download images for embedding (only on native, skip on web due to CORS)
      final Map<String, Uint8List> imageCache = {};
      if (!kIsWeb) {
        for (final resource in resources) {
          final fileType = resource.fileType.toLowerCase();
          if (fileType == 'image' || fileType == 'jpg' || fileType == 'png' || fileType == 'jpeg') {
            try {
              final response = await http.get(Uri.parse(resource.fileUrl));
              if (response.statusCode == 200) {
                imageCache[resource.id] = response.bodyBytes;
                LoggingService.debug('Downloaded image: ${resource.title}');
              }
            } catch (e) {
              LoggingService.warning('Failed to download image ${resource.title}: $e');
            }
          }
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(
            '${event.title} - Resources',
            '${resources.length} resource(s) available',
          ),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            if (resources.isEmpty)
              pw.Center(
                child: pw.Text(
                  'No resources available for this event.',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                ),
              )
            else if (kIsWeb)
              // On web, use simple list without embedded images
              ..._buildResourceList(resources)
            else
              // On native, use list with embedded images
              ..._buildResourceListWithImages(resources, imageCache),
          ],
        ),
      );

      final bytes = await pdf.save();
      return await _shareFile(bytes, '${_sanitizeFilename(event.title)}_resources.pdf');
    } catch (e) {
      LoggingService.error('Error generating resources PDF', e);
      return false;
    }
  }

  /// Generate both event detail and resources PDFs (or ZIP for resources)
  static Future<Map<String, dynamic>> generatePastEventPdfs({
    required Event event,
    required List<EventResource> resources,
  }) async {
    try {
      LoggingService.info('Generating PDFs for: ${event.title}');

      // Generate details PDF first
      bool detailsSuccess = await generateEventDetailPdf(event: event);
      LoggingService.debug('Details PDF result: $detailsSuccess');

      // Generate resources - try PDF first, fall back to ZIP
      bool resourcesSuccess = true;
      String resourcesType = 'none';

      if (resources.isNotEmpty) {
        LoggingService.info('Generating resources for ${resources.length} items...');

        // Try PDF first
        resourcesSuccess = await generateEventResourcesPdf(
          event: event,
          resources: resources,
        );

        if (resourcesSuccess) {
          resourcesType = 'pdf';
          LoggingService.info('Resources PDF generated successfully');
        } else {
          // Fall back to ZIP
          LoggingService.debug('PDF failed, trying ZIP...');
          resourcesSuccess = await generateEventResourcesZip(
            event: event,
            resources: resources,
          );
          resourcesType = resourcesSuccess ? 'zip' : 'failed';
          LoggingService.debug('Resources ZIP result: $resourcesSuccess');
        }
      }

      return {
        'details': detailsSuccess,
        'resources': resourcesSuccess,
        'resourcesType': resourcesType,
      };
    } catch (e) {
      LoggingService.error('Error generating past event PDFs', e);
      return {'details': false, 'resources': false, 'resourcesType': 'failed'};
    }
  }

  /// Generate and share event resources as ZIP file
  static Future<bool> generateEventResourcesZip({
    required Event event,
    required List<EventResource> resources,
  }) async {
    try {
      LoggingService.info('Creating ZIP archive for resources...');
      final archive = Archive();
      int downloadedCount = 0;

      // Download and add each resource to the archive
      for (final resource in resources) {
        try {
          LoggingService.debug('Downloading: ${resource.title} from ${resource.fileUrl}');
          final response = await http.get(Uri.parse(resource.fileUrl));

          if (response.statusCode == 200) {
            // Get file extension from URL or fileType
            String extension = _getExtension(resource.fileUrl, resource.fileType);
            String filename = '${_sanitizeFilename(resource.title)}$extension';

            // Add file to archive
            archive.addFile(ArchiveFile(
              filename,
              response.bodyBytes.length,
              response.bodyBytes,
            ));
            downloadedCount++;
            LoggingService.debug('Added to ZIP: $filename');
          } else {
            LoggingService.warning('Failed to download ${resource.title}: Status ${response.statusCode}');
          }
        } catch (e) {
          LoggingService.error('Error downloading ${resource.title}', e);
        }
      }

      if (downloadedCount == 0) {
        LoggingService.warning('No resources could be downloaded');
        return false;
      }

      // Create a text file with resource info
      String infoContent = 'Event: ${event.title}\n';
      infoContent += 'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n';
      infoContent += 'Resources: $downloadedCount of ${resources.length}\n\n';
      for (final r in resources) {
        infoContent += '- ${r.title} (${r.fileType})\n';
        infoContent += '  URL: ${r.fileUrl}\n';
        if (r.description != null) infoContent += '  Description: ${r.description}\n';
        infoContent += '\n';
      }
      archive.addFile(ArchiveFile('_resources_info.txt', infoContent.length, infoContent.codeUnits));

      // Encode ZIP
      final zipBytes = ZipEncoder().encode(archive);

      // Share the ZIP file
      return await _shareFile(
        Uint8List.fromList(zipBytes),
        '${_sanitizeFilename(event.title)}_resources.zip'
      );
    } catch (e) {
      LoggingService.error('Error generating resources ZIP', e);
      return false;
    }
  }

  /// Get file extension from URL or fileType
  static String _getExtension(String url, String fileType) {
    // Try to get from URL
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        return path.substring(lastDot);
      }
    }

    // Fall back to fileType
    switch (fileType.toLowerCase()) {
      case 'image':
      case 'jpg':
      case 'jpeg':
        return '.jpg';
      case 'png':
        return '.png';
      case 'pdf':
        return '.pdf';
      case 'video':
        return '.mp4';
      default:
        return '.bin';
    }
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  static pw.Widget _buildHeader(String title, String? subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'EVENT SPHERE',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.blue700,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                DateFormat('MMM d, yyyy').format(DateTime.now()),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          if (subtitle != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Event Sphere',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildEventList(List<Event> events, {bool showStatus = false}) {
    if (events.isEmpty) {
      return [
        pw.Center(
          child: pw.Text(
            'No events found',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
          ),
        ),
      ];
    }

    final now = DateTime.now();

    return events.map((event) {
      final dateStr = DateFormat('EEEE, MMM d, yyyy').format(event.date);
      final timeStr = DateFormat('h:mm a').format(event.date);
      final isUpcoming = event.date.isAfter(now);

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 16),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    event.title,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
                if (showStatus)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: event.isDeleted
                          ? PdfColors.orange100
                          : (isUpcoming ? PdfColors.green100 : PdfColors.grey200),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      event.isDeleted
                          ? 'Archived'
                          : (isUpcoming ? 'Upcoming' : 'Completed'),
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: event.isDeleted
                            ? PdfColors.orange800
                            : (isUpcoming ? PdfColors.green800 : PdfColors.grey700),
                      ),
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Text('Location: ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  event.venue,
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text('Date: ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  '$dateStr at $timeStr',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text('Category: ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  event.category,
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.blue600),
                ),
                pw.Spacer(),
                pw.Text(
                  '${event.currentAttendees}/${event.maxAttendees ?? "Unlimited"} registered',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ],
            ),
            if (event.description.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                event.description.length > 150
                    ? '${event.description.substring(0, 150)}...'
                    : event.description,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.grey100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildResourceList(List<EventResource> resources) {
    return resources.map((resource) {
      String iconText;
      switch (resource.fileType.toLowerCase()) {
        case 'pdf':
          iconText = '[PDF]';
          break;
        case 'link':
          iconText = '[LINK]';
          break;
        case 'image':
          iconText = '[IMG]';
          break;
        case 'video':
          iconText = '[VID]';
          break;
        default:
          iconText = '[FILE]';
      }

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Text(iconText, style: const pw.TextStyle(fontSize: 16)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    resource.title,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    resource.fileType.toUpperCase(),
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue700),
                  ),
                ),
              ],
            ),
            if (resource.description != null && resource.description!.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                resource.description!,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
              ),
            ],
            pw.SizedBox(height: 6),
            pw.Text(
              'URL: ${resource.fileUrl}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.blue600,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Uploaded: ${DateFormat('MMM d, yyyy').format(resource.uploadedAt)}${resource.uploadedBy != null ? ' by ${resource.uploadedBy}' : ''}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Build resource list with embedded images
  static List<pw.Widget> _buildResourceListWithImages(
    List<EventResource> resources,
    Map<String, Uint8List> imageCache,
  ) {
    return resources.map((resource) {
      final isImage = resource.fileType.toLowerCase() == 'image' ||
                      resource.fileType.toLowerCase() == 'jpg' ||
                      resource.fileType.toLowerCase() == 'png';
      final hasImageData = imageCache.containsKey(resource.id);

      String typeLabel;
      switch (resource.fileType.toLowerCase()) {
        case 'pdf':
          typeLabel = '[PDF]';
          break;
        case 'link':
          typeLabel = '[LINK]';
          break;
        case 'image':
        case 'jpg':
        case 'png':
          typeLabel = '[IMAGE]';
          break;
        case 'video':
          typeLabel = '[VIDEO]';
          break;
        default:
          typeLabel = '[FILE]';
      }

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 16),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Title row
            pw.Row(
              children: [
                pw.Text(typeLabel, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    resource.title,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    resource.fileType.toUpperCase(),
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue700),
                  ),
                ),
              ],
            ),

            // Description
            if (resource.description != null && resource.description!.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                resource.description!,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
              ),
            ],

            // Embedded image for image resources
            if (isImage && hasImageData) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey200),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 4,
                  verticalRadius: 4,
                  child: pw.Image(
                    pw.MemoryImage(imageCache[resource.id]!),
                    width: 400,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            ] else if (isImage && !hasImageData) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                '(Image could not be loaded)',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.red),
              ),
            ],

            // URL for non-image resources
            if (!isImage || !hasImageData) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                'URL: ${resource.fileUrl}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue600),
              ),
            ],

            // Upload info
            pw.SizedBox(height: 4),
            pw.Text(
              'Uploaded: ${DateFormat('MMM d, yyyy').format(resource.uploadedAt)}${resource.uploadedBy != null ? ' by ${resource.uploadedBy}' : ''}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ),
      );
    }).toList();
  }

  static String _sanitizeFilename(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  static Future<bool> _shareFile(Uint8List bytes, String filename) async {
    try {
      if (kIsWeb) {
        // Web: Use browser download via conditionally imported function
        downloadFileWeb(bytes, filename);
        return true;
      } else {
        // Mobile/Desktop: Use file system and share via conditionally imported function
        return await shareFileNative(bytes, filename);
      }
    } catch (e) {
      LoggingService.error('Error sharing/downloading file', e);
      return false;
    }
  }
}
