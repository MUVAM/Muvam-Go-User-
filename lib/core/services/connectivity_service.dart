import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:muvam/core/utils/app_logger.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Callback for connectivity changes
  Function(bool isConnected)? onConnectivityChanged;

  // Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity status
    await checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _handleConnectivityChange(results);
    });

    AppLogger.log('Connectivity service initialized', tag: 'CONNECTIVITY');
  }

  // Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final wasConnected = _isConnected;
      _isConnected = _hasConnection(results);

      AppLogger.log(
        'Connectivity status: ${_isConnected ? "Connected" : "Disconnected"}',
        tag: 'CONNECTIVITY',
      );

      // Notify if status changed
      if (wasConnected != _isConnected) {
        onConnectivityChanged?.call(_isConnected);
      }

      return _isConnected;
    } catch (e) {
      AppLogger.error(
        'Error checking connectivity',
        error: e,
        tag: 'CONNECTIVITY',
      );
      return false;
    }
  }

  // Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = _hasConnection(results);

    AppLogger.log(
      'Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"}',
      tag: 'CONNECTIVITY',
    );

    AppLogger.log(
      'Was: $wasConnected, Now: $_isConnected, Callback set: ${onConnectivityChanged != null}',
      tag: 'CONNECTIVITY',
    );

    // Only notify if status actually changed
    if (wasConnected != _isConnected) {
      AppLogger.log(
        'Status ACTUALLY changed! Calling callback...',
        tag: 'CONNECTIVITY',
      );

      if (onConnectivityChanged != null) {
        onConnectivityChanged!.call(_isConnected);
        AppLogger.log('Callback executed', tag: 'CONNECTIVITY');
      } else {
        AppLogger.log('No callback registered!', tag: 'CONNECTIVITY');
      }
    } else {
      AppLogger.log(
        'Status unchanged, not calling callback',
        tag: 'CONNECTIVITY',
      );
    }
  }

  // Check if any of the results indicate a connection
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    AppLogger.log('Connectivity service disposed', tag: 'CONNECTIVITY');
  }
}
