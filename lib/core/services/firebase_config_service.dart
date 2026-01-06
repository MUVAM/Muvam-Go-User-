import 'package:muvam/core/config/firebase_service_account.dart';
import 'package:muvam/core/utils/app_logger.dart';

class FirebaseConfigService {
  static Map<String, dynamic>? _cachedConfig;

  static Future<Map<String, dynamic>> getServiceAccountConfig() async {
    AppLogger.log('Starting getServiceAccountConfig');

    if (_cachedConfig != null) {
      AppLogger.log('Using cached config');
      return _cachedConfig!;
    }

    try {
      AppLogger.log('Loading service account from Dart constant');

      _cachedConfig = Map<String, dynamic>.from(
        FirebaseServiceAccount.credentials,
      );

      AppLogger.log('Service account config loaded and cached');

      final privateKey = _cachedConfig!["private_key"] as String;
      final projectId = _cachedConfig!["project_id"] as String;
      final clientEmail = _cachedConfig!["client_email"] as String;

      AppLogger.log('Project ID: $projectId');
      AppLogger.log('Client Email: $clientEmail');
      AppLogger.log('Has private_key: ${privateKey.isNotEmpty}');
      AppLogger.log('Private key length: ${privateKey.length}');
      AppLogger.log('Has BEGIN marker: ${privateKey.contains('-----BEGIN')}');
      AppLogger.log('Has END marker: ${privateKey.contains('-----END')}');

      if (privateKey.contains('YOUR_PRIVATE_KEY_HERE') ||
          clientEmail.contains('YOUR_CLIENT_EMAIL_HERE')) {
        AppLogger.log('Credentials contain placeholder values!');
        AppLogger.log(
          'Please update firebase_service_account.dart with actual credentials',
        );
        throw Exception(
          'Firebase service account credentials not configured. Please update firebase_service_account.dart',
        );
      }

      return _cachedConfig!;
    } catch (e) {
      AppLogger.log('Error loading Firebase config: $e');
      AppLogger.log('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  static void clearCache() {
    _cachedConfig = null;
    AppLogger.log('Cache cleared');
  }
}
