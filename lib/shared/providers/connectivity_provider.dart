import 'package:flutter/material.dart';
import 'package:muvam/core/services/connectivity_service.dart';
import 'package:muvam/core/utils/app_logger.dart';

class ConnectivityProvider with ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  bool _hasShownInitialStatus = false;

  ConnectivityProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Set up connectivity change listener
    _connectivityService.onConnectivityChanged = (isConnected) {
      AppLogger.log(
        '📥 CALLBACK RECEIVED in provider! isConnected: $isConnected',
        tag: 'CONNECTIVITY_PROVIDER',
      );

      _isConnected = isConnected;

      AppLogger.log(
        '🔔 Calling notifyListeners() to update UI',
        tag: 'CONNECTIVITY_PROVIDER',
      );

      notifyListeners();

      AppLogger.log(
        '✅ notifyListeners() called successfully',
        tag: 'CONNECTIVITY_PROVIDER',
      );
    };

    AppLogger.log(
      '🔧 Callback registered, initializing service...',
      tag: 'CONNECTIVITY_PROVIDER',
    );

    // Initialize the service
    await _connectivityService.initialize();

    // Get initial status
    _isConnected = _connectivityService.isConnected;
    _hasShownInitialStatus = true;

    AppLogger.log(
      '✅ Provider initialized. Initial status: $_isConnected',
      tag: 'CONNECTIVITY_PROVIDER',
    );

    notifyListeners();
  }

  /// Manually check connectivity
  Future<bool> checkConnectivity() async {
    final isConnected = await _connectivityService.checkConnectivity();
    _isConnected = isConnected;
    notifyListeners();
    return isConnected;
  }

  /// Check if initial status has been shown
  bool get hasShownInitialStatus => _hasShownInitialStatus;

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }
}
