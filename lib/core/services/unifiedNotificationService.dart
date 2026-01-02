import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muvam/core/services/fcmTokenService.dart';
import 'package:muvam/core/services/fcm_notification_service.dart';

class UnifiedNotificationService {
  /// Send chat message notification with vibration and enhanced features
  static Future<void> sendChatNotification({
    required String receiverId,
    required String senderName,
    required String messageText,
    required String chatRoomId,
  }) async {
    // final greeting = _getGreeting(receiverName);
    // Get receiver's FCM tokens
    final tokens = await FCMTokenService.getTokensForUser(receiverId);
    if (tokens.isEmpty) {
      return;
    }
    // Send notification to all user's devices
    for (String token in tokens) {
      try {
        await EnhancedNotificationService.sendNotificationWithVibration(
          deviceToken: token,
          title: "New Message",
          body: messageText,
          type: 'chat_message',
          additionalData: {
            'chatRoomId': chatRoomId,
            'senderId': senderName,
            'messageText': messageText,
          },
        );
      } catch (e) {
        if (e is InvalidTokenException) {
          await FCMTokenService.removeInvalidToken(receiverId, token);
        }
      }

      // Don't store chat messages in notification collection
      // Chat messages are handled separately in chatRooms collection
    }
  }

  static Future<void> sendCallNotification({
    required String receiverId,
    required String callerName,
    required int rideId,
    required int sessionId,
    String? callerImage,
  }) async {
    try {
      // Get receiver's FCM tokens
      final tokens = await FCMTokenService.getTokensForUser(receiverId);
      if (tokens.isEmpty) {
        print('⚠️ CALL_NOTIF: No FCM tokens found for user $receiverId');
        return;
      }

      print('📞 CALL_NOTIF: Sending call notification to $receiverId');
      print(
        '📞 CALL_NOTIF: Caller: $callerName, Ride: $rideId, Session: $sessionId',
      );

      // Send notification to all user's devices
      for (String token in tokens) {
        try {
          await EnhancedNotificationService.sendNotificationWithVibration(
            deviceToken: token,
            title: "Incoming Call",
            body: 'Passenger is calling you',
            type: 'incoming_call',
            additionalData: {
              'caller_name': callerName,
              'caller_image': callerImage ?? '',
              'ride_id': rideId.toString(),
              'session_id': sessionId.toString(),
              'call_type': 'voice',
              'priority': 'high',
              // No custom sound - will use notification channel's default ringtone
            },
          );
          print(
            '✅ CALL_NOTIF: Notification sent to token: ${token.substring(0, 20)}...',
          );
        } catch (e) {
          print('❌ CALL_NOTIF: Failed to send to token: $e');
          if (e is InvalidTokenException) {
            await FCMTokenService.removeInvalidToken(receiverId, token);
          }
        }
      }
    } catch (e) {
      print('💥 CALL_NOTIF: Error sending call notification: $e');
    }
  }

  /// Send order notification with vibration and enhanced features
  static Future<void> sendOrderNotification({
    required String receiverId,
    required String title,
    required String body,
    required String orderId,
    String? orderStatus,
  }) async {
    try {
      // Get receiver's name for greeting
      String receiverName = await _getUserName(receiverId);
      final greeting = _getGreeting(receiverName);
      // Get receiver's FCM tokens
      final tokens = await FCMTokenService.getTokensForUser(receiverId);
      for (String token in tokens) {
        try {
          await EnhancedNotificationService.sendNotificationWithVibration(
            deviceToken: token,
            title: greeting,
            body: body,
            type: 'order_notification',
            additionalData: {
              'orderId': orderId,
              'orderStatus': orderStatus ?? 'pending',
            },
          );
        } catch (e) {
          if (e is InvalidTokenException) {
            await FCMTokenService.removeInvalidToken(receiverId, token);
          }
        }
      }
      await _storeNotificationInFirestore(
        userId: receiverId,
        title: title,
        body: body,
        type: 'order',
        additionalData: {'orderId': orderId},
      );
    } catch (e) {}
  }

