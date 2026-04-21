// lib/pages/photo_gallery_page.dart
// Event Photo Gallery - View and upload event photos

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/photo_service.dart';
import '../providers/auth_provider.dart';

class PhotoGalleryPage extends ConsumerStatefulWidget {
  final Event event;
  const PhotoGalleryPage({super.key, required this.event});

  @override
  ConsumerState<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends ConsumerState<PhotoGalleryPage> {
  List<EventPhoto> _photos = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _loading = true);
    try {
      final photos = await PhotoService.getEventPhotos(widget.event.id);
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadPhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) return;

      setState(() => _uploading = true);

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        setState(() => _uploading = false);
        return;
      }

      final bytes = await image.readAsBytes();
      final caption = await _showCaptionDialog();

      try {
        await PhotoService.uploadEventPhoto(
          eventId: widget.event.id,
          userId: currentUser.id,
          photoBytes: bytes,
          fileName: image.name,
          caption: caption,
        );

        await _loadPhotos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _uploading = false);
  }

  Future<String?> _showCaptionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Add Caption', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter a caption (optional)',
            hintStyle: const TextStyle(color: Color(0xFFB8A9C9)),
            filled: true,
            fillColor: const Color(0xFF0D0B14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Skip', style: TextStyle(color: Color(0xFFB8A9C9))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openPhotoViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewerPage(
          photos: _photos,
          initialIndex: index,
          eventId: widget.event.id,
          onDelete: _loadPhotos,
        ),
      ),
    );
  }

  // Check if user can add photos (admin, superAdmin, president only)
  bool _canAddPhotos(User user) {
    return user.role == UserRole.admin ||
           user.role == UserRole.superAdmin ||
           user.role == UserRole.president;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final isEventPast = widget.event.date.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text(
          'Event Photos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Show upload button only for past events and authorized users (admin, superadmin, president)
          if (isEventPast && currentUser != null && _canAddPhotos(currentUser))
            _uploading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9D4EDD))),
                  )
                : IconButton(
                    icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF9D4EDD)),
                    onPressed: _uploadPhoto,
                  ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)))
          : _photos.isEmpty
              ? _buildEmptyState(isDark, isEventPast, currentUser)
              : RefreshIndicator(
                  onRefresh: _loadPhotos,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) => _buildPhotoTile(_photos[index], index, isDark),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark, bool isEventPast, User? currentUser) {
    final canAddPhotos = currentUser != null && _canAddPhotos(currentUser);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Color(0xFFB8A9C9),
          ),
          const SizedBox(height: 16),
          const Text(
            'No photos yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEventPast && canAddPhotos
                ? 'Be the first to share a memory!'
                : isEventPast
                    ? 'No photos have been added yet'
                    : 'Photos can be added after the event',
            style: const TextStyle(
              color: Color(0xFFB8A9C9),
            ),
          ),
          if (isEventPast && canAddPhotos) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _uploadPhoto,
                icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                label: const Text('Upload Photo', style: TextStyle(color: Colors.white)),
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

  Widget _buildPhotoTile(EventPhoto photo, int index, bool isDark) {
    return GestureDetector(
      onTap: () => _openPhotoViewer(index),
      child: Hero(
        tag: 'photo_${photo.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: photo.photoUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: const Color(0xFF1E1B2E),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9D4EDD))),
              ),
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFF1E1B2E),
                child: const Icon(Icons.broken_image, color: Color(0xFFB8A9C9)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Full-screen photo viewer
class PhotoViewerPage extends ConsumerStatefulWidget {
  final List<EventPhoto> photos;
  final int initialIndex;
  final String eventId;
  final VoidCallback? onDelete;

  const PhotoViewerPage({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.eventId,
    this.onDelete,
  });

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deletePhoto(EventPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Delete Photo', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this photo?', style: TextStyle(color: Color(0xFFB8A9C9))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PhotoService.deletePhoto(photo.id, photo.photoUrl);
        widget.onDelete?.call();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        // Handle error silently
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final currentPhoto = widget.photos[_currentIndex];
    final canDelete = currentUser?.id == currentPhoto.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletePhoto(currentPhoto),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return Column(
            children: [
              Expanded(
                child: Hero(
                  tag: 'photo_${photo.id}',
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: photo.photoUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
              if (photo.caption != null && photo.caption!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.black54,
                  child: Text(
                    photo.caption!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
