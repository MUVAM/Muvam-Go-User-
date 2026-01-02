import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:muvam/core/services/fcmTokenService.dart';
import 'package:muvam/core/services/firebase_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
// import 'package:workpal/services/fcmTokenService.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:workpal/services/firebase_config_service.dart';

class InvalidTokenException implements Exception {
  final String message;
  InvalidTokenException(this.message);

  @override
  String toString() => 'InvalidTokenException: $message';
}

class EnhancedNotificationService {
  static Future<String> getAccessToken() async {
    print('🔑 AUTH DEBUG: Starting getAccessToken');

    try {
      print('🔑 AUTH DEBUG: Getting Firebase service account config');
      final serviceAccountJson =
          await FirebaseConfigService.getServiceAccountConfig();
      print('✅ AUTH DEBUG: Service account config obtained');

      List<String> scopes = [
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/firebase.database",
        "https://www.googleapis.com/auth/firebase.messaging",
      ];
      print('🔑 AUTH DEBUG: Scopes: $scopes');

      print('🔑 AUTH DEBUG: Creating service account client');
      http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
      );
      print('✅ AUTH DEBUG: Service account client created');

      print('🔑 AUTH DEBUG: Obtaining access credentials');
      auth.AccessCredentials credentials = await auth
          .obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client,
          );
      print('✅ AUTH DEBUG: Access credentials obtained');

