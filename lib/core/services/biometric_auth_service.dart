import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  DateTime? _lastBackgroundTime;

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      AppLogger.log('Error checking biometrics: $e', tag: 'BIOMETRIC');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      AppLogger.log('Error getting biometrics: $e', tag: 'BIOMETRIC');
      return [];
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  Future<String> getLockTiming() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lock_timing') ?? 'immediately';
  }

  Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      final canCheck = await canCheckBiometrics();
      AppLogger.log('Can check biometrics: $canCheck', tag: 'BIOMETRIC');

      if (!canCheck) {
        AppLogger.log('Biometrics not available on device', tag: 'BIOMETRIC');
        return false;
      }

      final isDeviceSupported = await _auth.isDeviceSupported();
      AppLogger.log('Device supported: $isDeviceSupported', tag: 'BIOMETRIC');

      if (!isDeviceSupported) {
        AppLogger.log('Device does not support biometrics', tag: 'BIOMETRIC');
        return false;
      }

      final availableBiometrics = await getAvailableBiometrics();
      AppLogger.log(
        'Available biometrics: $availableBiometrics',
        tag: 'BIOMETRIC',
      );

      if (availableBiometrics.isEmpty) {
        AppLogger.log('No biometrics enrolled on device', tag: 'BIOMETRIC');
        return false;
      }

      AppLogger.log('Attempting authentication...', tag: 'BIOMETRIC');

      final isAuthenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      AppLogger.log(
        'Authentication result: $isAuthenticated',
        tag: 'BIOMETRIC',
      );
      return isAuthenticated;
    } on PlatformException catch (e) {
      AppLogger.log(
        'Authentication PlatformException - Code: ${e.code}, Message: ${e.message}',
        tag: 'BIOMETRIC',
      );

      switch (e.code) {
        case 'NotAvailable':
          AppLogger.log('Biometric not available', tag: 'BIOMETRIC');
          break;
        case 'NotEnrolled':
          AppLogger.log('No biometrics enrolled', tag: 'BIOMETRIC');
          break;
        case 'LockedOut':
          AppLogger.log('Too many attempts, locked out', tag: 'BIOMETRIC');
          break;
        case 'PermanentlyLockedOut':
          AppLogger.log('Permanently locked out', tag: 'BIOMETRIC');
          break;
        default:
          AppLogger.log('Unknown error: ${e.code}', tag: 'BIOMETRIC');
      }

      return false;
    } catch (e) {
      AppLogger.log('Authentication general error: $e', tag: 'BIOMETRIC');
      return false;
    }
  }

  Future<bool> shouldLockApp() async {
    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) return false;

    if (_lastBackgroundTime == null) return false;

    final timing = await getLockTiming();
    final now = DateTime.now();
    final difference = now.difference(_lastBackgroundTime!);

    switch (timing) {
      case 'immediately':
        return true;
      case '1_minute':
        return difference.inMinutes >= 1;
      case '30_minutes':
        return difference.inMinutes >= 30;
      default:
        return true;
    }
  }

  void recordBackgroundTime() {
    _lastBackgroundTime = DateTime.now();
    AppLogger.log(
      'App went to background at: $_lastBackgroundTime',
      tag: 'BIOMETRIC',
    );
  }

  void clearBackgroundTime() {
    _lastBackgroundTime = null;
    AppLogger.log('Background time cleared', tag: 'BIOMETRIC');
  }

  Future<String> getBiometricTypeName() async {
    final types = await getAvailableBiometrics();
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }

  Future<bool> hasStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<bool> authenticateForLogin() async {
    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) return false;

    final hasCredentials = await hasStoredCredentials();
    if (!hasCredentials) return false;

    return await authenticate(
      reason: 'Authenticate to login to Muvam',
      biometricOnly: false,
    );
  }
}
