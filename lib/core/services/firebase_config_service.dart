import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class FirebaseConfigService {
  static Map<String, dynamic>? _cachedConfig;

  /// Fetches Firebase service account configuration from Firestore
  static Future<Map<String, dynamic>> getServiceAccountConfig() async {
    print('🔑 CONFIG DEBUG: Starting getServiceAccountConfig');

    // Return cached config if available
    if (_cachedConfig != null) {
      print('✅ CONFIG DEBUG: Using cached config');
      return _cachedConfig!;
    }

    try {
      print(
        '📄 CONFIG DEBUG: Fetching config from Firestore Admin/Admin document',
      );
      final doc = await FirebaseFirestore.instance
          .collection('Admin')
          .doc('Admin')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print(
          '✅ CONFIG DEBUG: Admin document found, extracting service account data',
        );

        final rawPrivateKey = data["private_key"] ?? "";
        final formattedPrivateKey = _formatPrivateKey(rawPrivateKey);

        // Load service account config from file
        _cachedConfig = await _loadServiceAccountFromFile();

        print('✅ CONFIG DEBUG: Service account config created and cached');
        final privateKey = _cachedConfig!["private_key"] as String;
        print('🔑 CONFIG DEBUG: Has private_key: ${privateKey.isNotEmpty}');
        print('🔑 CONFIG DEBUG: Private key length: ${privateKey.length}');
        print(
          '🔑 CONFIG DEBUG: Private key starts with: ${privateKey.length > 30 ? privateKey.substring(0, 30) : privateKey}...',
        );
        print(
          '🔑 CONFIG DEBUG: Private key ends with: ${privateKey.length > 30 ? '...${privateKey.substring(privateKey.length - 30)}' : privateKey}',
        );
        print(
          '🔑 CONFIG DEBUG: Has BEGIN marker: ${privateKey.contains('-----BEGIN')}',
        );
        print(
          '🔑 CONFIG DEBUG: Has END marker: ${privateKey.contains('-----END')}',
        );
        print(
          '🔑 CONFIG DEBUG: Has private_key_id: ${(_cachedConfig!["private_key_id"] as String).isNotEmpty}',
        );
        print(
          '🔑 CONFIG DEBUG: Has client_id: ${(_cachedConfig!["client_id"] as String).isNotEmpty}',
        );

        return _cachedConfig!;
      } else {
        print('❌ CONFIG DEBUG: Admin document does not exist or has no data');
      }
    } catch (e) {
      // If fetching from Firestore fails, return empty config
      print('💥 CONFIG DEBUG: Error fetching Firebase config: $e');
      print('💥 CONFIG DEBUG: Stack trace: ${StackTrace.current}');
    }

    print(
      '⚠️ CONFIG DEBUG: Falling back to file-based config',
    );
    // Return config from file if Firestore fetch fails
    return await _loadServiceAccountFromFile();
  }

  /// Loads service account credentials from local JSON file
  static Future<Map<String, dynamic>> _loadServiceAccountFromFile() async {
    try {
      print('📂 CONFIG DEBUG: Loading service account from file');
      
      // Try to load from assets first (for production)
      try {
        final jsonString = await rootBundle.loadString(
          'lib/core/config/firebase_service_account.json',
        );
        final config = json.decode(jsonString) as Map<String, dynamic>;
        print('✅ CONFIG DEBUG: Loaded service account from assets');
        return config;
      } catch (e) {
        print('⚠️ CONFIG DEBUG: Could not load from assets: $e');
      }

      // Try to load from file system (for development)
      final file = File('lib/core/config/firebase_service_account.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final config = json.decode(jsonString) as Map<String, dynamic>;
        print('✅ CONFIG DEBUG: Loaded service account from file system');
        return config;
      }

      print('❌ CONFIG DEBUG: Service account file not found');
      throw Exception('Service account configuration file not found');
    } catch (e) {
      print('💥 CONFIG DEBUG: Error loading service account from file: $e');
      rethrow;
    }
  }

  /// Formats private key to ensure proper PEM format
  static String _formatPrivateKey(String privateKey) {
    if (privateKey.isEmpty) {
      print('❌ CONFIG DEBUG: Private key is empty');
      return privateKey;
    }

    // Remove any existing formatting and whitespace
    String cleanKey = privateKey
        .replaceAll('\\n', '\n')
        .replaceAll('\r', '')
        .trim();

    print('🔧 CONFIG DEBUG: Original key length: ${privateKey.length}');
    print('🔧 CONFIG DEBUG: Cleaned key length: ${cleanKey.length}');

    // Check if it already has proper PEM format
    if (cleanKey.startsWith('-----BEGIN PRIVATE KEY-----') &&
        cleanKey.endsWith('-----END PRIVATE KEY-----')) {
      print('✅ CONFIG DEBUG: Private key already has proper PEM format');
      return cleanKey;
    }

    // Remove existing headers/footers if present
    cleanKey = cleanKey
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceAll('-----END RSA PRIVATE KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll(' ', '')
        .trim();

    if (cleanKey.isEmpty) {
      print('❌ CONFIG DEBUG: Private key is empty after cleaning');
      return '';
    }

    // Format as proper PEM
    final formattedKey =
        '-----BEGIN PRIVATE KEY-----\n${_insertLineBreaks(cleanKey, 64)}\n-----END PRIVATE KEY-----';

    print('✅ CONFIG DEBUG: Private key formatted to proper PEM format');
    print('🔧 CONFIG DEBUG: Formatted key length: ${formattedKey.length}');

    return formattedKey;
  }

  /// Inserts line breaks every n characters
  static String _insertLineBreaks(String text, int lineLength) {
    if (text.length <= lineLength) return text;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i += lineLength) {
      final end = (i + lineLength < text.length) ? i + lineLength : text.length;
      buffer.write(text.substring(i, end));
      if (end < text.length) buffer.write('\n');
    }
    return buffer.toString();
  }

  /// Clears the cached config (useful for testing or when config changes)
  static void clearCache() {
    _cachedConfig = null;
  }
}
