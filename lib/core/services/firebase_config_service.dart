import 'package:muvam/core/config/firebase_service_account.dart';

class FirebaseConfigService {
  static Map<String, dynamic>? _cachedConfig;

  /// Gets Firebase service account configuration from Dart constant
  static Future<Map<String, dynamic>> getServiceAccountConfig() async {
    print('🔑 CONFIG DEBUG: Starting getServiceAccountConfig');

    // Return cached config if available
    if (_cachedConfig != null) {
      print('✅ CONFIG DEBUG: Using cached config');
      return _cachedConfig!;
    }

    try {
      print('📂 CONFIG DEBUG: Loading service account from Dart constant');

      // Load from Dart constant file
      _cachedConfig = Map<String, dynamic>.from(
        FirebaseServiceAccount.credentials,
      );

      print('✅ CONFIG DEBUG: Service account config loaded and cached');

      // Validate the config
      final privateKey = _cachedConfig!["private_key"] as String;
      final projectId = _cachedConfig!["project_id"] as String;
      final clientEmail = _cachedConfig!["client_email"] as String;

      print('🔑 CONFIG DEBUG: Project ID: $projectId');
      print('🔑 CONFIG DEBUG: Client Email: $clientEmail');
      print('🔑 CONFIG DEBUG: Has private_key: ${privateKey.isNotEmpty}');
      print('🔑 CONFIG DEBUG: Private key length: ${privateKey.length}');
      print(
        '🔑 CONFIG DEBUG: Has BEGIN marker: ${privateKey.contains('-----BEGIN')}',
      );
      print(
        '🔑 CONFIG DEBUG: Has END marker: ${privateKey.contains('-----END')}',
      );

      // Check if credentials are placeholder values
      if (privateKey.contains('YOUR_PRIVATE_KEY_HERE') ||
          clientEmail.contains('YOUR_CLIENT_EMAIL_HERE')) {
        print('❌ CONFIG DEBUG: Credentials contain placeholder values!');
        print(
          '⚠️  Please update lib/core/config/firebase_service_account.dart with actual credentials',
        );
        throw Exception(
          'Firebase service account credentials not configured. Please update firebase_service_account.dart',
        );
      }

      return _cachedConfig!;
    } catch (e) {
      print('💥 CONFIG DEBUG: Error loading Firebase config: $e');
      print('💥 CONFIG DEBUG: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Clears the cached config (useful for testing or when config changes)
  static void clearCache() {
    _cachedConfig = null;
    print('🔄 CONFIG DEBUG: Cache cleared');
  }
}
