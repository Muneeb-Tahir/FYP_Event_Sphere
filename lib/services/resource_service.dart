// lib/services/resource_service.dart
// Event Resources Service - Manage event materials and downloads

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'storage_service.dart';
import 'logging_service.dart';

class EventResource {
  final String id;
  final String eventId;
  final String title;
  final String fileUrl;
  final String fileType; // 'pdf', 'link', 'image', 'video', 'document'
  final String? description;
  final String? uploadedBy;
  final DateTime uploadedAt;

  EventResource({
    required this.id,
    required this.eventId,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    this.description,
    this.uploadedBy,
    required this.uploadedAt,
  });

  factory EventResource.fromMap(Map<String, dynamic> data) {
    return EventResource(
      id: data['id'] ?? '',
      eventId: data['event_id'] ?? '',
      title: data['title'] ?? 'Untitled',
      fileUrl: data['file_url'] ?? '',
      fileType: data['file_type'] ?? 'document',
      description: data['description'],
      uploadedBy: data['users']?['name'],
      uploadedAt: DateTime.tryParse(data['uploaded_at'] ?? '') ?? DateTime.now(),
    );
  }

  IconData get icon {
    switch (fileType.toLowerCase()) {
      case 'pdf': return const IconData(0xe873, fontFamily: 'MaterialIcons'); // Icons.picture_as_pdf
      case 'link': return const IconData(0xe157, fontFamily: 'MaterialIcons'); // Icons.link
      case 'image': return const IconData(0xe3f4, fontFamily: 'MaterialIcons'); // Icons.image
      case 'video': return const IconData(0xe63a, fontFamily: 'MaterialIcons'); // Icons.video_file
      default: return const IconData(0xe24d, fontFamily: 'MaterialIcons'); // Icons.insert_drive_file
    }
  }
}

class ResourceService {
  /// Add a resource link
  static Future<bool> addResourceLink({
    required String eventId,
    required String title,
    required String url,
    String? description,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      await SupabaseService.client.from('event_resources').insert({
        'event_id': eventId,
        'title': title,
        'file_url': url,
        'file_type': 'link',
        'description': description,
        'uploaded_by': userId,
        'uploaded_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      LoggingService.error('Error adding resource link', e);
      return false;
    }
  }

  /// Upload a resource file
  static Future<bool> uploadResourceFile({
    required String eventId,
    required String title,
    required Uint8List fileBytes,
    required String fileName,
    required String fileType,
    String? description,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;

      // Upload to storage using existing method
      final extension = fileName.split('.').last;
      final fileUrl = await StorageService.uploadEventImageBytes(
        fileBytes,
        'resource_$eventId',
        extension,
      );

      if (fileUrl == null) return false;

      // Save to database
      await SupabaseService.client.from('event_resources').insert({
        'event_id': eventId,
        'title': title,
        'file_url': fileUrl,
        'file_type': fileType,
        'description': description,
        'uploaded_by': userId,
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      LoggingService.error('Error uploading resource', e);
      return false;
    }
  }

  /// Get all resources for an event
  static Future<List<EventResource>> getEventResources(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_resources')
          .select('*, users(name)')
          .eq('event_id', eventId)
          .order('uploaded_at', ascending: false);

      return (data as List).map((e) => EventResource.fromMap(e)).toList();
    } catch (e) {
      LoggingService.error('Error fetching resources', e);
      return [];
    }
  }

  /// Get resource count
  static Future<int> getResourceCount(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_resources')
          .select('id')
          .eq('event_id', eventId);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Delete a resource
  static Future<bool> deleteResource(String resourceId) async {
    try {
      await SupabaseService.client
          .from('event_resources')
          .delete()
          .eq('id', resourceId);
      return true;
    } catch (e) {
      LoggingService.error('Error deleting resource', e);
      return false;
    }
  }

  /// Update resource details
  static Future<bool> updateResource({
    required String resourceId,
    String? title,
    String? description,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;

      await SupabaseService.client
          .from('event_resources')
          .update(updateData)
          .eq('id', resourceId);
      return true;
    } catch (e) {
      LoggingService.error('Error updating resource', e);
      return false;
    }
  }
}
