import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMTokenService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initializeFCM() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await _setupTokenHandling();
      }
    } catch (e) {}
  }

  static Future<void> _setupTokenHandling() async {
    try {
      await _getCurrentTokenAndStore();
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _storeTokenForCurrentUser(newToken);
      });
    } catch (e) {}
  }

  static Future<void> _getCurrentTokenAndStore() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _storeTokenForCurrentUser(token);
      }
    } catch (e) {}
  }

  static Future<void> _storeTokenForCurrentUser(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('user_id');
      if (user == null) {
        return;
      }
      await storeTokenForUser(user, token);
    } catch (e) {}
  }

  static Future<void> storeTokenForUser(String userId, String token) async {
    AppLogger.log('Storing token for userId: $userId');
    AppLogger.log('Token: ${token.substring(0, 20)}...');

    try {
      final userTokenRef = _firestore.collection('UserToken').doc(userId);
      final doc = await userTokenRef.get();
      if (doc.exists) {
        AppLogger.log('Document exists, updating token array');
        final data = doc.data() as Map<String, dynamic>;
        List<dynamic> existingTokens = data['token'] ?? [];
        AppLogger.log('Existing tokens count: ${existingTokens.length}');

        existingTokens.removeWhere((existingToken) => existingToken == token);
        existingTokens.insert(0, token);
        if (existingTokens.length > 3) {
          existingTokens = existingTokens.take(3).toList();
        }

        AppLogger.log('Updated tokens count: ${existingTokens.length}');

        await userTokenRef.update({
          'token': existingTokens,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        AppLogger.log('Token updated successfully');
      } else {
        AppLogger.log('Document doesn\'t exist, creating new one');
        await userTokenRef.set({
          'token': [token],
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        AppLogger.log('New token document created successfully');
      }
    } catch (e) {
      AppLogger.log('Error storing token: $e');
    }
  }

  static Future<void> ensureCurrentUserTokenStored() async {
    AppLogger.log('Starting ensureCurrentUserTokenStored');

    try {
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('user_id');
      if (user == null) {
        AppLogger.log('No authenticated user found');
        return;
      }

      AppLogger.log('Checking tokens for user: $user');

      final userTokenDoc = await _firestore
          .collection('UserToken')
          .doc(user)
          .get();

      if (!userTokenDoc.exists) {
        AppLogger.log('No token document exists, creating new one');
        await _getCurrentTokenAndStore();
      } else {
        final tokens = userTokenDoc.data()?['token'] as List?;
        if (tokens?.isEmpty == true) {
          AppLogger.log('Token document exists but is empty, refreshing');
          await _getCurrentTokenAndStore();
        } else {
          AppLogger.log(
            'Token document exists with ${tokens?.length} tokens, refreshing anyway',
          );
          await _getCurrentTokenAndStore();
        }
      }
    } catch (e) {
      AppLogger.log('Error in ensureCurrentUserTokenStored: $e');
    }
  }

  static Future<List<String>> getTokensForUser(String userId) async {
    AppLogger.log('Getting tokens for userId: $userId');

    try {
      final doc = await _firestore.collection('UserToken').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final tokens = List<String>.from(data['token'] ?? []);
        AppLogger.log('Found ${tokens.length} tokens for user $userId');
        for (int i = 0; i < tokens.length; i++) {
          AppLogger.log('Token $i: ${tokens[i].substring(0, 20)}...');
        }
        return tokens;
      } else {
        AppLogger.log('No token document found for user $userId');
      }
      return [];
    } catch (e) {
      AppLogger.log('Error getting tokens for user $userId: $e');
      return [];
    }
  }

  static Future<void> removeInvalidToken(
    String userId,
    String invalidToken,
  ) async {
    AppLogger.log('Removing invalid token for userId: $userId');
    AppLogger.log('Invalid token: ${invalidToken.substring(0, 20)}...');

    try {
      final userTokenRef = _firestore.collection('UserToken').doc(userId);
      final doc = await userTokenRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        List<dynamic> tokens = data['token'] ?? [];
        final originalCount = tokens.length;
        tokens.removeWhere((token) => token == invalidToken);
        final newCount = tokens.length;

        AppLogger.log('Removed ${originalCount - newCount} invalid tokens');
        AppLogger.log('Remaining tokens: $newCount');

        await userTokenRef.update({
          'token': tokens,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        AppLogger.log('Invalid token removed successfully');
      } else {
        AppLogger.log('No token document found for user $userId');
      }
    } catch (e) {
      AppLogger.log('Error removing invalid token: $e');
    }
  }
}
