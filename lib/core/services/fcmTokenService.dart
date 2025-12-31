import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMTokenService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM and request permissions
  static Future<void> initializeFCM() async {
    try {
      // Request notification permissions
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
      } else {}
    } catch (e) {}
  }

  /// Setup token handling - get current token and listen for changes
  static Future<void> _setupTokenHandling() async {
    try {
      // Get current token
      await _getCurrentTokenAndStore();
      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _storeTokenForCurrentUser(newToken);
      });
    } catch (e) {}
  }

  /// Get current FCM token and store it
  static Future<void> _getCurrentTokenAndStore() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _storeTokenForCurrentUser(token);
      } else {}
    } catch (e) {}
  }

  /// Store FCM token for current user
  static Future<void> _storeTokenForCurrentUser(String token) async {
    try {
      // final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('user_id');
      if (user == null) {
        return;
      }
      await storeTokenForUser(user, token);
    } catch (e) {}
  }

  /// Store FCM token for specific user
  static Future<void> storeTokenForUser(String userId, String token) async {
    print('💾 FCM_TOKEN DEBUG: Storing token for userId: $userId');
    print('💾 FCM_TOKEN DEBUG: Token: ${token.substring(0, 20)}...');

    try {
      final userTokenRef = _firestore.collection('UserToken').doc(userId);
      // Check if document exists
      final doc = await userTokenRef.get();
      if (doc.exists) {
        print('💾 FCM_TOKEN DEBUG: Document exists, updating token array');
        // Document exists, update token array
        final data = doc.data() as Map<String, dynamic>;
        List<dynamic> existingTokens = data['token'] ?? [];
        print(
          '💾 FCM_TOKEN DEBUG: Existing tokens count: ${existingTokens.length}',
        );

        // Remove token if it already exists to avoid duplicates
        existingTokens.removeWhere((existingToken) => existingToken == token);
        // Add new token at the beginning
        existingTokens.insert(0, token);
        // Keep only the latest 3 tokens
        if (existingTokens.length > 3) {
          existingTokens = existingTokens.take(3).toList();
        }

        print(
          '💾 FCM_TOKEN DEBUG: Updated tokens count: ${existingTokens.length}',
        );

        await userTokenRef.update({
          'token': existingTokens,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('✅ FCM_TOKEN DEBUG: Token updated successfully');
      } else {
        print('💾 FCM_TOKEN DEBUG: Document doesn\'t exist, creating new one');
        // Document doesn't exist, create new one
        await userTokenRef.set({
          'token': [token],
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('✅ FCM_TOKEN DEBUG: New token document created successfully');
      }
    } catch (e) {
      print('💥 FCM_TOKEN DEBUG: Error storing token: $e');
    }
  }

  /// Ensure current user has FCM token stored
  static Future<void> ensureCurrentUserTokenStored() async {
    print('🔄 FCM_TOKEN DEBUG: Starting ensureCurrentUserTokenStored');

    try {
      // final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('user_id');
      if (user == null) {
        print('❌ FCM_TOKEN DEBUG: No authenticated user found');
        return;
      }

      print('👤 FCM_TOKEN DEBUG: Checking tokens for user: ${user}');

      // Check if user has token stored
      final userTokenDoc = await _firestore
          .collection('UserToken')
          .doc(user)
          .get();

      if (!userTokenDoc.exists) {
        print('⚠️ FCM_TOKEN DEBUG: No token document exists, creating new one');
        await _getCurrentTokenAndStore();
      } else {
        final tokens = userTokenDoc.data()?['token'] as List?;
        if (tokens?.isEmpty == true) {
          print(
            '⚠️ FCM_TOKEN DEBUG: Token document exists but is empty, refreshing',
          );
          await _getCurrentTokenAndStore();
        } else {
          print(
            '✅ FCM_TOKEN DEBUG: Token document exists with ${tokens?.length} tokens, refreshing anyway',
          );
          // Still get current token to ensure it's up to date
          await _getCurrentTokenAndStore();
        }
      }
    } catch (e) {
      print('💥 FCM_TOKEN DEBUG: Error in ensureCurrentUserTokenStored: $e');
    }
  }

  /// Get stored tokens for a user
  static Future<List<String>> getTokensForUser(String userId) async {
    print('🔑 FCM_TOKEN DEBUG: Getting tokens for userId: $userId');

    try {
      final doc = await _firestore.collection('UserToken').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final tokens = List<String>.from(data['token'] ?? []);
        print(
          '✅ FCM_TOKEN DEBUG: Found ${tokens.length} tokens for user $userId',
        );
        for (int i = 0; i < tokens.length; i++) {
          print(
            '🔑 FCM_TOKEN DEBUG: Token $i: ${tokens[i].substring(0, 20)}...',
          );
        }
        return tokens;
      } else {
        print('❌ FCM_TOKEN DEBUG: No token document found for user $userId');
      }
      return [];
    } catch (e) {
      print('💥 FCM_TOKEN DEBUG: Error getting tokens for user $userId: $e');
      return [];
    }
  }

  /// Remove invalid tokens for a user
  static Future<void> removeInvalidToken(
    String userId,
    String invalidToken,
  ) async {
    print('🗑️ FCM_TOKEN DEBUG: Removing invalid token for userId: $userId');
    print(
      '🗑️ FCM_TOKEN DEBUG: Invalid token: ${invalidToken.substring(0, 20)}...',
    );

    try {
      final userTokenRef = _firestore.collection('UserToken').doc(userId);
      final doc = await userTokenRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        List<dynamic> tokens = data['token'] ?? [];
        final originalCount = tokens.length;
        tokens.removeWhere((token) => token == invalidToken);
        final newCount = tokens.length;

        print(
          '🗑️ FCM_TOKEN DEBUG: Removed ${originalCount - newCount} invalid tokens',
        );
        print('🗑️ FCM_TOKEN DEBUG: Remaining tokens: $newCount');

        await userTokenRef.update({
          'token': tokens,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('✅ FCM_TOKEN DEBUG: Invalid token removed successfully');
      } else {
        print('❌ FCM_TOKEN DEBUG: No token document found for user $userId');
      }
    } catch (e) {
      print('💥 FCM_TOKEN DEBUG: Error removing invalid token: $e');
    }
  }
}
