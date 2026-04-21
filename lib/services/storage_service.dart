// lib/services/storage_service.dart
// Supabase Storage Service for image uploads

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'supabase_service.dart';
import 'logging_service.dart';

class StorageService {
  static const String _eventImagesBucket = 'event-images';
  static const String _profileImagesBucket = 'profile-images';

  // ------------------------- PICK IMAGE -------------------------
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 80,
  }) async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: source,
      imageQuality: imageQuality,
      maxWidth: 1200,
      maxHeight: 1200,
    );
  }

  // ------------------------- UPLOAD EVENT IMAGE -------------------------
  static Future<String?> uploadEventImage(XFile file, String eventId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = '${eventId}_${DateTime.now().millisecondsSinceEpoch}.${file.name.split('.').last}';
      final path = 'events/$fileName';

      await SupabaseService.client.storage
          .from(_eventImagesBucket)
          .uploadBinary(path, bytes);

      // Get public URL
      final url = SupabaseService.client.storage
          .from(_eventImagesBucket)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      LoggingService.error('Error uploading event image', e);
      return null;
    }
  }

  // ------------------------- UPLOAD FROM BYTES (WEB) -------------------------
  static Future<String?> uploadEventImageBytes(Uint8List bytes, String eventId, String extension) async {
    try {
      final fileName = '${eventId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'events/$fileName';

      await SupabaseService.client.storage
          .from(_eventImagesBucket)
          .uploadBinary(path, bytes);

      // Get public URL
      final url = SupabaseService.client.storage
          .from(_eventImagesBucket)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      LoggingService.error('Error uploading event image bytes', e);
      return null;
    }
  }

  // ------------------------- UPLOAD PROFILE IMAGE -------------------------
  static Future<String?> uploadProfileImage(XFile file, String userId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.${file.name.split('.').last}';
      final path = 'profiles/$fileName';

      await SupabaseService.client.storage
          .from(_profileImagesBucket)
          .uploadBinary(path, bytes);

      // Get public URL
      final url = SupabaseService.client.storage
          .from(_profileImagesBucket)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      LoggingService.error('Error uploading profile image', e);
      return null;
    }
  }

  // ------------------------- DELETE IMAGE -------------------------
  static Future<bool> deleteEventImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final path = pathSegments.sublist(pathSegments.indexOf('events')).join('/');

      await SupabaseService.client.storage
          .from(_eventImagesBucket)
          .remove([path]);

      return true;
    } catch (e) {
      LoggingService.error('Error deleting image', e);
      return false;
    }
  }
}
