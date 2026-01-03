import 'dart:convert';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageCacheService {
  static const String _cacheKey = 'cached_messages';
  static const int _maxMessagesPerRide = 500;

  // Save messages for a specific ride
  static Future<void> saveMessages(
    int rideId,
    List<ChatMessageModel> messages,
  ) async {
    try {
      AppLogger.log(
        'Saving ${messages.length} messages for ride $rideId',
        tag: 'CACHE',
      );

      final prefs = await SharedPreferences.getInstance();

      // Get existing cache
      final cachedData = prefs.getString(_cacheKey);
      Map<String, dynamic> cache = cachedData != null
          ? jsonDecode(cachedData)
          : {};

      // Convert messages to JSON
      final messagesJson = messages
          .take(_maxMessagesPerRide)
          .map((m) => m.toJson())
          .toList();

      // Save messages for this ride
      cache[rideId.toString()] = {
        'messages': messagesJson,
        'last_updated': DateTime.now().toIso8601String(),
      };

      // Save back to storage
      await prefs.setString(_cacheKey, jsonEncode(cache));

      AppLogger.log('Messages cached successfully', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('Failed to cache messages', error: e, tag: 'CACHE');
    }
  }

  // Load messages for a specific ride
  static Future<List<ChatMessageModel>> loadMessages(int rideId) async {
    try {
      AppLogger.log('Loading cached messages for ride $rideId', tag: 'CACHE');

      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData == null) {
        AppLogger.log('No cached messages found', tag: 'CACHE');
        return [];
      }

      final cache = jsonDecode(cachedData) as Map<String, dynamic>;
      final rideData = cache[rideId.toString()];

      if (rideData == null) {
        AppLogger.log('No cached messages for ride $rideId', tag: 'CACHE');
        return [];
      }

      final messagesList = rideData['messages'] as List;
      final messages = messagesList
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();

      final lastUpdated = rideData['last_updated'];
      AppLogger.log(
        'Loaded ${messages.length} messages (last updated: $lastUpdated)',
        tag: 'CACHE',
      );

      return messages;
    } catch (e) {
      AppLogger.error('Failed to load cached messages', error: e, tag: 'CACHE');
      return [];
    }
  }

  // Add a single message to cache
  static Future<void> addMessage(int rideId, ChatMessageModel message) async {
    try {
      // Load existing messages
      final existingMessages = await loadMessages(rideId);

      // Check for duplicates (by timestamp and message content)
      final isDuplicate = existingMessages.any(
        (m) => m.timestamp == message.timestamp && m.message == message.message,
      );

      if (isDuplicate) {
        AppLogger.log('Duplicate message detected, skipping', tag: 'CACHE');
        return;
      }

      // Add new message
      existingMessages.add(message);

      // Save all messages
      await saveMessages(rideId, existingMessages);

      AppLogger.log('Message added to cache', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('Failed to add message to cache', error: e, tag: 'CACHE');
    }
  }

  // Clear messages for a specific ride
  static Future<void> clearRideMessages(int rideId) async {
    try {
      AppLogger.log('Clearing messages for ride $rideId', tag: 'CACHE');

      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData == null) return;

      final cache = jsonDecode(cachedData) as Map<String, dynamic>;
      cache.remove(rideId.toString());

      await prefs.setString(_cacheKey, jsonEncode(cache));

      AppLogger.log('Messages cleared', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('Failed to clear messages', error: e, tag: 'CACHE');
    }
  }

  // Clear all cached messages
  static Future<void> clearAllMessages() async {
    try {
      AppLogger.log('Clearing all cached messages', tag: 'CACHE');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);

      AppLogger.log('All messages cleared', tag: 'CACHE');
    } catch (e) {
      AppLogger.error('Failed to clear all messages', error: e, tag: 'CACHE');
    }
  }

  // Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData == null) {
        return {'total_rides': 0, 'total_messages': 0, 'cache_size_kb': 0};
      }

      final cache = jsonDecode(cachedData) as Map<String, dynamic>;
      int totalMessages = 0;

      cache.forEach((key, value) {
        final messages = value['messages'] as List;
        totalMessages += messages.length;
      });

      final cacheSizeBytes = utf8.encode(cachedData).length;
      final cacheSizeKb = (cacheSizeBytes / 1024).toStringAsFixed(2);

      return {
        'total_rides': cache.length,
        'total_messages': totalMessages,
        'cache_size_kb': cacheSizeKb,
      };
    } catch (e) {
      AppLogger.error('Failed to get cache stats', error: e, tag: 'CACHE');
      return {'total_rides': 0, 'total_messages': 0, 'cache_size_kb': 0};
    }
  }
}

extension ChatMessageModelJson on ChatMessageModel {
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'timestamp': timestamp,
      'ride_id': rideId,
      'user_id': userId,
    };
  }

  static ChatMessageModel fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      rideId: json['ride_id'] ?? 0,
      userId: json['user_id'],
    );
  }
}

class ChatMessageModel {
  final String message;
  final String timestamp;
  final int rideId;
  final String? userId;

  ChatMessageModel({
    required this.message,
    required this.timestamp,
    required this.rideId,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'timestamp': timestamp,
      'ride_id': rideId,
      'user_id': userId,
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      rideId: json['ride_id'] ?? 0,
      userId: json['user_id'],
    );
  }
}
