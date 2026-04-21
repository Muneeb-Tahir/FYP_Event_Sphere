// lib/services/photo_service.dart
// Event Photo Gallery Service

import 'dart:typed_data';
import 'supabase_service.dart';
import 'storage_service.dart';
import 'logging_service.dart';
import '../utils/image_compressor.dart';

class EventPhoto {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String photoUrl;
  final String? caption;
  final DateTime uploadedAt;
  final bool isApproved;

  EventPhoto({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.photoUrl,
    this.caption,
    required this.uploadedAt,
    this.isApproved = true,
  });

  factory EventPhoto.fromMap(Map<String, dynamic> data) {
    return EventPhoto(
      id: data['id'] ?? '',
      eventId: data['event_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['users']?['name'] ?? 'Anonymous',
      photoUrl: data['photo_url'] ?? '',
      caption: data['caption'],
      uploadedAt: DateTime.tryParse(data['uploaded_at'] ?? '') ?? DateTime.now(),
      isApproved: data['is_approved'] ?? true,
    );
  }
}

class PhotoService {
  // Upload a photo with automatic compression
  static Future<String> uploadEventPhoto({
    required String eventId,
    required String userId,
    required Uint8List photoBytes,
    required String fileName,
    String? caption,
  }) async {
    // Validate file size
    final sizeError = ImageCompressor.validateImageSize(photoBytes);
    if (sizeError != null) {
      throw Exception(sizeError);
    }

    // Compress image if needed (>500KB)
    Uint8List finalBytes = photoBytes;
    if (ImageCompressor.needsCompression(photoBytes)) {
      final compressed = await ImageCompressor.compressForUpload(photoBytes);
      if (compressed != null) {
        finalBytes = compressed;
        LoggingService.debug('Image compressed: ${photoBytes.length} -> ${compressed.length} bytes');
      }
    }

    // Upload to storage (always use jpg after compression)
    const extension = 'jpg';
    final photoUrl = await StorageService.uploadEventImageBytes(
      finalBytes,
      'photo_$userId',
      extension,
    );

    if (photoUrl == null) throw Exception('Failed to upload photo');

    // Save to database
    await SupabaseService.client.from('event_photos').insert({
      'event_id': eventId,
      'user_id': userId,
      'photo_url': photoUrl,
      'caption': caption,
      'uploaded_at': DateTime.now().toIso8601String(),
      'is_approved': true,
    });

    return photoUrl;
  }

  // Get all photos for an event
  static Future<List<EventPhoto>> getEventPhotos(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_photos')
          .select('*, users!inner(name)')
          .eq('event_id', eventId)
          .eq('is_approved', true)
          .order('uploaded_at', ascending: false);

      return (data as List).map((e) => EventPhoto.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get photo count for an event
  static Future<int> getPhotoCount(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_photos')
          .select('id')
          .eq('event_id', eventId)
          .eq('is_approved', true);

      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Delete a photo (only by uploader or admin)
  static Future<void> deletePhoto(String photoId, String photoUrl) async {
    // Delete from storage
    try {
      await StorageService.deleteEventImage(photoUrl);
    } catch (e) {
      // Ignore storage deletion errors
    }

    // Delete from database
    await SupabaseService.client
        .from('event_photos')
        .delete()
        .eq('id', photoId);
  }

  // Approve/Reject photo (admin only)
  static Future<void> setPhotoApproval(String photoId, bool approved) async {
    await SupabaseService.client
        .from('event_photos')
        .update({'is_approved': approved})
        .eq('id', photoId);
  }

  // Get user's photos
  static Future<List<EventPhoto>> getUserPhotos(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('event_photos')
          .select('*, users!inner(name)')
          .eq('user_id', userId)
          .order('uploaded_at', ascending: false);

      return (data as List).map((e) => EventPhoto.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