  /// Send payment notification with vibration and enhanced features
  static Future<void> sendPaymentNotification({
    required String receiverId,
    required String title,
    required String body,
    required String transactionId,
    String? amount,
  }) async {
    try {
      String receiverName = await _getUserName(receiverId);
      final greeting = _getGreeting(receiverName);
      final tokens = await FCMTokenService.getTokensForUser(receiverId);
      for (String token in tokens) {
        try {
          await EnhancedNotificationService.sendNotificationWithVibration(
            deviceToken: token,
            title: greeting,
            body: body,
            type: 'payment_notification',
            additionalData: {
              'transactionId': transactionId,
              'amount': amount ?? '0',
            },
          );
        } catch (e) {
          if (e is InvalidTokenException) {
            await FCMTokenService.removeInvalidToken(receiverId, token);
          }
        }
      }
      await _storeNotificationInFirestore(
        userId: receiverId,
        title: title,
        body: body,
        type: 'payment',
        additionalData: {'transactionId': transactionId},
      );
    } catch (e) {}
  }

  /// Send subscription notification with vibration and enhanced features
  static Future<void> sendSubscriptionNotification({
    required String receiverId,
    required String title,
    required String body,
    required String subscriptionType,
  }) async {
    try {
      String receiverName = await _getUserName(receiverId);
      final greeting = _getGreeting(receiverName);
      final tokens = await FCMTokenService.getTokensForUser(receiverId);
      for (String token in tokens) {
        try {
          await EnhancedNotificationService.sendNotificationWithVibration(
            deviceToken: token,
            title: greeting,
            body: body,
            type: 'subscription_notification',
            additionalData: {'subscriptionType': subscriptionType},
          );
        } catch (e) {
          if (e is InvalidTokenException) {
            await FCMTokenService.removeInvalidToken(receiverId, token);
          }
        }
      }
      await _storeNotificationInFirestore(
        userId: receiverId,
        title: title,
        body: body,
        type: 'subscription',
        additionalData: {'subscriptionType': subscriptionType},
      );
    } catch (e) {}
  }

  /// Send general notification with vibration and enhanced features
  static Future<void> sendGeneralNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type,
    Map<String, String>? additionalData,
  }) async {
    try {
      String receiverName = await _getUserName(receiverId);
      final greeting = _getGreeting(receiverName);
      final tokens = await FCMTokenService.getTokensForUser(receiverId);
      for (String token in tokens) {
        try {
          await EnhancedNotificationService.sendNotificationWithVibration(
            deviceToken: token,
            title: greeting,
            body: body,
            type: type,
            additionalData: additionalData,
          );
        } catch (e) {
          if (e is InvalidTokenException) {
            await FCMTokenService.removeInvalidToken(receiverId, token);
          }
        }
      }
      await _storeNotificationInFirestore(
        userId: receiverId,
        title: title,
        body: body,
        type: type,
        additionalData: additionalData,
      );
    } catch (e) {}
  }

  /// Send notification to multiple users (admin broadcasts)
  static Future<void> sendToMultipleUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required String type,
    Map<String, String>? additionalData,
  }) async {
    try {
      for (String userId in userIds) {
        await sendGeneralNotification(
          receiverId: userId,
          title: title,
          body: body,
          type: type,
          additionalData: additionalData,
        );
      }
    } catch (e) {}
  }

  /// Send notification to all admin users
  static Future<void> sendToAdmins({
    required String title,
    required String body,
    Map<String, String>? additionalData,
  }) async {
    try {
      // Get admin tokens from UserToken collection
      final adminTokenDoc = await FirebaseFirestore.instance
          .collection('UserToken')
          .doc('Admin')
          .get();
      if (adminTokenDoc.exists) {
        List<dynamic> tokenList = adminTokenDoc['token'] ?? [];
        for (String token in tokenList) {
          try {
            await EnhancedNotificationService.sendNotificationWithVibration(
              deviceToken: token,
              title: title,
              body: body,
              type: 'admin_notification',
              additionalData: additionalData,
            );
          } catch (e) {}
        }
      }
    } catch (e) {}
  }

  // Helper methods
  static String _getGreeting(String userName) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "🌅 Good Morning $userName";
    } else if (hour < 17) {
      return "☀️ Good Afternoon $userName";
    } else {
      return "🌙 Good Evening $userName";
    }
  }

  static Future<String> _getUserName(String userId) async {
    try {
      // Check vendors collection first
      var userDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['name'] as String? ?? 'User';
      }
      // Check customers collection
      userDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['username'] as String? ??
            userData?['name'] as String? ??
            'User';
      }
      return 'User';
    } catch (e) {
      return 'User';
    }
  }

  static Future<void> _storeNotificationInFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notificationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': type,
        ...?additionalData,
      };
      await FirebaseFirestore.instance
          .collection('NotificationWp')
          .doc(userId)
          .collection('notification')
          .add(notificationData);
    } catch (e) {}
  }
}
