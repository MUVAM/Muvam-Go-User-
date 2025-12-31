import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:muvam/core/services/firebase_config_service.dart';

class InvalidTokenException implements Exception {
  final String message;
  InvalidTokenException(this.message);

  @override
  String toString() => 'InvalidTokenException: $message';
}

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> getAccessToken() async {
    print('🔑 FCM: Starting getAccessToken');

    try {
      print('🔑 FCM: Getting service account config');
      final serviceAccountJson =
          await FirebaseConfigService.getServiceAccountConfig();
      print('✅ FCM: Service account config loaded');

      List<String> scopes = [
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/firebase.database",
        "https://www.googleapis.com/auth/firebase.messaging",
      ];

      print('🔑 FCM: Creating service account client');
      http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
      );

      auth.AccessCredentials credentials = await auth
          .obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client,
          );

      client.close();
      print('✅ FCM: Access token generated successfully');
      return credentials.accessToken.data;
    } catch (e, stackTrace) {
      print('💥 FCM: Error getting access token: $e');
      print('💥 FCM: Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> sendNotificationWithVibration({
    required String deviceToken,
    required String title,
    required String body,
    required String type,
    Map<String, String>? additionalData,
  }) async {
    print('📤 FCM: ========================================');
    print('📤 FCM: Sending notification');
    print('📤 FCM: Token: ${deviceToken.substring(0, 20)}...');
    print('📤 FCM: Title: $title');
    print('📤 FCM: Body: $body');
    print('📤 FCM: Type: $type');

    try {
      print('🔑 FCM: Getting access token');
      final String serverAccessToken = await getAccessToken();

      String endpointFirebaseCloudMessaging =
          'https://fcm.googleapis.com/v1/projects/muvam-go/messages:send';
      print('🎯 FCM: Endpoint: $endpointFirebaseCloudMessaging');

      final Map<String, dynamic> message = {
        'message': {
          'token': deviceToken,
          'notification': {'title': title, 'body': body},
          'data': {
            'type': type,
            'vibrate': 'true',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            ...?additionalData,
          },
          'android': {
            'priority': "high",
            'notification': {
              'sound': "default",
              'click_action': "FLUTTER_NOTIFICATION_CLICK",
              'channel_id': _getChannelId(type),
              'vibrate_timings': ["0s", "0.5s", "0.2s", "0.5s"],
            },
          },
          'apns': {
            'payload': {
              'aps': {'contentAvailable': true, 'badge': 1, 'sound': "default"},
            },
          },
        },
      };

      print('📦 FCM: Payload: ${jsonEncode(message)}');

      final response = await http.post(
        Uri.parse(endpointFirebaseCloudMessaging),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverAccessToken',
        },
        body: jsonEncode(message),
      );

      print('📝 FCM: Status: ${response.statusCode}');
      print('📝 FCM: Response: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ FCM: Notification sent successfully!');
      } else {
        print('❌ FCM: Failed with status: ${response.statusCode}');

        if (response.statusCode == 400 || response.statusCode == 404) {
          try {
            final errorData = jsonDecode(response.body);
            final errorMessage = errorData['error']?['message'] ?? '';
            if (errorMessage.contains('not a valid FCM registration token') ||
                errorMessage.contains('Requested entity was not found')) {
              print('🗑️ FCM: Invalid token detected');
              throw InvalidTokenException('Invalid FCM token');
            }
          } catch (e) {
            if (e is InvalidTokenException) rethrow;
          }
        }
      }
      print('📤 FCM: ========================================');
    } catch (e, stackTrace) {
      print('💥 FCM: Exception: $e');
      print('💥 FCM: Stack: $stackTrace');
      rethrow;
    }
  }

  static String _getChannelId(String type) {
    switch (type) {
      case 'call':
        return 'calls';
      case 'message':
        return 'messages';
      default:
        return 'ride_updates';
    }
  }

  Future<void> _sendToAllUserDevices({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, String>? additionalData,
  }) async {
    print('👥 FCM: ========================================');
    print('👥 FCM: Sending to user: $userId');
    print('👥 FCM: Title: $title');

    try {
      print('🔍 FCM: Fetching tokens from Firestore');
      print('🔍 FCM: Path: users/$userId/tokens');

      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .get();

      print('📊 FCM: Found ${tokensSnapshot.docs.length} token documents');

      if (tokensSnapshot.docs.isEmpty) {
        print('⚠️ FCM: No tokens found for user: $userId');
        return;
      }

      final tokens = tokensSnapshot.docs.map((doc) {
        final data = doc.data();
        print('🔑 FCM: Token doc: $data');
        return data['token'] as String;
      }).toList();

      print('📱 FCM: Sending to ${tokens.length} devices');

      for (final token in tokens) {
        print('📤 FCM: Sending to: ${token.substring(0, 20)}...');
        try {
          await sendNotificationWithVibration(
            deviceToken: token,
            title: title,
            body: body,
            type: type,
            additionalData: additionalData,
          );
        } catch (e) {
          print('❌ FCM: Failed: $e');
          if (e is InvalidTokenException) {
            print('🗑️ FCM: Removing invalid token');
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('tokens')
                .doc(token)
                .delete();
          }
        }
      }
      print('👥 FCM: ========================================');
    } catch (e, stackTrace) {
      print('💥 FCM: Error: $e');
      print('💥 FCM: Stack: $stackTrace');
    }
  }

  Future<void> sendRideAcceptedNotification({
    required String userId,
    required String driverName,
    required String rideId,
  }) async {
    print(
      '🚗 FCM: RIDE ACCEPTED - User: $userId, Driver: $driverName, Ride: $rideId',
    );
    await _sendToAllUserDevices(
      userId: userId,
      title: 'Ride Accepted! 🚗',
      body: '$driverName has accepted your ride request',
      type: 'ride_accepted',
      additionalData: {
        'rideId': rideId,
        'driverName': driverName,
        'screen': 'ride_details',
      },
    );
  }

  Future<void> sendDriverArrivedNotification({
    required String userId,
    required String driverName,
    required String rideId,
  }) async {
    print('📍 FCM: DRIVER ARRIVED - User: $userId, Driver: $driverName');
    await _sendToAllUserDevices(
      userId: userId,
      title: 'Driver Arrived! 📍',
      body: '$driverName has arrived at your pickup location',
      type: 'driver_arrived',
      additionalData: {
        'rideId': rideId,
        'driverName': driverName,
        'screen': 'ride_details',
      },
    );
  }

  Future<void> sendRideStartedNotification({
    required String userId,
    required String driverName,
    required String rideId,
  }) async {
    print('🚀 FCM: RIDE STARTED - User: $userId, Driver: $driverName');
    await _sendToAllUserDevices(
      userId: userId,
      title: 'Ride Started! 🚀',
      body: 'Your ride with $driverName has started',
      type: 'ride_started',
      additionalData: {
        'rideId': rideId,
        'driverName': driverName,
        'screen': 'ride_details',
      },
    );
  }

  Future<void> sendRideCompletedNotification({
    required String userId,
    required String driverName,
    required String rideId,
    required double fare,
  }) async {
    print('✅ FCM: RIDE COMPLETED - User: $userId, Fare: \$$fare');
    await _sendToAllUserDevices(
      userId: userId,
      title: 'Ride Completed! ✅',
      body:
          'Your ride with $driverName is complete. Fare: \$${fare.toStringAsFixed(2)}',
      type: 'ride_completed',
      additionalData: {
        'rideId': rideId,
        'driverName': driverName,
        'fare': fare.toString(),
        'screen': 'ride_rating',
      },
    );
  }

  Future<void> sendNewMessageNotification({
    required String userId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    print('💬 FCM: NEW MESSAGE - User: $userId, From: $senderName');
    await _sendToAllUserDevices(
      userId: userId,
      title: 'New message from $senderName 💬',
      body: message,
      type: 'message',
      additionalData: {
        'chatId': chatId,
        'senderName': senderName,
        'screen': 'chat',
      },
    );
  }

  Future<void> sendIncomingCallNotification({
    required String userId,
    required String callerName,
    required String sessionId,
    required String rideId,
  }) async {
    print('📞 FCM: INCOMING CALL - User: $userId, Caller: $callerName');
    await _sendToAllUserDevices(
      userId: userId,
      title: 'Incoming Call 📞',
      body: '$callerName is calling you',
      type: 'call',
      additionalData: {
        'sessionId': sessionId,
        'callerName': callerName,
        'rideId': rideId,
        'screen': 'call',
      },
    );
  }
}
