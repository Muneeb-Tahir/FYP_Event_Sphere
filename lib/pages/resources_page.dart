// lib/pages/resources_page.dart
// Event Resources Page - View and upload event materials

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/resource_service.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';

class ResourcesPage extends ConsumerStatefulWidget {
  final Event event;
  const ResourcesPage({super.key, required this.event});

  @override
  ConsumerState<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends ConsumerState<ResourcesPage> {
  List<EventResource> _resources = [];
  bool _loading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = ref.read(currentUserProvider);
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _loading = true);
    try {
      final resources = await ResourceService.getEventResources(widget.event.id);
      setState(() {
        _resources = resources;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  bool get _canManage {
    if (_currentUser == null) return false;
    return _currentUser!.role == UserRole.admin ||
           _currentUser!.role == UserRole.superAdmin ||
           _currentUser!.role == UserRole.president ||
           _currentUser!.role == UserRole.vicePresident ||
           _currentUser!.id == widget.event.createdBy;
  }

  void _showAddResourceDialog() {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Resource', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.link, color: Color(0xFF9D4EDD)),
              title: const Text('Add Link', style: TextStyle(color: Colors.white)),
              subtitle: const Text('YouTube, Drive, Website, etc.', style: TextStyle(color: Color(0xFFB8A9C9))),
              onTap: () {
                Navigator.pop(context);
                _showAddLinkDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Color(0xFF9D4EDD)),
              title: const Text('Upload File', style: TextStyle(color: Colors.white)),
              subtitle: const Text('PDF, Image, Document', style: TextStyle(color: Color(0xFFB8A9C9))),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLinkDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Add Link', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g., Event Slides'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL', hintText: 'https://...'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || urlController.text.isEmpty) return;
              Navigator.pop(context);

              final success = await ResourceService.addResourceLink(
                eventId: widget.event.id,
                title: titleController.text.trim(),
                url: urlController.text.trim(),
                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
              );

              if (success) {
                _loadResources();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link added!'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'png', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      final titleController = TextEditingController(text: file.name.split('.').first);

      if (!mounted) return;

      final title = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('File Title'),
          content: TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, titleController.text.trim()), child: const Text('Upload')),
          ],
        ),
      );

      if (title == null || title.isEmpty) return;

      final success = await ResourceService.uploadResourceFile(
        eventId: widget.event.id,
        title: title,
        fileBytes: file.bytes!,
        fileName: file.name,
        fileType: file.extension ?? 'document',
      );

      if (success) {
        _loadResources();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File uploaded!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _openResource(EventResource resource) async {
    final fileType = resource.fileType.toLowerCase();

    // For images, show in-app image viewer
    if (fileType == 'image' || fileType == 'jpg' || fileType == 'png' || fileType == 'jpeg') {
      _showImageViewer(resource);
      return;
    }

    // For other types, open in external app
    final uri = Uri.parse(resource.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open: ${resource.fileUrl}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageViewer(EventResource resource) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? DarkColors.surface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      resource.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Image
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: isDark ? DarkColors.background : Colors.grey[100],
              ),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  resource.fileUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Failed to load image', style: TextStyle(color: isDark ? DarkColors.textSecondary : Colors.grey)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final uri = Uri.parse(resource.fileUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: const Text('Open in Browser'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Footer with actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? DarkColors.surface : Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (resource.description != null)
                    Expanded(
                      child: Text(
                        resource.description!,
                        style: TextStyle(fontSize: 12, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(resource.fileUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open in Browser'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteResource(EventResource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text('Delete "${resource.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ResourceService.deleteResource(resource.id);
      _loadResources();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text('Event Resources', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_canManage)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF9D4EDD)),
              onPressed: _showAddResourceDialog,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _resources.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadResources,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resources.length,
                    itemBuilder: (context, index) => _buildResourceCard(_resources[index], isDark),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 80, color: Color(0xFFB8A9C9)),
          const SizedBox(height: 16),
          const Text('No resources yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Add links or files for attendees', style: TextStyle(color: Color(0xFFB8A9C9))),
          if (_canManage) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _showAddResourceDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Resource', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourceCard(EventResource resource, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTypeColor(resource.fileType).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(resource.icon, color: _getTypeColor(resource.fileType)),
        ),
        title: Text(resource.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resource.description != null) ...[
              const SizedBox(height: 4),
              Text(resource.description!, style: const TextStyle(fontSize: 13, color: Color(0xFFB8A9C9))),
            ],
            const SizedBox(height: 4),
            Text(resource.fileType.toUpperCase(), style: TextStyle(fontSize: 11, color: _getTypeColor(resource.fileType), fontWeight: FontWeight.w500)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Color(0xFF9D4EDD)),
              onPressed: () => _openResource(resource),
            ),
            if (_canManage)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteResource(resource),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return Colors.red;
      case 'link': return Colors.blue;
      case 'image': return Colors.green;
      case 'video': return Colors.purple;
      default: return Colors.orange;
    }
  }
}