      client.close();
      print('✅ AUTH DEBUG: Access token generated successfully');
      return credentials.accessToken.data;
    } catch (e) {
      print('💥 AUTH DEBUG: Error getting access token: $e');
      print('💥 AUTH DEBUG: Stack trace: ${StackTrace.current}');
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
    print('📤 FCM DEBUG: Starting sendNotificationWithVibration');
    print(
      '📤 FCM DEBUG: Token: ${deviceToken.substring(0, 20)}..., Title: $title, Body: $body, Type: $type',
    );

    try {
      print('🔑 FCM DEBUG: Getting access token');
      final String serverAccessToken = await getAccessToken();
      print('✅ FCM DEBUG: Access token obtained successfully');

      String endpointFirebasecloudMessaging =
          'https://fcm.googleapis.com/v1/projects/muvam-go/messages:send';
      print('🎯 FCM DEBUG: FCM endpoint: $endpointFirebasecloudMessaging');

      // Determine if this is a call notification
      final isCallNotification =
          type == 'incoming_call' || additionalData?['call_type'] == 'incoming';

      // Use appropriate channel and sound based on notification type
      final channelId = isCallNotification ? 'call_channel' : 'FoodHub';
      final sound = 'default'; // Always use default phone ringtone
      final priority = 'high'; // FCM v1 API only supports 'high' or 'normal'

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
            'priority': priority,
            'notification': {
              'sound': sound,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'channel_id': channelId,
              // Note: vibrate_timings, notification_priority, visibility, category, sticky
              // are not supported in FCM v1 API. Use notification channel settings instead.
              if (isCallNotification) ...{
                'tag': 'incoming_call', // Only 'tag' is supported
              },
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'contentAvailable': true,
                'badge': 1,
                'sound': 'default', // Use default phone ringtone
                if (isCallNotification) ...{
                  'category': 'INCOMING_CALL',
                  'interruption-level':
                      'critical', // iOS 15+ for critical alerts
                },
              },
            },
          },
        },
      };

      print('📦 FCM DEBUG: Message payload prepared: ${jsonEncode(message)}');
      print('📤 FCM DEBUG: Sending HTTP POST request to FCM');

      final response = await http.post(
        Uri.parse(endpointFirebasecloudMessaging),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverAccessToken',
        },
        body: jsonEncode(message),
      );

      print('📝 FCM DEBUG: FCM Response - Status Code: ${response.statusCode}');
      print('📝 FCM DEBUG: FCM Response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print(
          '✅ FCM DEBUG: Notification sent successfully! Response: $responseData',
        );
      } else {
        print(
          '❌ FCM DEBUG: FCM request failed with status: ${response.statusCode}',
        );
        // Parse error details if available
        try {
          final errorData = jsonDecode(response.body);
          print('❌ FCM DEBUG: Error details: $errorData');

          // Check if token is invalid and remove it
          if (response.statusCode == 400 || response.statusCode == 404) {
            final errorMessage = errorData['error']?['message'] ?? '';
            print('❌ FCM DEBUG: Error message: $errorMessage');
            if (errorMessage.contains('not a valid FCM registration token') ||
                errorMessage.contains('Requested entity was not found')) {
              print(
                '🗑️ FCM DEBUG: Invalid token detected, throwing InvalidTokenException',
              );
              // Note: We can't remove it here as we don't have userId context
              // The calling method should handle token removal
              throw InvalidTokenException('Invalid FCM token: $deviceToken');
            }
          }
        } catch (e) {
          print('❌ FCM DEBUG: Error parsing FCM error response: $e');
          if (e is InvalidTokenException) {
            rethrow;
          }
        }
      }
    } catch (e, stackTrace) {
      print('💥 FCM DEBUG: Exception in sendNotificationWithVibration: $e');
      print('💥 FCM DEBUG: Stack trace: $stackTrace');
      rethrow; // Re-throw to let calling method handle it
    }
  }

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

  static Future<void> sendLikeNotification({
    required String postOwnerId,
    required String likerName,
    required String postId,
  }) async {
    print('🔔 ENHANCED_NOTIF DEBUG: Starting sendLikeNotification');
    print(
      '🔔 ENHANCED_NOTIF DEBUG: postOwnerId: $postOwnerId, likerName: $likerName, postId: $postId',
    );

    try {
      // Get post owner's name for greeting - check both vendors and customers
      String userName = 'User';

      print(
        '👤 ENHANCED_NOTIF DEBUG: Fetching post owner name from vendors collection',
      );
      // Try vendors collection first
      var userDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(postOwnerId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        userName = userData?['name'] as String? ?? 'User';
        print('👤 ENHANCED_NOTIF DEBUG: Found vendor name: $userName');
      } else {
        print(
          '👤 ENHANCED_NOTIF DEBUG: Not found in vendors, checking customers collection',
        );
        // Try customers collection
        userDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(postOwnerId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          userName =
              userData?['username'] as String? ??
              userData?['name'] as String? ??
              'User';
          print('👤 ENHANCED_NOTIF DEBUG: Found customer name: $userName');
        } else {
          print(
            '❌ ENHANCED_NOTIF DEBUG: Post owner not found in either collection',
          );
        }
      }

      final greeting = _getGreeting(userName);
      print('👋 ENHANCED_NOTIF DEBUG: Generated greeting: $greeting');

      CollectionReference userTokenCollection = FirebaseFirestore.instance
          .collection('UserToken');

      print(
        '🔑 ENHANCED_NOTIF DEBUG: Fetching FCM tokens for user: $postOwnerId',
      );
      DocumentSnapshot docSnapshot = await userTokenCollection
          .doc(postOwnerId)
          .get();

      if (docSnapshot.exists) {
        List<dynamic> tokenList = docSnapshot['token'] ?? [];
        print(
          '🔑 ENHANCED_NOTIF DEBUG: Found ${tokenList.length} tokens: $tokenList',
        );

        if (tokenList.isEmpty) {
          print('⚠️ ENHANCED_NOTIF DEBUG: No tokens found, attempting refresh');
          await _attemptTokenRefresh(postOwnerId);
          // Try again after refresh
          docSnapshot = await userTokenCollection.doc(postOwnerId).get();
          if (docSnapshot.exists) {
            tokenList = docSnapshot['token'] ?? [];
            print(
              '🔑 ENHANCED_NOTIF DEBUG: After refresh, found ${tokenList.length} tokens: $tokenList',
            );
          }
        }

        for (String token in tokenList) {
          print(
            '📤 ENHANCED_NOTIF DEBUG: Sending notification to token: ${token.substring(0, 20)}...',
          );
          try {
            await sendNotificationWithVibration(
              deviceToken: token,
              title: greeting,
              body: "You have a like on your post",
              type: "like_notification",
              additionalData: {'postId': postId, 'likerId': likerName},
            );
            print(
              '✅ ENHANCED_NOTIF DEBUG: Notification sent successfully to token: ${token.substring(0, 20)}...',
            );
          } catch (e) {
            print(
              '❌ ENHANCED_NOTIF DEBUG: Failed to send notification to token: ${token.substring(0, 20)}... Error: $e',
            );
            if (e is InvalidTokenException) {
              print('🗑️ ENHANCED_NOTIF DEBUG: Removing invalid token');
              await FCMTokenService.removeInvalidToken(postOwnerId, token);
            }
          }
        }
      } else {
        print(
          '❌ ENHANCED_NOTIF DEBUG: No token document found for user, attempting refresh',
        );
        await _attemptTokenRefresh(postOwnerId);
      }

      print('💾 ENHANCED_NOTIF DEBUG: Storing notification in Firestore');
      // Store notification in Firestore
      await _storeNotificationInFirestore(
        userId: postOwnerId,
        title: "Like Notification",
        body: "$likerName liked your post",
        type: "like",
        additionalData: {'postId': postId, 'likerId': likerName},
      );
      print(
        '✅ ENHANCED_NOTIF DEBUG: Notification stored in Firestore successfully',
      );
      print(
        '✅ ENHANCED_NOTIF DEBUG: sendLikeNotification completed successfully',
      );
    } catch (e) {
      print('💥 ENHANCED_NOTIF DEBUG: Error in sendLikeNotification: $e');
      print('💥 ENHANCED_NOTIF DEBUG: Stack trace: ${StackTrace.current}');
    }
  }

  static Future<void> sendReplyNotification({
    required String commentAuthorId,
    required String replierName,
    required String postId,
    required String replyText,
    required String commentId,
  }) async {
    try {
      // Get comment author's name for greeting - check both vendors and customers
      String userName = 'User';

      var userDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(commentAuthorId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        userName = userData?['name'] as String? ?? 'User';
      } else {
        userDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(commentAuthorId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          userName =
              userData?['username'] as String? ??
              userData?['name'] as String? ??
              'User';
        }
      }

      final greeting = _getGreeting(userName);

      CollectionReference userTokenCollection = FirebaseFirestore.instance
          .collection('UserToken');

      DocumentSnapshot docSnapshot = await userTokenCollection
          .doc(commentAuthorId)
          .get();

      if (docSnapshot.exists) {
        List<dynamic> tokenList = docSnapshot['token'] ?? [];

        if (tokenList.isEmpty) {
          await _attemptTokenRefresh(commentAuthorId);
          // Try again after refresh
          docSnapshot = await userTokenCollection.doc(commentAuthorId).get();
          if (docSnapshot.exists) {
            tokenList = docSnapshot['token'] ?? [];
          }
        }

        for (String token in tokenList) {
          try {
            await sendNotificationWithVibration(
              deviceToken: token,
              title: greeting,
              body: "$replierName replied to your comment",
              type: "reply_notification",
              additionalData: {
                'postId': postId,
                'commentId': commentId,
                'replierId': replierName,
                'replyText': replyText,
              },
            );
          } catch (e) {
            if (e is InvalidTokenException) {
              await FCMTokenService.removeInvalidToken(commentAuthorId, token);
            }
          }
        }
      } else {
        await _attemptTokenRefresh(commentAuthorId);
      }

      // Store notification in Firestore
      await _storeNotificationInFirestore(
        userId: commentAuthorId,
        title: "Reply Notification",
        body: "$replierName replied to your comment",
        type: "reply",
        additionalData: {
          'postId': postId,
          'commentId': commentId,
          'replierId': replierName,
        },
      );
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> sendCommentNotification({
    required String postOwnerId,
    required String commenterName,
    required String postId,
    required String commentText,
    String? parentCommentId,
    String? parentCommentAuthorId,
  }) async {
    try {
      // Get post owner's name for greeting - check both vendors and customers
      String userName = 'User';

      // Try vendors collection first
      var userDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(postOwnerId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        userName = userData?['name'] as String? ?? 'User';
      } else {
        // Try customers collection
        userDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(postOwnerId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          userName =
              userData?['username'] as String? ??
              userData?['name'] as String? ??
              'User';
        }
      }

      final greeting = _getGreeting(userName);

      CollectionReference userTokenCollection = FirebaseFirestore.instance
          .collection('UserToken');

      DocumentSnapshot docSnapshot = await userTokenCollection
          .doc(postOwnerId)
          .get();

      if (docSnapshot.exists) {
        List<dynamic> tokenList = docSnapshot['token'] ?? [];

        for (String token in tokenList) {
          await sendNotificationWithVibration(
            deviceToken: token,
            title: greeting,
            body: "You have a comment on your post",
            type: "comment_notification",
            additionalData: {
              'postId': postId,
              'commenterId': commenterName,
              'commentText': commentText,
            },
          );
        }
      }

      // Store notification in Firestore for post owner
      await _storeNotificationInFirestore(
        userId: postOwnerId,
        title: "Comment Notification",
        body: "$commenterName commented on your post",
        type: "comment",
        additionalData: {'postId': postId, 'commenterId': commenterName},
      );

      // If this is a reply to a comment, notify the original comment author
      if (parentCommentId != null &&
          parentCommentAuthorId != null &&
          parentCommentAuthorId != postOwnerId) {
        // Get parent comment author's name
        String parentAuthorName = 'User';

        // Try vendors collection first
        var userDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(parentCommentAuthorId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          parentAuthorName = userData?['name'] as String? ?? 'User';
        } else {
          // Try customers collection
          userDoc = await FirebaseFirestore.instance
              .collection('customers')
              .doc(parentCommentAuthorId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            parentAuthorName =
                userData?['username'] as String? ??
                userData?['name'] as String? ??
                'User';
          }
        }

        final replyGreeting = _getGreeting(parentAuthorName);

        // Get parent comment author's tokens
        CollectionReference userTokenCollection = FirebaseFirestore.instance
            .collection('UserToken');

        DocumentSnapshot docSnapshot = await userTokenCollection
            .doc(parentCommentAuthorId)
            .get();

        if (docSnapshot.exists) {
          List<dynamic> tokenList = docSnapshot['token'] ?? [];

          for (String token in tokenList) {
            await sendNotificationWithVibration(
              deviceToken: token,
              title: replyGreeting,
              body: "$commenterName replied to your comment",
              type: "comment_reply_notification",
              additionalData: {
                'postId': postId,
                'commenterId': commenterName,
                'parentCommentId': parentCommentId,
                'commentText': commentText,
              },
            );
          }
        }

        // Store notification in Firestore for comment author
        await _storeNotificationInFirestore(
          userId: parentCommentAuthorId,
          title: "Reply Notification",
          body: "$commenterName replied to your comment",
          type: "comment_reply",
          additionalData: {
            'postId': postId,
            'commenterId': commenterName,
            'parentCommentId': parentCommentId,
          },
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> sendAdminPostNotification({
    required String adminName,
    required String postContent,
  }) async {
    try {
      // Get all user tokens
      final tokenSnapshot = await FirebaseFirestore.instance
          .collection('UserToken')
          .get();

      for (var tokenDoc in tokenSnapshot.docs) {
        final tokenData = tokenDoc.data();
        final userId = tokenDoc.id;
        final tokenList = List<String>.from(tokenData['token'] ?? []);

        // Get user's name for personalized greeting - check both vendors and customers
        String userName = 'User';

        // Try vendors collection first
        var userDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          userName = userData?['name'] as String? ?? 'User';
        } else {
          // Try customers collection
          userDoc = await FirebaseFirestore.instance
              .collection('customers')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            userName =
                userData?['username'] as String? ??
                userData?['name'] as String? ??
                'User';
          }
        }

        final greeting = _getGreeting(userName);

        for (String token in tokenList) {
          await sendNotificationWithVibration(
            deviceToken: token,
            title: greeting,
            body: "$adminName just posted",
            type: "admin_post_notification",
            additionalData: {
              'adminName': adminName,
              'postContent': postContent,
            },
          );
        }

        // Store notification in Firestore for each user
        await _storeNotificationInFirestore(
          userId: userId,
          title: "New Post",
          body: "$adminName just posted",
          type: "admin_post",
          additionalData: {'adminName': adminName},
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> _storeNotificationInFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    print('💾 FIRESTORE DEBUG: Starting _storeNotificationInFirestore');
    print(
      '💾 FIRESTORE DEBUG: userId: $userId, title: $title, body: $body, type: $type',
    );
    print('💾 FIRESTORE DEBUG: additionalData: $additionalData');

    try {
      final notificationData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'sellerId':
            additionalData?['likerId'] ??
            additionalData?['commenterId'] ??
            additionalData?['adminName'] ??
            '',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': type,
        'postId': additionalData?['postId'] ?? '',
        'commentId':
            additionalData?['commentId'] ??
            additionalData?['parentCommentId'] ??
            '',
        ...?additionalData,
      };

      print(
        '💾 FIRESTORE DEBUG: Notification data prepared: $notificationData',
      );
      print(
        '💾 FIRESTORE DEBUG: Storing in path: NotificationWp/$userId/notification/',
      );

      final docRef = await FirebaseFirestore.instance
          .collection('NotificationWp')
          .doc(userId)
          .collection('notification')
          .add(notificationData);

      print(
        '✅ FIRESTORE DEBUG: Notification stored successfully with ID: ${docRef.id}',
      );
    } catch (e) {
      print('💥 FIRESTORE DEBUG: Error storing notification in Firestore: $e');
      print('💥 FIRESTORE DEBUG: Stack trace: ${StackTrace.current}');
    }
  }

  static Future<void> triggerVibration() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500],
          intensities: [0, 128, 0, 255],
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  static void initEnhancedNotifications() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Create notification channel for Android
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'FoodHub',
      'WorkPal Notifications',
      description: 'Notifications for WorkPal app',
      importance: Importance.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      playSound: true,
    );

    // Create CALL notification channel with ringtone
    AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      'call_channel',
      'Incoming Calls',
      description: 'Notifications for incoming calls',
      importance: Importance.max, // Maximum importance for calls
      enableVibration: true,
      vibrationPattern: Int64List.fromList([
        0,
        1000,
        500,
        1000,
        500,
        1000,
      ]), // Longer vibration
      playSound: true,
      // No custom sound specified - will use default phone ringtone
      enableLights: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Create the call channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(callChannel);

    var androidInitialize = const AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    var iosInitialize = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    var initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iosInitialize,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
            await triggerVibration();
            // Handle notification tap for deep linking
            if (notificationResponse.payload != null) {
              await _handleNotificationTap(notificationResponse.payload!);
            }
          },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        // Trigger vibration for incoming notifications
        if (message.data['vibrate'] == 'true') {
          await triggerVibration();
        }

        BigTextStyleInformation bigTextStyleInformation =
            BigTextStyleInformation(
              message.notification!.body.toString(),
              htmlFormatBigText: true,
              contentTitle: message.notification!.title.toString(),
              htmlFormatContentTitle: true,
            );

        AndroidNotificationDetails androidNotificationDetails =
            AndroidNotificationDetails(
              "FoodHub",
              "WorkPal Notifications",
              channelDescription: 'Notifications for WorkPal app',
              importance: Importance.high,
              playSound: true,
              priority: Priority.high,
              styleInformation: bigTextStyleInformation,
              enableVibration: true,
              vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
              icon: '@drawable/ic_notification',
              largeIcon: const DrawableResourceAndroidBitmap(
                '@mipmap/launcher_icon',
              ),
            );

        NotificationDetails notificationDetails = NotificationDetails(
          android: androidNotificationDetails,
          iOS: const DarwinNotificationDetails(),
        );

        // Create payload with post ID for deep linking
        String payload = '';
        if (message.data['postId'] != null) {
          payload = 'postId:${message.data['postId']}';
        }

        flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title,
          message.notification!.body,
          notificationDetails,
          payload: payload,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await triggerVibration();
      // Handle notification tap when app is opened from background
      if (message.data['postId'] != null) {
        await _handleNotificationTap('postId:${message.data['postId']}');
      }
    });

    // Handle notification tap when app is launched from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null && message.data['postId'] != null) {
        _handleNotificationTap('postId:${message.data['postId']}');
      }
    });
  }

  static Future<void> _handleNotificationTap(String payload) async {
    if (payload.startsWith('postId:')) {
      final postId = payload.substring(7); // Remove 'postId:' prefix

      // Store the post ID to navigate to it when the app is ready
      // This will be handled by the main app when it's initialized
      _pendingPostNavigation = postId;
    }
  }

  static String? _pendingPostNavigation;

  static String? getPendingPostNavigation() {
    final postId = _pendingPostNavigation;
    _pendingPostNavigation = null; // Clear after getting
    return postId;
  }

  /// Attempt to refresh FCM token for a user who doesn't have one stored
  static Future<void> _attemptTokenRefresh(String userId) async {
    print(
      '🔄 TOKEN_REFRESH DEBUG: Starting _attemptTokenRefresh for userId: $userId',
    );

    try {
      // Check if this user is currently authenticated
      // final currentUser = FirebaseAuth.instance.currentUser;

      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('user_id');
      print('👤 TOKEN_REFRESH DEBUG: Current authenticated user: $currentUser');

      if (currentUser != null && currentUser == userId) {
        print(
          '✅ TOKEN_REFRESH DEBUG: User matches current authenticated user, refreshing token',
        );
        await FCMTokenService.ensureCurrentUserTokenStored();
        print('✅ TOKEN_REFRESH DEBUG: Token refresh completed');
      } else {
        print(
          '⚠️ TOKEN_REFRESH DEBUG: User does not match current authenticated user, skipping refresh',
        );
      }
    } catch (e) {
      print('💥 TOKEN_REFRESH DEBUG: Error in _attemptTokenRefresh: $e');
    }
  }
}
