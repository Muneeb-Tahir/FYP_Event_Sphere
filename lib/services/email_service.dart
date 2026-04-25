// lib/services/email_service.dart
// Email Service - Calls Supabase Edge Function to send emails

import 'dart:convert';
import '../services/supabase_service.dart';
import 'logging_service.dart';

class EmailService {
  /// HTML-escape user-supplied strings to prevent XSS in email templates
  static String _esc(String input) => const HtmlEscape().convert(input);
  // NOTE: Emails are sent via SupabaseService.client.functions.invoke('send-email')
  // The old _functionUrl constant was dead code. If you need direct HTTP calls,
  // use the Supabase client functions API instead.
  //
  // SECURITY: User-supplied values (name, eventTitle) are interpolated into HTML.
  // The Edge Function should HTML-encode these to prevent XSS.

  /// Send welcome email to new user
  static Future<void> sendWelcomeEmail(String email, String name) async {
    await _sendEmail(
      to: email,
      subject: 'Welcome to Event Sphere! 🎉',
      html: '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center;">
            <h1 style="color: white; margin: 0;">Welcome to Event Sphere!</h1>
          </div>
          <div style="padding: 30px; background: #f9f9f9;">
            <p style="font-size: 16px;">Hi <strong>${_esc(name)}</strong>,</p>
            <p>Thank you for creating an account with Event Sphere! We're thrilled to have you on board.</p>
            <p>With Event Sphere, you can:</p>
            <ul>
              <li>🎫 Browse and register for exciting events</li>
              <li>📅 Keep track of your registered events</li>
              <li>🏛️ Join societies and connect with others</li>
              <li>📢 Stay updated with announcements</li>
            </ul>
            <p>Start exploring events now and make the most of your campus experience!</p>
            <br>
            <p>Best regards,<br><strong>The Event Sphere Team</strong></p>
          </div>
        </div>
      ''',
      type: 'welcome',
    );
  }

  /// Send event approved email to event creator
  static Future<void> sendEventApprovedEmail(String email, String eventTitle, String eventDate, String venue) async {
    await _sendEmail(
      to: email,
      subject: 'Your Event Has Been Approved! 🎉',
      html: '''
        <h2>Great News!</h2>
        <p>Your event <strong>${_esc(eventTitle)}</strong> has been approved!</p>
        <p><strong>Date:</strong> ${_esc(eventDate)}</p>
        <p><strong>Venue:</strong> ${_esc(venue)}</p>
        <p>Students can now register for your event. Good luck!</p>
        <br>
        <p>Best regards,<br><strong>Event Sphere Team</strong></p>
      ''',
      type: 'event_approved',
    );
  }

  /// Send new event announcement to a user
  static Future<void> sendNewEventAnnouncement({
    required String email,
    required String eventTitle,
    required String eventDate,
    required String venue,
    required String category,
    required String description,
  }) async {
    await _sendEmail(
      to: email,
      subject: '🎫 New Event: ${_esc(eventTitle)}',
      html: '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center;">
            <h1 style="color: white; margin: 0;">🎫 New Event!</h1>
          </div>
          <div style="padding: 30px; background: #f9f9f9;">
            <h2 style="color: #333;">${_esc(eventTitle)}</h2>
            <p><strong>📅 Date:</strong> ${_esc(eventDate)}</p>
            <p><strong>📍 Venue:</strong> ${_esc(venue)}</p>
            <p><strong>🏷️ Category:</strong> ${_esc(category)}</p>
            <p style="margin-top: 20px;">${_esc(description)}</p>
            <div style="text-align: center; margin-top: 30px;">
              <p style="color: #666;">Open Event Sphere to register now!</p>
            </div>
            <br>
            <p>Best regards,<br><strong>The Event Sphere Team</strong></p>
          </div>
        </div>
      ''',
      type: 'new_event',
    );
  }

  /// Send new event notification to all users
  static Future<void> notifyAllUsersAboutNewEvent({
    required String eventTitle,
    required String eventDate,
    required String venue,
    required String category,
    required String description,
  }) async {
    try {
      // Get all user emails
      final users = await SupabaseService.client
          .from('users')
          .select('email');

      final emails = (users as List)
          .map((u) => u['email'] as String?)
          .where((e) => e != null && e.isNotEmpty)
          .cast<String>()
          .toList();

      LoggingService.info('Sending new event notification to ${emails.length} users');

      // Send all emails concurrently with individual error handling
      final results = await Future.wait(
        emails.map((email) async {
          try {
            await sendNewEventAnnouncement(
              email: email,
              eventTitle: eventTitle,
              eventDate: eventDate,
              venue: venue,
              category: category,
              description: description,
            );
            return true;
          } catch (e) {
            LoggingService.warning('Failed to send notification to $email: $e');
            return false;
          }
        }),
        eagerError: false,
      );

      final sent = results.where((r) => r).length;
      final failed = results.where((r) => !r).length;
      LoggingService.info('New event notifications: $sent sent, $failed failed');
    } catch (e) {
      LoggingService.error('Error sending batch notifications', e);
    }
  }


  /// Send event rejected email
  static Future<void> sendEventRejectedEmail(String email, String eventTitle, String reason) async {
    await _sendEmail(
      to: email,
      subject: 'Event Submission Update',
      html: '''
        <h2>Event Status Update</h2>
        <p>Unfortunately, your event <strong>${_esc(eventTitle)}</strong> was not approved.</p>
        <p><strong>Reason:</strong> ${_esc(reason)}</p>
        <p>You can modify your event and resubmit it for review.</p>
        <br>
        <p>Best regards,<br><strong>Event Sphere Team</strong></p>
      ''',
      type: 'event_rejected',
    );
  }

  /// Send password reset email (custom, not Supabase's)
  static Future<void> sendPasswordResetEmail(String email) async {
    await _sendEmail(
      to: email,
      subject: 'Password Reset Request',
      html: '''
        <h2>Password Reset</h2>
        <p>We received a request to reset your password.</p>
        <p>If you didn't make this request, you can ignore this email.</p>
        <br>
        <p>Best regards,<br><strong>Event Sphere Team</strong></p>
      ''',
      type: 'password_reset',
    );
  }

  /// Core send email function
  static Future<void> _sendEmail({
    required String to,
    required String subject,
    required String html,
    String type = 'general',
  }) async {
    try {
      LoggingService.debug('Sending $type email to $to');

      final response = await SupabaseService.client.functions.invoke(
        'send-email',
        body: {
          'to': to,
          'subject': subject,
          'html': html,
          'type': type,
        },
      );

      LoggingService.debug('Email response status: ${response.status}');

      if (response.status != 200) {
        LoggingService.warning('Email failed: ${response.data}');
      } else {
        LoggingService.info('Email sent successfully to $to');
      }
    } catch (e) {
      LoggingService.error('Email error', e);
      // Don't throw - email failure shouldn't break the app
    }
  }
}
