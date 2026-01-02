import 'package:muvam/core/services/fcmTokenService.dart';
import 'package:muvam/core/services/fcm_notification_service.dart';
import 'package:muvam/core/utils/app_logger.dart';

class CallNotificationService {
  /// Send incoming call notification to a user
  static Future<void> sendIncomingCallNotification({
    required String receiverId,
    required String callerName,
    required String sessionId,
    required int rideId,
  }) async {
    try {
      AppLogger.log(
        '📞 Sending incoming call notification to user: $receiverId',
        tag: 'CALL_NOTIF',
      );
      AppLogger.log(
        '📞 Caller: $callerName, Session: $sessionId, Ride: $rideId',
        tag: 'CALL_NOTIF',
      );

      // Get receiver's FCM tokens
      final tokens = await FCMTokenService.getTokensForUser(receiverId);

      if (tokens.isEmpty) {
        AppLogger.log(
          '⚠️ No FCM tokens found for user $receiverId',
          tag: 'CALL_NOTIF',
        );
        return;
      }

      AppLogger.log(
        '✅ Found ${tokens.length} FCM tokens for user',
        tag: 'CALL_NOTIF',
      );

      // Send notification to all user's devices
      for (String token in tokens) {
        try {
          await _sendCallNotificationToToken(
            token: token,
            callerName: callerName,
            sessionId: sessionId,
            rideId: rideId,
          );

          AppLogger.log(
            '✅ Call notification sent to token: ${token.substring(0, 20)}...',
            tag: 'CALL_NOTIF',
          );
        } catch (e) {
          AppLogger.error(
            '❌ Failed to send to token: ${token.substring(0, 20)}...',
            error: e,
            tag: 'CALL_NOTIF',
          );

          // Remove invalid tokens
          if (e is InvalidTokenException) {
            await FCMTokenService.removeInvalidToken(receiverId, token);
          }
        }
      }

      AppLogger.log(
        '✅ Incoming call notifications sent successfully',
        tag: 'CALL_NOTIF',
      );
    } catch (e, stack) {
      AppLogger.error(
        '❌ Error sending incoming call notification',
        error: e,
        tag: 'CALL_NOTIF',
      );
      AppLogger.log('Stack trace: $stack', tag: 'CALL_NOTIF');
    }
  }

  /// Send call notification to a specific FCM token
  static Future<void> _sendCallNotificationToToken({
    required String token,
    required String callerName,
    required String sessionId,
    required int rideId,
  }) async {
    await EnhancedNotificationService.sendNotificationWithVibration(
      deviceToken: token,
      title: '📞 Incoming Call',
      body: '$callerName is calling you...',
      type: 'incoming_call',
      additionalData: {
        'session_id': sessionId,
        'caller_name': callerName,
        'ride_id': rideId.toString(),
        'call_type': 'incoming',
        'action': 'open_call_screen',
        // Android-specific for full-screen intent
        'channel_id': 'call_channel',
        'priority': 'max',
        'importance': 'high',
        'sound': 'ringtone', // Custom ringtone
        'vibrate': 'true',
      },
    );
  }

  /// Send call ended notification
  static Future<void> sendCallEndedNotification({
    required String receiverId,
    required String callerName,
    String? reason,
  }) async {
    try {
      AppLogger.log(
        '📞 Sending call ended notification to user: $receiverId',
        tag: 'CALL_NOTIF',
      );

      final tokens = await FCMTokenService.getTokensForUser(receiverId);

      for (String token in tokens) {
        try {
          await EnhancedNotificationService.sendNotificationWithVibration(
            deviceToken: token,
            title: '📞 Call Ended',
            body: reason ?? 'Call with $callerName has ended',
            type: 'call_ended',
            additionalData: {
              'caller_name': callerName,
              'reason': reason ?? 'ended',
            },
          );
        } catch (e) {
          if (e is InvalidTokenException) {
            await FCMTokenService.removeInvalidToken(receiverId, token);
          }
        }
      }

      AppLogger.log('✅ Call ended notifications sent', tag: 'CALL_NOTIF');
    } catch (e) {
      AppLogger.error(
        '❌ Error sending call ended notification',
        error: e,
        tag: 'CALL_NOTIF',
      );
    }
  }

  /// Send missed call notification
  static Future<void> sendMissedCallNotification({
    required String receiverId,
    required String callerName,
    required int rideId,
  }) async {
    try {
      AppLogger.log(
        '📞 Sending missed call notification to user: $receiverId',
        tag: 'CALL_NOTIF',
      );

      final tokens = await FCMTokenService.getTokensForUser(receiverId);

      for (String token in tokens) {
        try {
          await EnhancedNotificationService.sendNotificationWithVibration(
            deviceToken: token,
            title: '📞 Missed Call',
            body: 'You missed a call from $callerName',
            type: 'missed_call',
            additionalData: {
              'caller_name': callerName,
              'ride_id': rideId.toString(),
              'action': 'open_ride_details',
            },
          );
        } catch (e) {
          if (e is InvalidTokenException) {
            await FCMTokenService.removeInvalidToken(receiverId, token);
          }
        }
      }

      AppLogger.log('✅ Missed call notifications sent', tag: 'CALL_NOTIF');
    } catch (e) {
      AppLogger.error(
        '❌ Error sending missed call notification',
        error: e,
        tag: 'CALL_NOTIF',
      );
    }
  }
}
